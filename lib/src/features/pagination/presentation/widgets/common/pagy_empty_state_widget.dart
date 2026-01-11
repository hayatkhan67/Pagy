import 'package:flutter/material.dart';

/// Default empty state widget displayed when no data is available.
///
/// This widget shows a customizable message with an optional icon and
/// retry button. It is used by [PagyBuilder] when no custom empty state
/// builder is provided.
///
/// Example:
/// ```dart
/// DefaultEmptyWidget(
///   onRetry: () => controller.loadData(),
///   message: 'No items found',
///   icon: Icons.inbox_outlined,
///   showRetryButton: true,
/// )
/// ```
class DefaultEmptyWidget extends StatelessWidget {
  /// Callback invoked when the retry button is pressed.
  final VoidCallback onRetry;

  /// Message displayed in the empty state.
  ///
  /// Defaults to `'No data available'`.
  final String message;

  /// Optional icon displayed above the message.
  ///
  /// If `null`, no icon is shown.
  final IconData? icon;

  /// Whether to show the retry button.
  ///
  /// Defaults to `true`. Set to `false` if you prefer users to
  /// use pull-to-refresh instead.
  final bool showRetryButton;

  /// Creates a [DefaultEmptyWidget].
  const DefaultEmptyWidget({
    super.key,
    required this.onRetry,
    this.message = 'No data available',
    this.icon,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRetryButton) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
