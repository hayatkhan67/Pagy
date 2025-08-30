import 'package:flutter/material.dart';

import '../controllers/pagy_controller.dart';
import 'common/pagy_builder.dart';
import 'common/pagy_shimmer.dart';

/// A customizable [ListView] wrapper powered by [PagyController].
/// Handles pagination states (loading, error, empty, data) automatically.
///
/// Features:
/// - Shimmer loading placeholders
/// - Retry handling for empty/error states
/// - Custom separators, loaders, padding, scrolling options
/// - Optional max visible items (preview mode)
class PagyListView<T> extends StatelessWidget {
  /// The controller that manages pagination logic and state.
  final PagyController<T>? controller;

  /// Builder for rendering each item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Space between items in the list.
  final double itemSpacing;

  /// ListView padding around content.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether to show shimmer loading placeholders.
  final bool enableShimmer;

  /// Number of shimmer placeholder items during loading.
  final int shimmerItemCount;

  /// The model used to build shimmer placeholders.
  /// Must not be null if [enableShimmer] is true.
  final T? shimmerItemModel;

  /// Wraps list content to take minimum height.
  final bool shrinkWrap;

  /// Disable list scrolling (useful inside [SingleChildScrollView]).
  final bool isScrollDisabled;

  /// Custom scroll physics.
  final ScrollPhysics? scrollPhysics;

  /// Limit the number of items shown (useful for previews/dashboards).
  final int? maxVisibleItems;

  /// Custom error widget builder with error message + retry callback.
  final Widget Function(String, VoidCallback)? onErrorBuilder;

  /// Custom empty state widget builder with retry callback.
  final Widget Function(VoidCallback)? onEmptyBuilder;

  /// Custom loader widget (instead of default CircularProgressIndicator).
  final Widget? loaderWidget;

  /// Custom separator builder between items.
  final Widget Function(BuildContext, int)? separatorBuilder;

  const PagyListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.itemSpacing = 0,
    this.contentPadding,
    this.enableShimmer = false,
    this.shimmerItemCount = 1,
    this.shimmerItemModel,
    this.shrinkWrap = false,
    this.isScrollDisabled = false,
    this.scrollPhysics,
    this.maxVisibleItems,
    this.onErrorBuilder,
    this.onEmptyBuilder,
    this.loaderWidget,
    this.separatorBuilder,
  }) : assert(
          shimmerItemModel != null || !enableShimmer,
          'PagyListView: enableShimmer is true but shimmerItemModel is null. '
          'Provide a shimmerItemModel when enabling shimmer placeholders.',
        );

  @override
  Widget build(BuildContext context) {
    return PagyBuilder<T>(
      controller: controller,
      itemBuilder: itemBuilder,
      shimmerEffect: enableShimmer,
      customLoader: loaderWidget,
      shrinkWrap: shrinkWrap,
      disableScrolling: isScrollDisabled,
      scrollPhysics: scrollPhysics,
      padding: contentPadding,
      itemShowLimit: maxVisibleItems,
      errorBuilder: onErrorBuilder,
      emptyStateRetryBuilder: onEmptyBuilder,
      separatorBuilder: separatorBuilder,
      isGridView: false,
      placeholderItemCount: shimmerItemCount,
      placeholderItemModel: shimmerItemModel,
      shimmerBuilder: enableShimmer
          ? (ctx) => PagyShimmer<T>(
                count: shimmerItemCount,
                itemBuilder: (c, _) => itemBuilder(c, shimmerItemModel as T),
                layoutBuilder: (childBuilder) => ListView.separated(
                  separatorBuilder: separatorBuilder ??
                      (_, __) => SizedBox(height: itemSpacing),
                  shrinkWrap: shrinkWrap,
                  physics: isScrollDisabled
                      ? const NeverScrollableScrollPhysics()
                      : scrollPhysics,
                  padding: contentPadding,
                  itemCount: shimmerItemCount,
                  itemBuilder: childBuilder,
                ),
              )
          : null,
      layoutBuilder: (context, state, itemCount, itemBuilderFn) {
        return ListView.separated(
          separatorBuilder:
              separatorBuilder ?? (_, __) => SizedBox(height: itemSpacing),
          shrinkWrap: shrinkWrap,
          physics: isScrollDisabled
              ? const NeverScrollableScrollPhysics()
              : scrollPhysics,
          padding: contentPadding,
          itemCount: itemCount,
          itemBuilder: itemBuilderFn,
        );
      },
    );
  }
}
