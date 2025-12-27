import 'package:flutter/material.dart';
import '../../core/graph/node.dart';
import '../framework.dart';

class FNodes extends FMultiNodeWidget {
  const FNodes({super.key, required super.children, super.position, super.rotation, super.scale, super.name});

  @override
  State<FNodes> createState() => _FNodesState();
}

class _FNodesState extends FMultiNodeWidgetState<FNodes, FNode> {
  @override
  FNode createNode() => FNode();
}

class FNodeGroup extends FNodeWidget {
  const FNodeGroup({super.key, super.position, super.rotation, super.scale, super.name, super.child});

  @override
  State<FNodeGroup> createState() => _FNodeGroupState();
}

class _FNodeGroupState extends FNodeWidgetState<FNodeGroup, FNode> {
  @override
  FNode createNode() => FNode();
}
