import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../../../pagy.dart';
import '../../../../../core/utils/pagy_helpers.dart';

/// Signature for layout builder callback used in [PagyBuilder].
///
/// Provides the current [PagyState], total [itemCount], and an
/// [itemBuilder] function that can be passed to list/grid builders.
typedef LayoutBuilderCallback<T> = Widget Function(
  BuildContext context,
  PagyState<T> state,
  int itemCount,
  Widget Function(BuildContext, int) itemBuilder,
);

/// Signature for building a shimmer widget.
/// Used when shimmer placeholders are enabled.
typedef ShimmerBuilder = Widget Function(BuildContext context);

/// Core widget that powers [PagyBaseView], [PagyListView], and [PagyGridView].
///
/// This builder is responsible for:
/// - Listening to [PagyController] state changes
/// - Rendering shimmer placeholders during loading
/// - Handling full-screen error & empty states
/// - Rendering inline error/loader during pagination
/// - Integrating pull-to-refresh and infinite scroll
class PagyBuilder<T> extends StatelessWidget {
  /// Pagination controller that manages API calls and state.
  final PagyController<T>? controller;

  /// Function that builds the layout (List/Grid etc.).
  final LayoutBuilderCallback<T> layoutBuilder;

  /// Builder for individual list/grid items.
  final Widget Function(BuildContext, T item) itemBuilder;

  /// Optional shimmer builder for custom shimmer layouts.
  final ShimmerBuilder? shimmerBuilder;

  /// Whether shimmer placeholders should be shown while loading.
  final bool shimmerEffect;

  /// Marks whether this builder is used inside a GridView.
  final bool isGridView;

  /// Number of columns in GridView (ignored for ListView).
  final int crossAxisCount;

  /// Horizontal spacing between grid items.
  final double crossAxisSpacing;

  /// Vertical spacing between grid items.
  final double mainAxisSpacing;

  /// Gap between list items.
  final double itemsGap;

  /// Number of shimmer items to show when loading.
  final int placeholderItemCount;

  /// Placeholder model for shimmer item rendering.
  final T? placeholderItemModel;

  /// Optional separator builder for ListView.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Custom loader widget for pagination.
  final Widget? customLoader;

  /// Limit number of visible items (useful for previews).
  final int? itemShowLimit;

  /// Whether the list/grid should shrink-wrap its content.
  final bool shrinkWrap;

  /// Whether to completely disable scrolling.
  final bool disableScrolling;

  /// Custom scroll physics for list/grid.
  final ScrollPhysics? scrollPhysics;

  /// Padding applied to the list/grid.
  final EdgeInsetsGeometry? padding;

  /// Custom error widget builder for displaying errors.
  final Widget Function(String errorMessage, VoidCallback onRetry)?
      errorBuilder;

  /// Custom empty state widget builder with retry support.
  final Widget Function(VoidCallback onRetry)? emptyStateRetryBuilder;

  /// Creates a [PagyBuilder].
  ///
  /// Use this widget indirectly via [PagyListView] or [PagyGridView],
  /// unless you need advanced customization.
  const PagyBuilder({
    super.key,
    required this.controller,
    required this.layoutBuilder,
    required this.itemBuilder,
    this.shimmerBuilder,
    this.shimmerEffect = false,
    this.isGridView = false,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.itemsGap = 20,
    this.placeholderItemCount = 6,
    this.placeholderItemModel,
    this.separatorBuilder,
    this.customLoader,
    this.itemShowLimit,
    this.shrinkWrap = false,
    this.disableScrolling = false,
    this.scrollPhysics,
    this.padding,
    this.errorBuilder,
    this.emptyStateRetryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const MissingControllerWidget(name: 'PagyBuilder');
    }

    return ValueListenableBuilder<PagyState<T>>(
      valueListenable: controller!.controller,
      builder: (context, state, _) {
        // 1️⃣ Initial shimmer or loader
        if (state.isFetching) {
          return shimmerEffect && shimmerBuilder != null
              ? shimmerBuilder!(context)
              : _loader();
        }

        // 2️⃣ Full-screen error state (when no data available)
        if (_hasError(state) && state.data.isEmpty) {
          return _buildFullError(state.errorMessage!);
        }

        // 3️⃣ Empty state
        if (state.data.isEmpty) {
          return _buildEmpty();
        }

        // 4️⃣ Normal list with optional inline error/footer
        final hasInlineError = _hasError(state) && state.data.isNotEmpty;
        final baseCount = calculatePagyItemCount(state, itemShowLimit);
        final totalCount = baseCount + (hasInlineError ? 1 : 0);

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
            child: layoutBuilder(
              context,
              state,
              totalCount,
              (ctx, index) => _buildItem(ctx, index, state),
            ),
          ),
        );
      },
    );
  }

  /// Builds an individual item in the list/grid.
  ///
  /// Handles:
  /// - Normal item rendering
  /// - Inline error footer
  /// - Inline shimmer footer
  /// - Inline loader
  Widget _buildItem(BuildContext context, int index, PagyState<T> state) {
    if (index < state.data.length) {
      return itemBuilder(context, state.data[index]);
    }

    // 🔹 Inline error footer
    if (_hasError(state) && state.data.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: errorBuilder?.call(
              state.errorMessage!,
              () => controller!.loadData(refresh: false),
            ) ??
            PagyConfig().globalErrorBuilder?.call(
                  state.errorMessage!,
                  () => controller!.loadData(refresh: false),
                ) ??
            DefaultErrorWidget(
              errorMessage: state.errorMessage!,
              onRetry: () => controller!.loadData(refresh: false),
            ),
      );
    }

    // 🔹 Inline shimmer footer (when fetching more)
    if (state.isMoreFetching && shimmerEffect) {
      return _buildShimmerItem(context);
    }

    // 🔹 Inline loader fallback
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _loader(),
    );
  }

  /// Loader widget (custom or global).
  Widget _loader() =>
      customLoader ?? PagyConfig().globalLoader ?? const DefaultPagyLoader();

  /// Builds a full-screen error state widget.
  Widget _buildFullError(String message) =>
      errorBuilder?.call(message, () => controller!.loadData()) ??
      PagyConfig().globalErrorBuilder?.call(
            message,
            () => controller!.loadData(),
          ) ??
      DefaultErrorWidget(
        errorMessage: message,
        onRetry: () => controller!.loadData(),
      );

  /// Builds a full-screen empty state widget.
  Widget _buildEmpty() =>
      emptyStateRetryBuilder?.call(
        () => controller!.loadData(),
      ) ??
      PagyConfig().globalEmptyBuilder?.call(
            () => controller!.loadData(),
          ) ??
      DefaultEmptyWidget(onRetry: () => controller!.loadData());

  /// Returns true if the given [state] has an error message.
  bool _hasError(PagyState<T> state) =>
      (state.errorMessage?.isNotEmpty ?? false);

  /// Builds a shimmer placeholder for inline loading.
  Widget _buildShimmerItem(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: itemBuilder(context, placeholderItemModel as T),
    );
  }
}
