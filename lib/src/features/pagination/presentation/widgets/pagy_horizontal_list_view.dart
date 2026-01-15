import 'package:flutter/material.dart';

import '../controllers/pagy_controller.dart';
import 'pagy_base_view.dart';

/// {@template pagy_horizontal_list_view}
/// A customizable horizontal [ListView]-like widget powered by [PagyController].
///
/// `PagyHorizontalListView` automatically manages pagination states such as:
/// - **Loading**: Shows shimmer placeholders while fetching data.
/// - **Error**: Displays an error widget with retry support.
/// - **Empty**: Handles empty state gracefully with customizable UI.
/// - **Data**: Renders your paginated items as a horizontal scrollable list.
///
/// It integrates seamlessly with [PagyController] to handle
/// API-driven pagination or manual data management. This widget is
/// ideal for horizontal layouts such as:
/// - Category listings
/// - Featured products carousels
/// - Horizontal media galleries
/// - Story/highlights displays
///
/// ### Features:
/// - Shimmer placeholders while data is loading
/// - Retry handling for empty and error states
/// - Custom separators between list items
/// - Adjustable item spacing for quick styling
/// - Optional max visible items (preview mode)
/// - Scroll control with `shrinkWrap`, `disableScrolling`, and `scrollPhysics`
/// - Fully customizable loaders, error, and empty state widgets
/// - **Dynamic height support** using Row-based layout
///
/// ### Example (Fixed Height):
/// ```dart
/// SizedBox(
///   height: 200,
///   child: PagyHorizontalListView<Category>(
///     controller: categoryController,
///     itemBuilderWithIndex: (context, category, index) {
///       return CategoryCard(category: category, rank: index + 1);
///     },
///     itemSpacing: 12,
///     shimmerEffect: true,
///     placeholderItemModel: Category.empty(),
///   ),
/// )
/// ```
///
/// ### Example (Dynamic Height):
/// ```dart
/// PagyHorizontalListView<Category>(
///   controller: categoryController,
///   useDynamicHeight: true, // Uses Row + SingleChildScrollView
///   itemBuilderWithIndex: (context, category, index) {
///     return CategoryCard(category: category);
///   },
///   itemSpacing: 12,
/// )
/// ```
///
/// **Note:** When [useDynamicHeight] is `false` (default), this is a horizontal
/// scrolling list that typically needs to be wrapped in a [SizedBox] or
/// [Container] with a fixed height. When [useDynamicHeight] is `true`, the
/// widget uses a [Row] inside a [SingleChildScrollView], allowing the height
/// to be determined by the tallest child (intrinsic sizing).
/// {@endtemplate}
class PagyHorizontalListView<T> extends PagyBaseView<T> {
  /// Space between list items horizontally.
  ///
  /// Defaults to `0`. To add spacing without a custom [separatorBuilder],
  /// simply set this value to the desired width.
  final double itemSpacing;

  /// A custom builder for separators between items.
  ///
  /// If not provided, a [SizedBox] with width equal to [itemSpacing]
  /// will be used as the default separator.
  ///
  /// Example:
  /// ```dart
  /// separatorBuilder: (_, __) => SizedBox(
  ///   width: 1,
  ///   child: Container(color: Colors.grey),
  /// ),
  /// ```
  final Widget Function(BuildContext, int)? separatorBuilder;

  /// Whether to use dynamic height sizing instead of fixed height.
  ///
  /// When `true`, the widget uses a [Row] inside a [SingleChildScrollView]
  /// instead of [ListView.separated]. This allows the height to be determined
  /// by the content (intrinsic sizing), making it suitable for use in:
  /// - [Column] widgets
  /// - [ListView] with unbounded height
  /// - Any layout where fixed height is not desired
  ///
  /// **Important:** When `useDynamicHeight` is `true`:
  /// - The widget will take the height of its tallest child
  /// - You don't need to wrap it in a [SizedBox] with fixed height
  /// - Performance may be slightly lower for very large lists since all
  ///   items are built upfront (not lazily)
  ///
  /// Defaults to `false` (uses [ListView.separated] with lazy loading).
  ///
  /// Example:
  /// ```dart
  /// Column(
  ///   children: [
  ///     Text('Featured Categories'),
  ///     PagyHorizontalListView<Category>(
  ///       controller: categoryController,
  ///       useDynamicHeight: true,
  ///       itemBuilderWithIndex: (context, category, index) {
  ///         return CategoryCard(category: category);
  ///       },
  ///     ),
  ///   ],
  /// )
  /// ```
  final bool useDynamicHeight;

