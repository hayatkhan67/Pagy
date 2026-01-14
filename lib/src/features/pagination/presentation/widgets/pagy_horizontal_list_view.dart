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
///
/// ### Example:
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
/// **Note:** Since this is a horizontal scrolling list, you typically
/// need to wrap it in a [SizedBox] or [Container] with a fixed height.
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

  /// Creates a [PagyHorizontalListView] instance.
  ///
  /// Requires a [PagyController] and an [itemBuilder].
  ///
  /// - If [shimmerEffect] is enabled, you **must** provide a
  ///   [placeholderItemModel].
  /// - Supports custom states via [errorBuilder], [emptyStateBuilder],
  ///   and [customLoader].
  /// - Use [emptyMessage] and [emptyIcon] to customize empty state.
  const PagyHorizontalListView({
    super.key,
    required super.controller,
    @Deprecated(
        'Use itemBuilderWithIndex instead for access to index. Will be removed in v2.0.0')
    super.itemBuilder,
    super.itemBuilderWithIndex,
    this.itemSpacing = 0,
    this.separatorBuilder,
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
  /// Uses [ListView.separated] with horizontal scroll direction to render
  /// items with either a custom [separatorBuilder] or spacing defined
  /// by [itemSpacing].
  @override
  Widget buildLayout(
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
}
