import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// A widget that provides a paginated list view with support for shimmer effects,
/// error handling, and custom item building.
class PagyListView<T> extends StatelessWidget {
  /// The controller that manages paginated state and triggers API requests.
  final PagyController<T>? controller;

  /// Builder function to create each list item from the model.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Padding for the list.
  final EdgeInsetsGeometry? padding;

  /// Disable user scrolling.
  final bool disableScrolling;

  /// Whether to show shimmer effect while loading.
  final bool shimmerEffect;

  /// Number of shimmer placeholder items to show.
  final int placeholderItemCount;

  /// The model to use for rendering shimmer placeholder items.
  final T? placeholderItemModel;

  /// Whether the list should shrink to fit its content.
  final bool shrinkWrap;

  /// Custom scroll physics.
  final ScrollPhysics? scrollPhysics;

  /// Gap between list items.
  final double itemsGap;

  /// Widget builder to display on error.
  final Widget Function(String errorMessage, VoidCallback onRetry)?
      errorBuilder;

  /// Builder for empty state widget with retry callback.
  final Widget Function(VoidCallback onRetry)? emptyStateRetryBuilder;

  /// Optional limit for the number of items to show on the screen.
  final int? itemShowLimit;

  /// Creates a [PagyListView] widget.
  const PagyListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.padding,
    this.disableScrolling = false,
    this.shimmerEffect = false,
    this.placeholderItemCount = 1,
    this.placeholderItemModel,
    this.shrinkWrap = false,
    this.scrollPhysics,
    this.itemsGap = 0,
    this.errorBuilder,
    this.emptyStateRetryBuilder,
    this.itemShowLimit,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyListView: shimmerEffect is enabled but placeholderItemModel is null.\n'
          'You must provide a valid placeholderItemModel when shimmerEffect is true.',
        );

  @override
  Widget build(BuildContext context) {
    // Return an error message if the controller is null
    if (controller == null) return const _MissingControllerWidget();

    return ValueListenableBuilder<PagyState<T>>(
      valueListenable: controller!.controller,
      builder: (context, state, _) {
        // Show shimmer or loading indicator if data is being fetched
        if (state.isFetching) {
          return shimmerEffect
              ? _buildShimmerList()
              : const Center(child: CircularProgressIndicator());
        }

        // Display an error message if an error occurs
        if (state.errorMessage != null &&
            (state.errorMessage?.isNotEmpty ?? false) &&
            state.data.isEmpty) {
          if (errorBuilder != null) {
            return errorBuilder!(
              state.errorMessage!,
              () => controller!.loadData(),
            );
          }
          return _defaultErrorWidget(state.errorMessage!);
        }

        // Handle empty data state
        if (state.data.isEmpty) {
          if (emptyStateRetryBuilder != null) {
            return emptyStateRetryBuilder!.call(() => controller!.loadData());
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No data available', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => controller!.loadData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Display list with scroll listener for pagination
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!state.isMoreFetching &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent -
                        PagyConfig().scrollOffset) {
              controller!.loadData(refresh: false);
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => controller!.loadData(),
            child: ListView.separated(
              separatorBuilder: (_, __) => SizedBox(height: itemsGap),
              shrinkWrap: shrinkWrap,
              physics: disableScrolling
                  ? const NeverScrollableScrollPhysics()
                  : null,
              padding: padding,
              itemCount: itemShowLimit != null && itemShowLimit! > 0
                  ? (state.data.length < itemShowLimit!
                      ? state.data.length + (state.isMoreFetching ? 1 : 0)
                      : itemShowLimit!)
                  : state.data.length + (state.isMoreFetching ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.data.length) {
                  return shimmerEffect
                      ? _buildShimmerItem(context)
                      : const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                }

                final item = state.data[index];
                return itemBuilder(context, item);
              },
            ),
          ),
        );
      },
    );
  }

  /// Builds a list view with shimmer effect while loading data.
  Widget _buildShimmerList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        separatorBuilder: (_, __) => SizedBox(height: itemsGap),
        shrinkWrap: shrinkWrap,
        physics: disableScrolling
            ? const NeverScrollableScrollPhysics()
            : scrollPhysics,
        padding: padding,
        itemCount: placeholderItemCount,
        itemBuilder: (context, _) =>
            itemBuilder(context, placeholderItemModel as T),
      ),
    );
  }

  /// Builds a single shimmer item while loading.
  Widget _buildShimmerItem(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: itemBuilder(context, placeholderItemModel as T),
    );
  }

  /// Displays a default error widget with an error message and retry button.
  Widget _defaultErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            maxLines: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => controller!.loadData(),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}

/// Widget displayed when the controller is missing or not initialized.
class _MissingControllerWidget extends StatelessWidget {
  const _MissingControllerWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '⚠️ PagyListView Error:\n\nController is not initialized.\n\nPlease pass a valid PagyController<T>.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
