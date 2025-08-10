import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../../../pagy.dart';
import '../../../../../core/utils/pagy_helpers.dart';

typedef LayoutBuilderCallback<T> = Widget Function(
  BuildContext context,
  PagyState<T> state,
  int itemCount,
  Widget Function(BuildContext, int) itemBuilder,
);

typedef ShimmerBuilder = Widget Function(BuildContext context);

class PagyBuilder<T> extends StatelessWidget {
  final PagyController<T>? controller;
  final LayoutBuilderCallback<T> layoutBuilder;
  final Widget Function(BuildContext, T item) itemBuilder;
  final ShimmerBuilder? shimmerBuilder;

  final bool shimmerEffect;
  final bool isGridView;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double itemsGap;
  final int placeholderItemCount;
  final T? placeholderItemModel;
  final IndexedWidgetBuilder? separatorBuilder;

  final Widget? customLoader;
  final int? itemShowLimit;
  final bool shrinkWrap;
  final bool disableScrolling;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsetsGeometry? padding;

  final Widget Function(String errorMessage, VoidCallback onRetry)?
      errorBuilder;
  final Widget Function(VoidCallback onRetry)? emptyStateRetryBuilder;

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
        // 1️⃣ Initial shimmer load
        if (state.isFetching) {
          return shimmerEffect && shimmerBuilder != null
              ? shimmerBuilder!(context)
              : _loader();
        }

        // 2️⃣ Full error screen (no data)
        if (_hasError(state) && state.data.isEmpty) {
          return _buildFullError(state.errorMessage!);
        }

        // 3️⃣ Empty state
        if (state.data.isEmpty) {
          return _buildEmpty();
        }

        // 4️⃣ Normal list with optional footer
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

  /// Build each item including shimmer or error footer
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

    // 🔹 Inline shimmer footer (loading more)
    if (state.isMoreFetching && shimmerEffect) {
      return _buildShimmerItem(context);
    }

    // 🔹 Inline loader
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _loader(),
    );
  }

  /// Loader widget (configurable)
  Widget _loader() =>
      customLoader ?? PagyConfig().globalLoader ?? const DefaultPagyLoader();

  /// Full-screen error widget
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

  /// Empty state widget
  Widget _buildEmpty() =>
      emptyStateRetryBuilder?.call(
        () => controller!.loadData(),
      ) ??
      PagyConfig().globalEmptyBuilder?.call(
            () => controller!.loadData(),
          ) ??
      DefaultEmptyWidget(onRetry: () => controller!.loadData());

  bool _hasError(PagyState<T> state) =>
      (state.errorMessage?.isNotEmpty ?? false);

  Widget _buildShimmerItem(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: itemBuilder(context, placeholderItemModel as T),
    );
  }
}
