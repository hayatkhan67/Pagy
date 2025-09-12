import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../controllers/pagy_controller.dart';
import 'pagy_base_view.dart';

/// {@template pagy_grid_view}
/// A customizable [GridView]-like widget powered by [PagyController].
///
/// `PagyGridView` automatically manages pagination states:
/// - **Loading** (with shimmer placeholders)
/// - **Error** (with retry support)
/// - **Empty** (with retry builder)
/// - **Data** (grid of items)
///
/// It builds a staggered-style grid using [MasonryGridView.builder],
/// making it ideal for:
/// - Product listings
/// - Social media feeds
/// - Image/photo galleries
///
/// ### Features
/// - Automatic pagination via [PagyController]
/// - Shimmer placeholders for smooth loading
/// - Built-in retry for empty/error states
/// - Custom loader, error, and empty widgets
/// - Flexible grid configuration:
///   - `crossAxisCount` for column count
///   - `crossAxisSpacing` & `mainAxisSpacing` for spacing
/// - Scroll control:
///   - `shrinkWrap`
///   - `disableScrolling`
///   - `scrollPhysics`
/// - Limit items shown via `itemShowLimit` (useful for previews)
///
/// ### Example
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
  ///
  /// Defaults to `2`.
  final int crossAxisCount;

  /// Horizontal spacing between items.
  ///
  /// Defaults to `9.0`.
  final double crossAxisSpacing;

  /// Vertical spacing between items.
  ///
  /// Defaults to `10.0`.
  final double mainAxisSpacing;

  /// Creates a new [PagyGridView].
  ///
  /// Requires:
  /// - a [PagyController] to manage pagination
  /// - an [itemBuilder] to render each grid item
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
