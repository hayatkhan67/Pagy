import 'package:flutter/material.dart';

class MissingControllerWidget extends StatelessWidget {
  final String name;

  const MissingControllerWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '⚠️ $name Error:\n\nController is not initialized.\n\nPlease pass a valid PagyController<T>.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
