import 'package:flutter/material.dart';

import '../controllers/pagy_controller.dart';
import 'pagy_base_view.dart';

/// {@template pagy_list_view}
/// A customizable [ListView]-like widget powered by [PagyController].
///
/// `PagyListView` automatically manages pagination states such as:
/// - **Loading**: Shows shimmer placeholders while fetching data.
/// - **Error**: Displays an error widget with retry support.
/// - **Empty**: Handles empty state gracefully with customizable UI.
/// - **Data**: Renders your paginated items as a scrollable list.
///
/// It integrates seamlessly with [PagyController] to handle
/// API-driven pagination or manual data management. This widget is
/// ideal for feed-like layouts such as message lists, comments,
/// or product catalogs.
///
/// ### Features:
/// - Shimmer placeholders while data is loading
/// - Retry handling for empty and error states
/// - Custom separators between list items
/// - Adjustable item spacing for quick styling
/// - Optional max visible items (preview mode)
/// - Scroll control with `shrinkWrap`, `disableScrolling`, and `scrollPhysics`
/// - Fully customizable loaders, error, and empty state widgets
/// - Pull-to-refresh on empty state via `enableRefreshOnEmpty`
///
/// ### Example:
/// ```dart
/// PagyListView<User>(
///   controller: userController,
///   itemBuilderWithIndex: (context, user, index) {
///     return ListTile(
///       leading: CircleAvatar(child: Text('#${index + 1}')),
///       title: Text(user.name),
///     );
///   },
///   itemSpacing: 8,
///   shimmerEffect: true,
///   placeholderItemModel: User.empty(),
///   emptyMessage: 'No users found',
///   enableRefreshOnEmpty: true,
/// )
/// ```
/// {@endtemplate}
class PagyListView<T> extends PagyBaseView<T> {
  /// Space between list items in the list.
  ///
  /// Defaults to `0`. To add spacing without a custom [separatorBuilder],
  /// simply set this value to the desired height.
  final double itemSpacing;

  /// A custom builder for separators between items.
  ///
  /// If not provided, a [SizedBox] with height equal to [itemSpacing]
  /// will be used as the default separator.
  ///
  /// Example:
  /// ```dart
  /// separatorBuilder: (_, __) => Divider(color: Colors.grey),
  /// ```
  final Widget Function(BuildContext, int)? separatorBuilder;

  /// Creates a [PagyListView] instance.
  ///
  /// Requires a [PagyController] and an [itemBuilder].
  ///
  /// - If [shimmerEffect] is enabled, you **must** provide a
  ///   [placeholderItemModel].
  /// - Supports custom states via [errorBuilder], [emptyStateBuilder],
  ///   and [customLoader].
  /// - Use [emptyMessage] and [emptyIcon] to customize empty state.
  /// - Set [enableRefreshOnEmpty] to allow pull-to-refresh when empty.
  const PagyListView({
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
    super.enableRefreshIndicator,
    super.onRefresh,
    super.refreshTriggersPagyLoad,
    super.refreshIndicatorBuilder,
    super.customLoader,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyListView: shimmerEffect is true but placeholderItemModel is null. '
          'Provide a placeholderItemModel when enabling shimmer placeholders.',
        );

  /// Builds the core layout of the list when data is available.
  ///
  /// Uses [ListView.separated] to render items with either a custom
  /// [separatorBuilder] or spacing defined by [itemSpacing].
  @override
  Widget buildLayout(
    BuildContext context,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilderFn,
  ) {
    return ListView.separated(
      separatorBuilder:
          separatorBuilder ?? (_, __) => SizedBox(height: itemSpacing),
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
