import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../controllers/pagy_controller.dart';
import 'common/pagy_builder.dart';
import 'common/pagy_shimmer.dart';

class PagyGridView<T> extends StatelessWidget {
  final PagyController<T>? controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int crossAxisCount;
  final EdgeInsetsGeometry? padding;
  final bool shimmerEffect;
  final int placeholderItemCount;
  final T? placeholderItemModel;
  final bool shrinkWrap;
  final bool disableScrolling;
  final ScrollPhysics? scrollPhysics;
  final int? itemShowLimit;
  final Widget Function(String, VoidCallback)? errorBuilder;
  final Widget Function(VoidCallback)? emptyStateRetryBuilder;
  final Widget? customLoader;

  const PagyGridView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.crossAxisSpacing = 9,
    this.mainAxisSpacing = 10,
    this.crossAxisCount = 2,
    this.padding,
    this.shimmerEffect = false,
    this.placeholderItemCount = 1,
    this.placeholderItemModel,
    this.shrinkWrap = false,
    this.disableScrolling = false,
    this.scrollPhysics,
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
    return PagyBuilder<T>(
      controller: controller,
      itemBuilder: itemBuilder,
      isGridView: true,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      placeholderItemCount: placeholderItemCount,
      placeholderItemModel: placeholderItemModel,
      shimmerEffect: shimmerEffect,
      customLoader: customLoader,
      shrinkWrap: shrinkWrap,
      disableScrolling: disableScrolling,
      scrollPhysics: scrollPhysics,
      padding: padding,
      itemShowLimit: itemShowLimit,
      errorBuilder: errorBuilder,
      emptyStateRetryBuilder: emptyStateRetryBuilder,
      shimmerBuilder: shimmerEffect
          ? (ctx) => PagyShimmer<T>(
                count: placeholderItemCount,
                itemBuilder: (c, _) =>
                    itemBuilder(c, placeholderItemModel as T),
                layoutBuilder: (childBuilder) => MasonryGridView.builder(
                  shrinkWrap: shrinkWrap,
                  gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                  ),
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  itemCount: placeholderItemCount,
                  itemBuilder: childBuilder,
                ),
              )
          : null,
      layoutBuilder: (context, state, itemCount, itemBuilderFn) {
        return MasonryGridView.builder(
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
          itemCount: itemCount,
          itemBuilder: itemBuilderFn,
        );
      },
    );
  }
}