  /// Creates a [PagyHorizontalListView] instance.
  ///
  /// Requires a [PagyController] and an [itemBuilder].
  ///
  /// - If [shimmerEffect] is enabled, you **must** provide a
  ///   [placeholderItemModel].
  /// - Supports custom states via [errorBuilder], [emptyStateBuilder],
  ///   and [customLoader].
  /// - Use [emptyMessage] and [emptyIcon] to customize empty state.
  /// - Set [useDynamicHeight] to `true` for intrinsic height sizing.
  const PagyHorizontalListView({
    super.key,
    required super.controller,
    @Deprecated(
        'Use itemBuilderWithIndex instead for access to index. Will be removed in v2.0.0')
    super.itemBuilder,
    super.itemBuilderWithIndex,
    this.itemSpacing = 0,
    this.separatorBuilder,
    this.useDynamicHeight = false,
    super.shimmerEffect = false,
    super.placeholderItemCount = 1,
    super.placeholderItemModel,
    super.shrinkWrap = false,
    super.disableScrolling = false,
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
    super.customLoader,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyHorizontalListView: shimmerEffect is true but placeholderItemModel is null. '
          'Provide a placeholderItemModel when enabling shimmer placeholders.',
        );

  /// Override to specify horizontal scroll direction
  @override
  Axis get scrollDirection => Axis.horizontal;

  /// Builds the core layout of the horizontal list when data is available.
  ///
  /// When [useDynamicHeight] is `false` (default):
  /// Uses [ListView.separated] with horizontal scroll direction to render
  /// items with either a custom [separatorBuilder] or spacing defined
  /// by [itemSpacing]. This requires a fixed height constraint.
  ///
  /// When [useDynamicHeight] is `true`:
  /// Uses a [Row] inside [SingleChildScrollView] to render items with
  /// [List.generate], allowing intrinsic height sizing. The height will
  /// be determined by the tallest child widget.
  ///
  /// **Auto-fallback:** If placed in an unbounded height context without
  /// [useDynamicHeight] set to `true`, automatically uses the dynamic
  /// height layout to prevent viewport errors.
  @override
  Widget buildLayout(
    BuildContext context,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilderFn,
  ) {
    // If user explicitly wants dynamic height, use it directly
    if (useDynamicHeight) {
      return _buildDynamicHeightLayout(context, itemCount, itemBuilderFn);
    }

    // Otherwise, check constraints and auto-fallback if unbounded height
    return LayoutBuilder(
      builder: (context, constraints) {
        // If height is unbounded (infinite), automatically use dynamic height
        // layout to prevent "Horizontal viewport was given unbounded height" error
        if (constraints.maxHeight == double.infinity) {
          return _buildDynamicHeightLayout(context, itemCount, itemBuilderFn);
        }
        // Height is bounded, safe to use ListView
        return _buildListViewLayout(context, itemCount, itemBuilderFn);
      },
    );
  }

  /// Builds the standard ListView.separated layout (requires fixed height)
  Widget _buildListViewLayout(
    BuildContext context,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilderFn,
  ) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      separatorBuilder:
          separatorBuilder ?? (_, __) => SizedBox(width: itemSpacing),
      shrinkWrap: shrinkWrap,
      physics: disableScrolling
          ? const NeverScrollableScrollPhysics()
          : scrollPhysics,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilderFn,
    );
  }

  /// Builds the Row-based layout with dynamic/intrinsic height support
  Widget _buildDynamicHeightLayout(
    BuildContext context,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilderFn,
  ) {
    final children = List<Widget>.generate(itemCount, (index) {
      final item = itemBuilderFn(context, index);
      // Add separator after each item except the last
      if (index < itemCount - 1) {
        final separator = separatorBuilder?.call(context, index) ??
            SizedBox(width: itemSpacing);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [item, separator],
        );
      }
      return item;
    });

    Widget rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    // Apply padding if specified
    if (padding != null) {
      rowContent = Padding(
        padding: padding!,
        child: rowContent,
      );
    }

    // Wrap in SingleChildScrollView for horizontal scrolling (unless disabled)
    if (disableScrolling) {
      return rowContent;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: scrollPhysics,
      child: rowContent,
    );
  }
}
