import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final IconData icon;
}
