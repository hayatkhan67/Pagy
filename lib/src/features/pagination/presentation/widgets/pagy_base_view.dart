import 'package:flutter/material.dart';

import '../controllers/pagy_controller.dart';
import 'common/pagy_builder.dart';
import 'common/pagy_shimmer.dart';

/// Base widget for Pagy-powered list/grid views.
///
/// This widget provides the **common pagination boilerplate** used by
/// [`PagyListView`] and [`PagyGridView`]. It handles:
///
/// - Shimmer placeholders during loading
/// - Error and empty states
/// - Retry callbacks
/// - Layout delegation to child widgets
///
/// Extend this class when creating new Pagy-based layouts (e.g. StaggeredGridView).
abstract class PagyBaseView<T> extends StatelessWidget {
  /// Controller that manages pagination state and API calls.
  final PagyController<T>? controller;

  /// Function that builds each item in the list/grid.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Enables shimmer placeholders while loading.
  final bool shimmerEffect;

  /// Number of placeholder items to display during shimmer.
  final int placeholderItemCount;

  /// Model used to render a single shimmer placeholder item.
  ///
  /// Required if [shimmerEffect] is enabled.
  final T? placeholderItemModel;

  /// Whether the list/grid should shrink to fit content.
  final bool shrinkWrap;

  /// Whether to completely disable scrolling (useful inside parent scrollable).
  final bool disableScrolling;

  /// Custom scroll physics for list/grid.
  final ScrollPhysics? scrollPhysics;

  /// Padding applied around the list/grid.
  final EdgeInsetsGeometry? padding;

  /// Maximum number of items to render (for preview or limit).
  final int? itemShowLimit;

  /// Builder function for rendering an error state.
  ///
  /// Provides the error message and a retry callback.
  final Widget Function(String, VoidCallback)? errorBuilder;

  /// Builder function for rendering an empty state with retry support.
  final Widget Function(VoidCallback)? emptyStateRetryBuilder;

  /// Custom loader widget shown during pagination.
  final Widget? customLoader;

  /// Creates a base Pagy-powered view.
  ///
  /// - [controller] is required to manage pagination.
  /// - [itemBuilder] builds each item in the list/grid.
  /// - [shimmerEffect] requires [placeholderItemModel].
  const PagyBaseView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.shimmerEffect = false,
    this.placeholderItemCount = 1,
    this.placeholderItemModel,
    this.shrinkWrap = false,
    this.disableScrolling = false,
    this.scrollPhysics,
    this.padding,
    this.itemShowLimit,
    this.errorBuilder,
    this.emptyStateRetryBuilder,
    this.customLoader,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyBaseView: shimmerEffect is enabled but placeholderItemModel is null.',
        );

  /// Must be implemented by child classes to define how items are laid out.
  ///
  /// Examples:
  /// - `ListView.builder` in [`PagyListView`]
  /// - `GridView.builder` in [`PagyGridView`]
  Widget buildLayout(
    BuildContext context,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilderFn,
  );

  /// Builds the shimmer placeholder layout.
  ///
  /// Can be overridden by child classes for custom shimmer appearance.
  Widget buildShimmer(BuildContext context) {
    return PagyShimmer<T>(
      count: placeholderItemCount,
      itemBuilder: (c, _) => itemBuilder(c, placeholderItemModel as T),
      layoutBuilder: (childBuilder) => buildLayout(
        context,
        placeholderItemCount,
        childBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagyBuilder<T>(
      controller: controller,
      itemBuilder: itemBuilder,
      shimmerEffect: shimmerEffect,
      placeholderItemCount: placeholderItemCount,
      placeholderItemModel: placeholderItemModel,
      customLoader: customLoader,
      shrinkWrap: shrinkWrap,
      disableScrolling: disableScrolling,
      scrollPhysics: scrollPhysics,
      padding: padding,
      itemShowLimit: itemShowLimit,
      errorBuilder: errorBuilder,
      emptyStateRetryBuilder: emptyStateRetryBuilder,
      shimmerBuilder: shimmerEffect ? buildShimmer : null,
      layoutBuilder: (ctx, state, itemCount, itemBuilderFn) {
        return buildLayout(ctx, itemCount, itemBuilderFn);
      },
    );
  }
}
