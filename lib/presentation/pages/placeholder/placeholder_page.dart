import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  static const String route = '/placeholder';
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Placeholder());
  }
}
