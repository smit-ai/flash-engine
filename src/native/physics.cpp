#include "physics.h"
#include <cmath>
#include <algorithm>
#include <vector>

#define PI 3.14159265359f

struct Vec2 {
    float x, y;
    Vec2 operator+(const Vec2& v) const { return {x + v.x, y + v.y}; }
    Vec2 operator-(const Vec2& v) const { return {x - v.x, y - v.y}; }
    Vec2 operator*(float s) const { return {x * s, y * s}; }
    float dot(const Vec2& v) const { return x * v.x + y * v.y; }
    float cross(const Vec2& v) const { return x * v.y - y * v.x; }
    float lengthSq() const { return x * x + y * y; }
    float length() const { return std::sqrt(lengthSq()); }
};

inline Vec2 cross(Vec2 v, float s) { return {s * v.y, -s * v.x}; }
inline Vec2 cross(float s, Vec2 v) { return {-s * v.y, s * v.x}; }
inline Vec2 rotate(Vec2 v, float angle) {
    float c = std::cos(angle);
    float s = std::sin(angle);
    return { v.x * c - v.y * s, v.x * s + v.y * c };
}

extern "C" {

PhysicsWorld* create_physics_world(int maxBodies) {
    PhysicsWorld* world = new PhysicsWorld();
    world->bodies = new NativeBody[maxBodies];
    world->maxBodies = maxBodies;
    world->activeCount = 0;
    
    world->maxManifolds = maxBodies * 2; // Conservative estimate
    world->manifolds = new ContactManifold[world->maxManifolds];
    world->activeManifolds = 0;
    
    world->gravityX = 0;
    world->gravityY = -9.81f * 100.0f; 
    
    world->velocityIterations = 12; // Increased for better accuracy
    world->positionIterations = 4;
    
    return world;
}

void destroy_physics_world(PhysicsWorld* world) {
    if (!world) return;
    delete[] world->bodies;
    delete[] world->manifolds;
    delete world;
}

struct CollisionManifold {
    Vec2 normal;
    float penetration;
    Vec2 contacts[2];
    int contactCount;
    bool collided;
};

// --- Collision Detection (SAT & Math) ---

CollisionManifold detectCircleCircle(NativeBody& a, NativeBody& b) {
    Vec2 posA = {a.x, a.y};
    Vec2 posB = {b.x, b.y};
    Vec2 d = posB - posA;
    float distSq = d.lengthSq();
    float radiusSum = a.radius + b.radius;

    if (distSq >= radiusSum * radiusSum) return {{0,0}, 0, {{0,0}}, 0, false};

    float dist = std::sqrt(distSq);
    CollisionManifold m;
    m.collided = true;
    m.contactCount = 1;

    if (dist == 0) {
        m.penetration = a.radius;
        m.normal = {0, 1};
        m.contacts[0] = posA;
    } else {
        m.penetration = radiusSum - dist;
        m.normal = d * (1.0f / dist);
        m.contacts[0] = posB - (m.normal * b.radius);
    }
    return m;
}

// Simple SAT helper for OBB vs OBB (Not fully exhaustive, but sufficient for high-quality box physics)
CollisionManifold detectBoxBox(NativeBody& a, NativeBody& b) {
    auto project = [](NativeBody& body, Vec2 axis, float& min, float& max) {
        float hw = body.width * 0.5f;
        float hh = body.height * 0.5f;
        Vec2 pos = {body.x, body.y};
        Vec2 v[4] = {
            pos + rotate({-hw, -hh}, body.rotation),
            pos + rotate({ hw, -hh}, body.rotation),
            pos + rotate({ hw,  hh}, body.rotation),
            pos + rotate({-hw,  hh}, body.rotation)
        };
        min = max = axis.dot(v[0]);
        for (int i = 1; i < 4; ++i) {
            float p = axis.dot(v[i]);
            if (p < min) min = p;
            if (p > max) max = p;
        }
    };

    float minOverlap = 1e10f;
    Vec2 bestAxis;
    NativeBody* ref = &a;
    NativeBody* inc = &b;

    Vec2 axes[4] = {
        rotate({1, 0}, a.rotation),
        rotate({0, 1}, a.rotation),
        rotate({1, 0}, b.rotation),
        rotate({0, 1}, b.rotation)
    };

    for (int i = 0; i < 4; ++i) {
        float minA, maxA, minB, maxB;
        project(a, axes[i], minA, maxA);
        project(b, axes[i], minB, maxB);

        float overlap = std::min(maxA, maxB) - std::max(minA, minB);
        if (overlap <= 0) return {{0,0}, 0, {{0,0}}, 0, false};

        if (overlap < minOverlap) {
            minOverlap = overlap;
            bestAxis = axes[i];
            if (i < 2) { ref = &a; inc = &b; }
            else { ref = &b; inc = &a; }
        }
    }

    Vec2 d = {b.x - a.x, b.y - a.y};
    if (bestAxis.dot(d) < 0) bestAxis = bestAxis * -1.0f;

    CollisionManifold m;
    m.collided = true;
    m.normal = bestAxis;
    m.penetration = minOverlap;
    m.contactCount = 1;

    // Contact Point: Deepest vertex of incident body into reference body
    float hw = inc->width * 0.5f;
    float hh = inc->height * 0.5f;
    Vec2 incPos = {inc->x, inc->y};
    Vec2 incVerts[4] = {
        incPos + rotate({-hw, -hh}, inc->rotation),
        incPos + rotate({ hw, -hh}, inc->rotation),
        incPos + rotate({ hw,  hh}, inc->rotation),
        incPos + rotate({-hw,  hh}, inc->rotation)
    };

    float minDot = 1e10f;
    Vec2 deepest;
    for(int i=0; i<4; ++i) {
        float dot = bestAxis.dot(incVerts[i]);
        if (dot < minDot) {
            minDot = dot;
            deepest = incVerts[i];
        }
    }
    m.contacts[0] = deepest + (bestAxis * (minOverlap * 0.5f));
    return m;
}

CollisionManifold detectCircleBox(NativeBody& circle, NativeBody& box) {
    Vec2 pc = {circle.x, circle.y};
    Vec2 pb = {box.x, box.y};
    
    Vec2 d = pc - pb;
    Vec2 localD = rotate(d, -box.rotation);

    float hw = box.width * 0.5f;
    float hh = box.height * 0.5f;

    Vec2 closest = { std::max(-hw, std::min(hw, localD.x)), std::max(-hh, std::min(hh, localD.y)) };
    Vec2 localNormal = localD - closest;
    float distSq = localNormal.lengthSq();
    float r = circle.radius;

    if (distSq > r * r && (std::abs(localD.x) > hw || std::abs(localD.y) > hh)) return {{0,0}, 0, {{0,0}}, 0, false};

    float dist = std::sqrt(distSq);
    CollisionManifold m;
    m.collided = true;
    m.contactCount = 1;
    
    if (dist > 0.0001f) {
        m.normal = rotate(localNormal, box.rotation) * (1.0f / dist);
    } else {
        float dx = hw - std::abs(localD.x);
        float dy = hh - std::abs(localD.y);
        if (dx < dy) {
            m.normal = rotate({(localD.x > 0) ? 1.0f : -1.0f, 0}, box.rotation);
            dist = -dx;
        } else {
            m.normal = rotate({0, (localD.y > 0) ? 1.0f : -1.0f}, box.rotation);
            dist = -dy;
        }
    }
    
    m.penetration = r - dist;
    m.contacts[0] = pb + rotate(closest, box.rotation);
    return m;
}

// --- Solver ---

void step_physics(PhysicsWorld* world, float dt) {
    if (!world || world->activeCount == 0 || dt <= 0) return;

    // 1. Force Application & Integration
    // 1. Force Application (Velocity Integration)
    for (int i = 0; i < world->activeCount; ++i) {
        NativeBody& b = world->bodies[i];
        if (b.type == STATIC) continue;

        b.vx += (world->gravityX + b.forceX * b.inverseMass) * dt;
        b.vy += (world->gravityY + b.forceY * b.inverseMass) * dt;
        b.angularVelocity += (b.torque * b.inverseInertia) * dt;
        
        b.forceX = b.forceY = b.torque = 0;
        b.collision_count = 0;
    }

    // 2. Constraint Solving (Velocity)
    for (int iter = 0; iter < world->velocityIterations; ++iter) {
        for (int i = 0; i < world->activeCount; ++i) {
            for (int j = i + 1; j < world->activeCount; ++j) {
                NativeBody& a = world->bodies[i];
                NativeBody& b = world->bodies[j];
                if (a.type == STATIC && b.type == STATIC) continue;

                CollisionManifold m = {{0,0}, 0, {{0,0}}, 0, false};
                if (a.shapeType == SHAPE_CIRCLE && b.shapeType == SHAPE_CIRCLE) m = detectCircleCircle(a, b);
                else if (a.shapeType == SHAPE_BOX && b.shapeType == SHAPE_BOX) m = detectBoxBox(a, b);
                else if (a.shapeType == SHAPE_CIRCLE) m = detectCircleBox(a, b);
                else m = detectCircleBox(b, a);

                if (m.collided) {
                    if (a.shapeType == SHAPE_CIRCLE && b.shapeType == SHAPE_BOX) {
                        m.normal = m.normal * -1.0f; 
                    }
                    
                    for (int c = 0; c < m.contactCount; ++c) {
                        Vec2 ra = m.contacts[c] - Vec2{a.x, a.y};
                        Vec2 rb = m.contacts[c] - Vec2{b.x, b.y};

                        Vec2 relativeVel = (Vec2{b.vx, b.vy} + cross(b.angularVelocity, rb)) - 
                                           (Vec2{a.vx, a.vy} + cross(a.angularVelocity, ra));

                        float contactVel = relativeVel.dot(m.normal);
                        if (contactVel > 0) continue;

                        float raCrossN = ra.cross(m.normal);
                        float rbCrossN = rb.cross(m.normal);
                        float invMassSum = a.inverseMass + b.inverseMass + 
                                          (raCrossN * raCrossN) * a.inverseInertia + 
                                          (rbCrossN * rbCrossN) * b.inverseInertia;

                        float e = 0.1f; // Simplified restitution
                        float j = -(1.0f + e) * contactVel;
                        j /= invMassSum;

                        Vec2 impulse = m.normal * j;
                        if (a.type == DYNAMIC) {
                            a.vx -= impulse.x * a.inverseMass;
                            a.vy -= impulse.y * a.inverseMass;
                            a.angularVelocity -= ra.cross(impulse) * a.inverseInertia;
                        }
                        if (b.type == DYNAMIC) {
                            b.vx += impulse.x * b.inverseMass;
                            b.vy += impulse.y * b.inverseMass;
                            b.angularVelocity += rb.cross(impulse) * b.inverseInertia;
                        }

                        // Friction (Standard implementation)
                        relativeVel = (Vec2{b.vx, b.vy} + cross(b.angularVelocity, rb)) - 
                                      (Vec2{a.vx, a.vy} + cross(a.angularVelocity, ra));
                        Vec2 tangent = relativeVel - (m.normal * relativeVel.dot(m.normal));
                        if (tangent.lengthSq() > 0.0001f) {
                            tangent = tangent * (1.0f / tangent.length());
                            float friction = 0.3f; // Default friction
                            float jt = -relativeVel.dot(tangent) / invMassSum;
                            jt = std::max(-j * friction, std::min(j * friction, jt));
                            
                            Vec2 fImpulse = tangent * jt;
                            if (a.type == DYNAMIC) {
                                a.vx -= fImpulse.x * a.inverseMass;
                                a.vy -= fImpulse.y * a.inverseMass;
                                a.angularVelocity -= ra.cross(fImpulse) * a.inverseInertia;
                            }
                            if (b.type == DYNAMIC) {
                                b.vx += fImpulse.x * b.inverseMass;
                                b.vy += fImpulse.y * b.inverseMass;
                                b.angularVelocity += rb.cross(fImpulse) * b.inverseInertia;
                            }
                        }
                    }
                    a.collision_count++;
                    b.collision_count++;
                }
            }
        }
    }

    // 3. Position Integration
    for (int i = 0; i < world->activeCount; ++i) {
        NativeBody& b = world->bodies[i];
        if (b.type == STATIC) continue;
        b.x += b.vx * dt;
        b.y += b.vy * dt;
        b.rotation += b.angularVelocity * dt;
    }

    // 4. Positional Correction (Baumgarte)
    const float slop = 0.05f;
    const float percent = 0.5f; // Slightly more aggressive
    for (int iter = 0; iter < world->positionIterations; ++iter) {
        for (int i = 0; i < world->activeCount; ++i) {
            for (int j = i + 1; j < world->activeCount; ++j) {
                NativeBody& a = world->bodies[i];
                NativeBody& b = world->bodies[j];
                if (a.type == STATIC && b.type == STATIC) continue;

                CollisionManifold m = {{0,0}, 0, {{0,0}}, 0, false};
                if (a.shapeType == SHAPE_CIRCLE && b.shapeType == SHAPE_CIRCLE) m = detectCircleCircle(a, b);
                else if (a.shapeType == SHAPE_BOX && b.shapeType == SHAPE_BOX) m = detectBoxBox(a, b);
                else if (a.shapeType == SHAPE_CIRCLE) m = detectCircleBox(a, b);
                else m = detectCircleBox(b, a);

                if (m.collided) {
                    if (a.shapeType == SHAPE_CIRCLE && b.shapeType == SHAPE_BOX) m.normal = m.normal * -1.0f;
                    float correction = (std::max(m.penetration - slop, 0.0f) / (a.inverseMass + b.inverseMass)) * percent;
                    Vec2 c = m.normal * correction;
                    if (a.type == DYNAMIC) { a.x -= c.x * a.inverseMass; a.y -= c.y * a.inverseMass; }
                    if (b.type == DYNAMIC) { b.x += c.x * b.inverseMass; b.y += c.y * b.inverseMass; }
                }
            }
        }
    }
}

int32_t create_body(PhysicsWorld* world, int type, int shapeType, float x, float y, float w, float h, float rotation) {
    if (!world || world->activeCount >= world->maxBodies) return -1;

    int32_t id = world->activeCount++;
    NativeBody& b = world->bodies[id];
    b.id = id;
    b.type = type;
    b.shapeType = shapeType;
    b.x = x;
    b.y = y;
    b.rotation = rotation;
    b.vx = b.vy = b.angularVelocity = 0;
    b.forceX = b.forceY = b.torque = 0;
    b.width = w;
    b.height = h;
    b.radius = (w < h ? w : h) / 2.0f;
    b.mass = (type == STATIC) ? 0.0f : 1.0f;
    b.inverseMass = (type == STATIC) ? 0.0f : 1.0f / b.mass;
    
    // Calculate Inertia
    if (type == STATIC) {
        b.inertia = b.inverseInertia = 0;
    } else {
        if (shapeType == SHAPE_BOX) b.inertia = (1.0f / 12.0f) * b.mass * (w * w + h * h);
        else b.inertia = 0.5f * b.mass * (b.radius * b.radius);
        b.inverseInertia = 1.0f / b.inertia;
    }
    
    b.restitution = 0.2f;
    b.friction = 0.4f;
    b.isSensor = false;
    b.collision_count = 0;

    return id;
}

void apply_force(PhysicsWorld* world, int32_t bodyId, float fx, float fy) {
    if (world && bodyId >= 0 && bodyId < world->activeCount) {
        world->bodies[bodyId].forceX += fx;
        world->bodies[bodyId].forceY += fy;
    }
}

void apply_torque(PhysicsWorld* world, int32_t bodyId, float torque) {
    if (world && bodyId >= 0 && bodyId < world->activeCount) {
        world->bodies[bodyId].torque += torque;
    }
}

void set_body_velocity(PhysicsWorld* world, int32_t bodyId, float vx, float vy) {
    if (world && bodyId >= 0 && bodyId < world->activeCount) {
        world->bodies[bodyId].vx = vx;
        world->bodies[bodyId].vy = vy;
    }
}

void get_body_position(PhysicsWorld* world, int32_t bodyId, float* x, float* y) {
    if (world && bodyId >= 0 && bodyId < world->activeCount) {
        *x = world->bodies[bodyId].x;
        *y = world->bodies[bodyId].y;
    }
}

}
