import 'package:flutter/material.dart';
import '../../../../../pagy.dart';
import 'common/pagy_builder.dart';
import 'common/pagy_shimmer.dart';

class PagyListView<T> extends StatelessWidget {
  final PagyController<T>? controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double itemsGap;
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
  final Widget Function(BuildContext, int)? separatorBuilder;

  const PagyListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.itemsGap = 0,
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
    this.separatorBuilder,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyListView: shimmerEffect is enabled but placeholderItemModel is null.',
        );

  @override
  Widget build(BuildContext context) {
    return PagyBuilder<T>(
      controller: controller,
      itemBuilder: itemBuilder,
      shimmerEffect: shimmerEffect,
      customLoader: customLoader,
      shrinkWrap: shrinkWrap,
      disableScrolling: disableScrolling,
      scrollPhysics: scrollPhysics,
      padding: padding,
      itemShowLimit: itemShowLimit,
      errorBuilder: errorBuilder,
      emptyStateRetryBuilder: emptyStateRetryBuilder,
      separatorBuilder: separatorBuilder,
      isGridView: false,
      placeholderItemCount: placeholderItemCount,
      placeholderItemModel: placeholderItemModel,
      shimmerBuilder: shimmerEffect
          ? (ctx) => PagyShimmer<T>(
                count: placeholderItemCount,
                itemBuilder: (c, _) =>
                    itemBuilder(c, placeholderItemModel as T),
                layoutBuilder: (childBuilder) => ListView.separated(
                  separatorBuilder:
                      separatorBuilder ?? (_, __) => SizedBox(height: itemsGap),
                  shrinkWrap: shrinkWrap,
                  physics: disableScrolling
                      ? const NeverScrollableScrollPhysics()
                      : scrollPhysics,
                  padding: padding,
                  itemCount: placeholderItemCount,
                  itemBuilder: childBuilder,
                ),
              )
          : null,
      layoutBuilder: (context, state, itemCount, itemBuilderFn) {
        return ListView.separated(
          separatorBuilder:
              separatorBuilder ?? (_, __) => SizedBox(height: itemsGap),
          shrinkWrap: shrinkWrap,
          physics: disableScrolling
              ? const NeverScrollableScrollPhysics()
              : scrollPhysics,
          padding: padding,
          itemCount: itemCount,
          itemBuilder: itemBuilderFn,
        );
      },
    );
  }
}
