import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.path,
    required this.icon,
    this.activePaths = const <String>[],
  });

  final String label;
  final String path;
  final IconData icon;
  final List<String> activePaths;

  bool matches(String location) {
    if (location == path) {
      return true;
    }
    return activePaths.contains(location);
  }
}
