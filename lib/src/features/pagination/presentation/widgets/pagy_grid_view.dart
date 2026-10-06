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
/// - **Empty** (with retry builder or pull-to-refresh)
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
/// - Customizable empty message and icon via [emptyMessage] and [emptyIcon]
/// - Pull-to-refresh on empty state via [enableRefreshOnEmpty]
/// - Flexible grid configuration:
///   - `crossAxisCount` for column count
///   - `crossAxisSpacing` & `mainAxisSpacing` for spacing
///   - `gridDelegate` for the full masonry layout surface (e.g. responsive
///     columns via `SliverSimpleGridDelegateWithMaxCrossAxisExtent`)
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
///   itemBuilderWithIndex: (context, product, index) {
///     return ProductCard(
///       product: product,
///       rank: index + 1,
///     );
///   },
///   crossAxisCount: 2,
///   crossAxisSpacing: 8,
///   mainAxisSpacing: 12,
///   emptyMessage: 'No products found',
///   emptyIcon: Icons.shopping_bag_outlined,
///   enableRefreshOnEmpty: true,
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

  /// Full control over how children are distributed across the cross axis.
  ///
  /// Leave this `null` (the default) to lay out [crossAxisCount] equal columns.
  /// Provide a delegate to reach the rest of the masonry layout options —
  /// [crossAxisCount] is then ignored, while [crossAxisSpacing] and
  /// [mainAxisSpacing] still apply.
  ///
  /// Responsive columns sized by available width:
  /// ```dart
  /// PagyGridView<Photo>(
  ///   controller: controller,
  ///   gridDelegate: const SliverSimpleGridDelegateWithMaxCrossAxisExtent(
  ///     maxCrossAxisExtent: 180,
  ///   ),
  ///   itemBuilderWithIndex: (context, photo, i) => PhotoTile(photo: photo),
  /// )
  /// ```
  ///
  /// Both [SliverSimpleGridDelegateWithFixedCrossAxisCount] and
  /// [SliverSimpleGridDelegateWithMaxCrossAxisExtent] are re-exported by
  /// `package:pagy/pagy.dart`, so you don't need to depend on
  /// `flutter_staggered_grid_view` directly. Custom [SliverSimpleGridDelegate]
  /// subclasses work too.
  final SliverSimpleGridDelegate? gridDelegate;

  /// Creates a new [PagyGridView].
  ///
  /// Requires:
  /// - a [PagyController] to manage pagination
  /// - an [itemBuilder] to render each grid item
  const PagyGridView({
    super.key,
    required super.controller,
    @Deprecated(
        'Use itemBuilderWithIndex instead for access to index. Will be removed in v2.0.0')
    super.itemBuilder,
    super.itemBuilderWithIndex,
    super.shimmerEffect,
    super.placeholderItemCount,
    super.placeholderItemModel,
    super.shrinkWrap,
    super.disableScrolling,
    super.scrollPhysics,
    super.padding,
    super.itemShowLimit,
    super.errorBuilder,
    @Deprecated('Use emptyStateBuilder instead') super.emptyStateRetryBuilder,
    super.emptyStateBuilder,
    super.emptyMessage,
    super.emptyIcon,
    super.showEmptyRetryButton,
    super.enableRefreshOnEmpty,
    super.enableRefreshIndicator,
    super.onRefresh,
    super.refreshTriggersPagyLoad,
    super.refreshIndicatorBuilder,
    super.customLoader,
    super.customShimmer,
    super.shimmerBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 9,
    this.mainAxisSpacing = 10,
    this.gridDelegate,
  }) : assert(
          placeholderItemModel != null ||
              !shimmerEffect ||
              customShimmer != null ||
              shimmerBuilder != null,
          'PagyGridView: shimmerEffect is true but placeholderItemModel is null. '
          'Provide a placeholderItemModel, customShimmer, or shimmerBuilder when enabling shimmer placeholders.',
        );

  /// The grid renders its footer as a full-width sliver below the columns.
  @override
  bool get separateFooter => true;

  /// The effective cross-axis layout: an explicit [gridDelegate] if given,
  /// otherwise [crossAxisCount] equal columns.
  SliverSimpleGridDelegate get _effectiveGridDelegate =>
      gridDelegate ??
      SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
      );

  EdgeInsetsGeometry get _effectivePadding =>
      padding ??
      const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16);

  /// The shimmer has no paging footer, so it keeps the plain [MasonryGridView]
  /// rather than the sliver layout [buildLayout] uses for real data.
  @override
  Widget buildShimmerLayout(
    BuildContext context,
    Widget Function(BuildContext, int) childBuilder,
  ) {
    return MasonryGridView.builder(
      shrinkWrap: shrinkWrap,
      physics: disableScrolling
          ? const NeverScrollableScrollPhysics()
          : scrollPhysics,
      padding: _effectivePadding,
      gridDelegate: _effectiveGridDelegate,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      itemCount: placeholderItemCount,
      itemBuilder: childBuilder,
    );
  }

  @override
  Widget buildLayout(
    BuildContext context,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilderFn, {
    Widget? footer,
  }) {
    return CustomScrollView(
      shrinkWrap: shrinkWrap,
      physics: disableScrolling
          ? const NeverScrollableScrollPhysics()
          : scrollPhysics,
      slivers: [
        SliverPadding(
          padding: _effectivePadding,
          sliver: SliverMasonryGrid(
            gridDelegate: _effectiveGridDelegate,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            delegate: SliverChildBuilderDelegate(
              itemBuilderFn,
              childCount: itemCount,
            ),
          ),
        ),
        if (footer != null) SliverToBoxAdapter(child: footer),
      ],
    );
  }
}
