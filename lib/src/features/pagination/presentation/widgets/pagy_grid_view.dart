import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'pagy_base_view.dart';

/// {@template pagy_grid_view}
/// A customizable [GridView]-like widget powered by [PagyController].
///
/// `PagyGridView` automatically handles pagination states (loading, error,
/// empty, data) while providing deep customization for UI and behavior.
///
/// It builds a staggered-style grid using [MasonryGridView.builder],
/// making it ideal for feed-like layouts such as product listings,
/// social media grids, or photo galleries.
///
/// ### Features:
/// - Automatic pagination using [PagyController]
/// - Shimmer placeholders for loading state
/// - Error & empty state handling with retry support
/// - Custom loader and error widgets
/// - Grid configuration with flexible `crossAxisCount`, spacing, and padding
/// - Scroll control with `shrinkWrap`, `disableScrolling`, and `scrollPhysics`
/// - Optional item count limit for previews
///
/// ### Example:
/// ```dart
/// PagyGridView<Product>(
///   controller: pagyController,
///   itemBuilder: (context, index) {
///     final product = pagyController.items[index];
///     return ProductCard(product: product);
///   },
///   crossAxisCount: 2,
///   crossAxisSpacing: 8,
///   mainAxisSpacing: 12,
/// )
/// ```
/// {@endtemplate}
class PagyGridView<T> extends PagyBaseView<T> {
  /// Number of columns in the grid.
  final int crossAxisCount;

  /// Spacing between items on the cross axis (horizontal).
  final double crossAxisSpacing;

  /// Spacing between items on the main axis (vertical).
  final double mainAxisSpacing;

  /// Creates a new [PagyGridView] instance.
  ///
  /// Requires a [PagyController] and an [itemBuilder].
  const PagyGridView({
    super.key,
    required super.controller,
    required super.itemBuilder,
    super.shimmerEffect,
    super.placeholderItemCount,
    super.placeholderItemModel,
    super.shrinkWrap,
    super.disableScrolling,
    super.scrollPhysics,
    super.padding,
    super.itemShowLimit,
    super.errorBuilder,
    super.emptyStateRetryBuilder,
    super.customLoader,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 9,
    this.mainAxisSpacing = 10,
  });

  @override
  Widget buildLayout(
    BuildContext context,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilderFn,
  ) {
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
  }
}
