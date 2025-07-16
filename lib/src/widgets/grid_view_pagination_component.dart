import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../helpers/pagy_helpers.dart';
import 'common/pagy_empty_state_widget.dart';
import 'common/pagy_error_widget.dart';
import 'common/pagy_loading_widget.dart';
import 'common/pagy_missing_controller_widget.dart';

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

  final int? itemShowLimit;

  final Widget Function(String errorMessage, VoidCallback onRetry)?
      errorBuilder;
  final Widget Function(VoidCallback onRetry)? emptyStateRetryBuilder;
  final Widget? customLoader;

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
    this.itemShowLimit,
    this.errorBuilder,
    this.emptyStateRetryBuilder,
    this.customLoader,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyGridView: shimmerEffect is enabled but placeholderItemModel is null.',
        );

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const MissingControllerWidget(name: 'PagyGridView');
    }

    return ValueListenableBuilder<PagyState<T>>(
      valueListenable: controller!.controller,
      builder: (context, state, _) {
        if (state.isFetching) {
          return shimmerEffect
              ? _buildShimmerGrid()
              : (customLoader ??
                  PagyConfig().globalLoader ??
                  const DefaultPagyLoader());
        }

        if ((state.errorMessage?.isNotEmpty ?? false) && state.data.isEmpty) {
          return errorBuilder?.call(
                  state.errorMessage!, () => controller!.loadData()) ??
              PagyConfig()
                  .globalErrorBuilder
                  ?.call(state.errorMessage!, () => controller!.loadData()) ??
              DefaultErrorWidget(
                errorMessage: state.errorMessage!,
                onRetry: () => controller!.loadData(),
              );
        }

        if (state.data.isEmpty) {
          return emptyStateRetryBuilder?.call(() => controller!.loadData()) ??
              PagyConfig()
                  .globalEmptyBuilder
                  ?.call(() => controller!.loadData()) ??
              DefaultEmptyWidget(onRetry: () => controller!.loadData());
        }

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
              itemCount: calculatePagyItemCount(state, itemShowLimit),
              itemBuilder: (context, index) {
                if (index >= state.data.length) {
                  return shimmerEffect
                      ? _buildShimmerItem(context)
                      : Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: MediaQuery.sizeOf(context).height * 0.09,
                          ),
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

  Widget _buildShimmerItem(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: itemBuilder(context, placeholderItemModel as T),
    );
  }
}
