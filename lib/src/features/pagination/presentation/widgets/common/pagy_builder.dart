import 'package:flutter/material.dart';

import '../../../../../../pagy.dart';
import '../../../../../core/utils/pagy_helpers.dart';

class PagyBuilder<T> extends StatelessWidget {
  final PagyController<T> controller;
  final int? itemShowLimit;

  /// Builds each data item
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Builds the shimmer widget for one item
  final Widget Function(BuildContext context)? shimmerItemBuilder;

  /// Builds the scrollable list/grid
  final Widget Function(
          BuildContext context, int itemCount, IndexedWidgetBuilder itemBuilder)
      builder;

  /// Optional padding & loader
  final Widget? customLoader;

  /// Error & empty builders
  final Widget Function(String errorMessage, VoidCallback onRetry)?
      errorBuilder;
  final Widget Function(VoidCallback onRetry)? emptyStateRetryBuilder;

  const PagyBuilder({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.builder,
    this.shimmerItemBuilder,
    this.customLoader,
    this.errorBuilder,
    this.emptyStateRetryBuilder,
    this.itemShowLimit,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PagyState<T>>(
      valueListenable: controller.controller,
      builder: (context, state, _) {
        // Initial loading (no data yet)
        if (state.isFetching && state.data.isEmpty) {
          return shimmerItemBuilder != null
              ? builder(context, 5, (ctx, _) => shimmerItemBuilder!(ctx))
              : (customLoader ??
                  PagyConfig().globalLoader ??
                  const DefaultPagyLoader());
        }

        // Full-page error
        if ((state.errorMessage?.isNotEmpty ?? false) && state.data.isEmpty) {
          return errorBuilder?.call(
                  state.errorMessage!, () => controller.loadData()) ??
              PagyConfig()
                  .globalErrorBuilder
                  ?.call(state.errorMessage!, () => controller.loadData()) ??
              DefaultErrorWidget(
                errorMessage: state.errorMessage!,
                onRetry: () => controller.loadData(),
              );
        }

        // Empty state
        if (state.data.isEmpty) {
          return emptyStateRetryBuilder?.call(() => controller.loadData()) ??
              PagyConfig()
                  .globalEmptyBuilder
                  ?.call(() => controller.loadData()) ??
              DefaultEmptyWidget(onRetry: () => controller.loadData());
        }

        // Normal state (with pagination)
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!state.isMoreFetching &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent -
                        PagyConfig().scrollOffset) {
              controller.loadData(refresh: false);
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => controller.loadData(),
            child: builder(
              context,
              calculatePagyItemCount(state, itemShowLimit) +
                  ((state.errorMessage?.isNotEmpty ?? false) &&
                          state.data.isNotEmpty
                      ? 1
                      : 0),
              (ctx, index) {
                if (index < state.data.length) {
                  return itemBuilder(ctx, state.data[index]);
                }

                // Page 2+ error at bottom
                if ((state.errorMessage?.isNotEmpty ?? false) &&
                    state.data.isNotEmpty) {
                  return errorBuilder?.call(
                        state.errorMessage!,
                        () => controller.loadData(refresh: false),
                      ) ??
                      PagyConfig().globalErrorBuilder?.call(
                            state.errorMessage!,
                            () => controller.loadData(refresh: false),
                          ) ??
                      DefaultErrorWidget(
                        errorMessage: state.errorMessage!,
                        onRetry: () => controller.loadData(refresh: false),
                      );
                }

                // Loader for "load more"
                return shimmerItemBuilder != null
                    ? shimmerItemBuilder!(ctx)
                    : (customLoader ??
                        PagyConfig().globalLoader ??
                        const DefaultPagyLoader());
              },
            ),
          ),
        );
      },
    );
  }
}
