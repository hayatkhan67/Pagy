import 'package:flutter/material.dart';

class DefaultEmptyWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const DefaultEmptyWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No data available', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
