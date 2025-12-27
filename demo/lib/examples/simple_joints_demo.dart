import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class SimpleJointsDemo extends StatelessWidget {
  const SimpleJointsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Declarative Joints Demo'), backgroundColor: Colors.black87),
      body: FView(
        child: Stack(
          children: [
            // Orthographic camera for consistent 2D layout
            FCamera(position: v.Vector3(0, 0, 1000), isOrthographic: true, orthographicSize: 400.0),

            // Static Ground
            FStaticBody(
              name: 'Ground',
              position: v.Vector3(0, -350, 0),
              width: 1000,
              height: 40,
              child: FBox(width: 1000, height: 40, color: Colors.grey[900]!),
            ),

            // --- Rope Bridge Section ---
            FStaticBody(
              name: 'BridgeAnchorLeft',
              position: v.Vector3(-250, 150, 0),
              width: 30,
              height: 30,
              child: FBox(width: 30, height: 30, color: Colors.brown),
            ),
            FStaticBody(
              name: 'BridgeAnchorRight',
              position: v.Vector3(250, 150, 0),
              width: 30,
              height: 30,
              child: FBox(width: 30, height: 30, color: Colors.brown),
            ),

            // Rope segments
            for (int i = 0; i < 5; i++)
              FRigidBody.square(
                key: ValueKey('rope_$i'),
                name: 'Rope$i',
                position: v.Vector3(-150.0 + (i * 75), 150, 0),
                size: 30,
                child: FBox(width: 30, height: 30, color: Colors.orange),
              ),

            // Declarative Joints for Rope
            FDistanceJoint(nodeA: 'BridgeAnchorLeft', nodeB: 'Rope0', length: 75, frequency: 10, dampingRatio: 0.5),
            FDistanceJoint(nodeA: 'Rope0', nodeB: 'Rope1', length: 75, frequency: 10, dampingRatio: 0.5),
            FDistanceJoint(nodeA: 'Rope1', nodeB: 'Rope2', length: 75, frequency: 10, dampingRatio: 0.5),
            FDistanceJoint(nodeA: 'Rope2', nodeB: 'Rope3', length: 75, frequency: 10, dampingRatio: 0.5),
            FDistanceJoint(nodeA: 'Rope3', nodeB: 'Rope4', length: 75, frequency: 10, dampingRatio: 0.5),
            FDistanceJoint(nodeA: 'Rope4', nodeB: 'BridgeAnchorRight', length: 75, frequency: 10, dampingRatio: 0.5),

            // --- Pendulum Section ---
            FStaticBody(
              name: 'PendulumPivot',
              position: v.Vector3(-200, 0, 0),
              width: 20,
              height: 20,
              child: FCircle(radius: 10, color: Colors.blueGrey),
            ),
            FRigidBody.circle(
              name: 'PendulumBob',
              position: v.Vector3(-100, 0, 0),
              radius: 25,
              child: FCircle(radius: 25, color: Colors.blue),
            ),
            FRevoluteJoint(nodeA: 'PendulumPivot', nodeB: 'PendulumBob', anchor: v.Vector2(-200, 0)),

            // --- Motor Section ---
            FStaticBody(
              name: 'MotorPivot',
              position: v.Vector3(150, 0, 0),
              width: 20,
              height: 20,
              child: FCircle(radius: 10, color: Colors.redAccent),
            ),
            FRigidBody.square(
              name: 'MotorBox',
              position: v.Vector3(150, 0, 0),
              size: 60,
              child: FBox(width: 60, height: 60, color: Colors.purpleAccent),
            ),
            FRevoluteJoint(
              nodeA: 'MotorPivot',
              nodeB: 'MotorBox',
              anchor: v.Vector2(150, 0),
              enableMotor: true,
              motorSpeed: 3.0,
              maxMotorTorque: 5000.0,
            ),
          ],
        ),
      ),
    );
  }
}
