import 'package:flutter/material.dart';

class MenuItemModel {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final Color color;

  MenuItemModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.color,
  });
}
