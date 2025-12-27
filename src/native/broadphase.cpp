#include "broadphase.h"
#include "physics.h"
#include <cmath>
#include <algorithm>

extern "C" {

SpatialHashGrid* create_spatial_grid(float worldMinX, float worldMinY, 
                                     float worldMaxX, float worldMaxY, 
                                     float cellSize) {
    SpatialHashGrid* grid = new SpatialHashGrid();
    
    grid->worldMinX = worldMinX;
    grid->worldMinY = worldMinY;
    grid->worldMaxX = worldMaxX;
    grid->worldMaxY = worldMaxY;
    grid->cellSize = cellSize;
    
    grid->gridWidth = (int)std::ceil((worldMaxX - worldMinX) / cellSize);
    grid->gridHeight = (int)std::ceil((worldMaxY - worldMinY) / cellSize);
    
    int totalCells = grid->gridWidth * grid->gridHeight;
    grid->cells = new GridCell[totalCells];
    
    return grid;
}

void destroy_spatial_grid(SpatialHashGrid* grid) {
    if (!grid) return;
    delete[] grid->cells;
    delete grid;
}

void clear_spatial_grid(SpatialHashGrid* grid) {
    if (!grid) return;
    
    int totalCells = grid->gridWidth * grid->gridHeight;
    for (int i = 0; i < totalCells; ++i) {
        grid->cells[i].bodyIds.clear();
    }
    grid->pairs.clear();
}

// Hash function for pair caching
inline uint64_t make_pair_key(uint32_t a, uint32_t b) {
    if (a > b) std::swap(a, b);
    return ((uint64_t)a << 32) | b;
}

void insert_into_grid(SpatialHashGrid* grid, uint32_t bodyId, const AABB& aabb) {
    if (!grid) return;
    
    // Calculate grid cell range that AABB overlaps
    int minCellX = (int)std::floor((aabb.minX - grid->worldMinX) / grid->cellSize);
    int minCellY = (int)std::floor((aabb.minY - grid->worldMinY) / grid->cellSize);
    int maxCellX = (int)std::floor((aabb.maxX - grid->worldMinX) / grid->cellSize);
    int maxCellY = (int)std::floor((aabb.maxY - grid->worldMinY) / grid->cellSize);
    
    // Clamp to grid bounds
    minCellX = std::max(0, std::min(minCellX, grid->gridWidth - 1));
    minCellY = std::max(0, std::min(minCellY, grid->gridHeight - 1));
    maxCellX = std::max(0, std::min(maxCellX, grid->gridWidth - 1));
    maxCellY = std::max(0, std::min(maxCellY, grid->gridHeight - 1));
    
    // Insert body into all overlapping cells
    for (int y = minCellY; y <= maxCellY; ++y) {
        for (int x = minCellX; x <= maxCellX; ++x) {
            int cellIndex = y * grid->gridWidth + x;
            grid->cells[cellIndex].bodyIds.push_back(bodyId);
        }
    }
}

int query_grid_pairs(SpatialHashGrid* grid, BroadphasePair* outPairs, int maxPairs) {
    if (!grid) return 0;
    
    // Clear the pairs cache for this frame
    grid->pairs.clear();
    
    int totalCells = grid->gridWidth * grid->gridHeight;
    
    // 1. Collect ALL potential pairs (including duplicates)
    for (int i = 0; i < totalCells; ++i) {
        const auto& bodyIds = grid->cells[i].bodyIds;
        size_t count = bodyIds.size();
        
        if (count < 2) continue;
        
        for (size_t j = 0; j < count; ++j) {
            for (size_t k = j + 1; k < count; ++k) {
                uint32_t a = bodyIds[j];
                uint32_t b = bodyIds[k];
                
                // Store pair as uint64_t key
                if (a > b) std::swap(a, b);
                uint64_t key = ((uint64_t)a << 32) | b;
                
                grid->pairs.push_back(key);
            }
        }
    }
    
    // 2. Sort and Unique to remove duplicates
    if (grid->pairs.empty()) return 0;
    
    std::sort(grid->pairs.begin(), grid->pairs.end());
    auto last = std::unique(grid->pairs.begin(), grid->pairs.end());
    grid->pairs.erase(last, grid->pairs.end());
    
    // 3. Output unique pairs
    int pairCount = 0;
    for (uint64_t key : grid->pairs) {
        if (pairCount >= maxPairs) break;
        
        outPairs[pairCount].bodyA = (uint32_t)(key >> 32);
        outPairs[pairCount].bodyB = (uint32_t)(key & 0xFFFFFFFF);
        pairCount++;
    }
    
    return pairCount;
}

AABB calculate_body_aabb(const NativeBody& body) {
    AABB aabb;
    
    if (body.shapeType == SHAPE_CIRCLE) {
        aabb.minX = body.x - body.radius;
        aabb.minY = body.y - body.radius;
        aabb.maxX = body.x + body.radius;
        aabb.maxY = body.y + body.radius;
    } else {
        // Box - need to account for rotation
        float hw = body.width * 0.5f;
        float hh = body.height * 0.5f;
        float c = std::cos(body.rotation);
        float s = std::sin(body.rotation);
        
        // Calculate rotated corners
        float corners[4][2] = {
            {-hw * c - (-hh) * s, -hw * s + (-hh) * c},
            { hw * c - (-hh) * s,  hw * s + (-hh) * c},
            { hw * c -   hh  * s,  hw * s +   hh  * c},
            {-hw * c -   hh  * s, -hw * s +   hh  * c}
        };
        
        // Find min/max
        aabb.minX = aabb.maxX = body.x + corners[0][0];
        aabb.minY = aabb.maxY = body.y + corners[0][1];
        
        for (int i = 1; i < 4; ++i) {
            float x = body.x + corners[i][0];
            float y = body.y + corners[i][1];
            aabb.minX = std::min(aabb.minX, x);
            aabb.minY = std::min(aabb.minY, y);
            aabb.maxX = std::max(aabb.maxX, x);
            aabb.maxY = std::max(aabb.maxY, y);
        }
    }
    
    // Fatten AABB slightly for temporal coherence
    aabb.fatten(2.0f);
    
    return aabb;
}

}
