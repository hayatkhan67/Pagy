import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// A widget that displays paginated data in a grid view, with support for loading states, error handling,
/// empty states, and a shimmer effect while data is being fetched.
///
/// This widget uses the [PagyController] to manage pagination and provides options for customization
/// such as scroll behavior, spacing, and error handling.
///
/// The [itemBuilder] function is used to build each individual item in the grid.
///
/// Example usage:
/// ```dart
/// PagyGridView<MyModel>(
///   controller: pagyController,
///   itemBuilder: (context, item) => MyItemWidget(item),
/// )
/// ```
class PagyGridView<T> extends StatelessWidget {
  final PagyController<T>? controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final bool disableScrolling;
  final bool shimmerEffect;
  final int placeholderItemCount;
  final T? placeholderItemModel;
  final bool shrinkWrap;
  final ScrollPhysics? scrollPhysics;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int crossAxisCount;
  final Widget Function(String errorMessage, VoidCallback onRetry)?
      errorBuilder;
  final Widget Function(VoidCallback onRetry)? emptyStateRetryBuilder;

  /// Creates a new [PagyGridView] widget.
  ///
  /// The following parameters are required:
  /// - [controller]: The controller that manages pagination.
  /// - [itemBuilder]: A function that builds each grid item using the provided [BuildContext] and item.
  const PagyGridView({
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
    this.crossAxisSpacing = 9,
    this.mainAxisSpacing = 10,
    this.crossAxisCount = 2,
    this.errorBuilder,
    this.emptyStateRetryBuilder,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyGridView: shimmerEffect is enabled but placeholderItemModel is null.\n'
          'You must provide a valid placeholderItemModel when shimmerEffect is true.',
        );

  @override
  Widget build(BuildContext context) {
    // If controller is null, show an error widget
    if (controller == null) return const _MissingControllerWidget();

    return ValueListenableBuilder<PagyState<T>>(
      valueListenable: controller!.controller,
      builder: (context, state, _) {
        // If data is being fetched and no data is available, show loading state
        if (state.isFetching && state.data.isEmpty) {
          return shimmerEffect
              ? _buildShimmerGrid()
              : const Center(child: CircularProgressIndicator());
        }

        // If there is an error and no data, show the error widget
        if ((state.errorMessage?.isNotEmpty ?? false) && state.data.isEmpty) {
          return errorBuilder != null
              ? errorBuilder!(state.errorMessage!, () => controller!.loadData())
              : _defaultErrorWidget(state.errorMessage!);
        }

        // If there is no data, show the empty state widget
        if (state.data.isEmpty) {
          return emptyStateRetryBuilder?.call(() => controller!.loadData()) ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No data available',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => controller!.loadData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
        }

        // Display paginated data with infinite scroll and refresh
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            // Trigger load more data when scroll reaches the end
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
            child: MasonryGridView.builder(
              shrinkWrap: shrinkWrap,
              physics: disableScrolling
                  ? const NeverScrollableScrollPhysics()
                  : scrollPhysics,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(bottom: 16),
              gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
              ),
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              itemCount: state.data.length + (state.isMoreFetching ? 1 : 0),
              itemBuilder: (context, index) {
                // Show shimmer effect or loading indicator while fetching more data
                if (index >= state.data.length) {
                  return shimmerEffect
                      ? _buildShimmerItem(context)
                      : Padding(
                          padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.sizeOf(context).height * 0.09),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ));
                }

                // Build the item using the provided itemBuilder function
                return itemBuilder(context, state.data[index]);
              },
            ),
          ),
        );
      },
    );
  }

  /// Builds a grid view with shimmer effect for loading items.
  ///
  /// The shimmer effect is shown while waiting for data to be fetched.
  Widget _buildShimmerGrid() {
    return Skeletonizer(
      enabled: true,
      child: MasonryGridView.builder(
        shrinkWrap: shrinkWrap,
        physics: disableScrolling
            ? const NeverScrollableScrollPhysics()
            : scrollPhysics,
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        ),
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        itemCount: placeholderItemCount,
        itemBuilder: (context, _) =>
            itemBuilder(context, placeholderItemModel as T),
      ),
    );
  }

  /// Builds a single shimmer item for the grid while data is being fetched.
  Widget _buildShimmerItem(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: itemBuilder(context, placeholderItemModel as T),
    );
  }

  /// Default error widget to display when an error occurs.
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

/// Widget displayed when [PagyGridView] is not initialized with a valid controller.
class _MissingControllerWidget extends StatelessWidget {
  const _MissingControllerWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '⚠️ PagyGridView Error:\n\nController is not initialized.\n\nPlease pass a valid PagyController<T>.',
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
