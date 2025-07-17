import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../helpers/pagy_helpers.dart';
import 'common/pagy_empty_state_widget.dart';
import 'common/pagy_error_widget.dart';
import 'common/pagy_loading_widget.dart';
import 'common/pagy_missing_controller_widget.dart';

class PagyListView<T> extends StatelessWidget {
  final PagyController<T>? controller;
  final Widget Function(BuildContext context, T item) itemBuilder;

  final EdgeInsetsGeometry? padding;
  final bool disableScrolling;
  final bool shimmerEffect;
  final int placeholderItemCount;
  final T? placeholderItemModel;
  final bool shrinkWrap;
  final ScrollPhysics? scrollPhysics;
  final double itemsGap;
  final int? itemShowLimit;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  final Widget Function(String errorMessage, VoidCallback onRetry)?
      errorBuilder;
  final Widget Function(VoidCallback onRetry)? emptyStateRetryBuilder;
  final Widget? customLoader;

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
    this.itemShowLimit,
    this.errorBuilder,
    this.emptyStateRetryBuilder,
    this.customLoader,
    this.separatorBuilder,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyListView: shimmerEffect is enabled but placeholderItemModel is null.',
        );

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const MissingControllerWidget(name: 'PagyListView');
    }

    return ValueListenableBuilder<PagyState<T>>(
      valueListenable: controller!.controller,
      builder: (context, state, _) {
        // Initial loading
        if (state.isFetching) {
          return shimmerEffect
              ? _buildShimmerList()
              : (customLoader ??
                  PagyConfig().globalLoader ??
                  const DefaultPagyLoader());
        }

        // Error state
        if ((state.errorMessage?.isNotEmpty ?? false) && state.data.isEmpty) {
          return errorBuilder?.call(
                state.errorMessage!,
                () => controller!.loadData(),
              ) ??
              PagyConfig().globalErrorBuilder?.call(
                    state.errorMessage!,
                    () => controller!.loadData(),
                  ) ??
              DefaultErrorWidget(
                errorMessage: state.errorMessage!,
                onRetry: () => controller!.loadData(),
              );
        }

        // Empty state
        if (state.data.isEmpty) {
          return emptyStateRetryBuilder?.call(() => controller!.loadData()) ??
              PagyConfig()
                  .globalEmptyBuilder
                  ?.call(() => controller!.loadData()) ??
              DefaultEmptyWidget(onRetry: () => controller!.loadData());
        }

        // Data loaded — paginated list
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
              separatorBuilder:
                  separatorBuilder ?? (_, __) => SizedBox(height: itemsGap),
              shrinkWrap: shrinkWrap,
              physics: disableScrolling
                  ? const NeverScrollableScrollPhysics()
                  : scrollPhysics,
              padding: padding,
              itemCount: calculatePagyItemCount(state, itemShowLimit),
              itemBuilder: (context, index) {
                if (index >= state.data.length) {
                  return shimmerEffect
                      ? _buildShimmerItem(context)
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: customLoader ??
                              PagyConfig().globalLoader ??
                              const DefaultPagyLoader(),
                        );
                }
                return itemBuilder(context, state.data[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        separatorBuilder:
            separatorBuilder ?? (_, __) => SizedBox(height: itemsGap),
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

  Widget _buildShimmerItem(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: itemBuilder(context, placeholderItemModel as T),
    );
  }
}
