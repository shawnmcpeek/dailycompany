import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HallwayBackButton extends StatelessWidget {
  const HallwayBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'The hallway',
      onPressed: () => context.go('/hallway'),
      icon: const Icon(Icons.arrow_back),
    );
  }
}
