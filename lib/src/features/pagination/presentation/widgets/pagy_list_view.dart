import 'package:flutter/material.dart';

import '../controllers/pagy_controller.dart';
import 'common/pagy_shimmer.dart';
import 'pagy_base_view.dart';

/// {@template pagy_list_view}
/// A customizable [ListView]-like widget powered by [PagyController].
///
/// `PagyListView` automatically manages pagination states:
/// loading, error, empty, and data. It integrates seamlessly with
/// your [PagyController] to handle API calls or provide deep manual
/// control when needed.
///
/// ### Features:
/// - Shimmer placeholders while data is loading
/// - Retry handling for empty and error states
/// - Custom separators between list items
/// - Adjustable item spacing
/// - Optional max visible items (preview mode)
/// - Scroll control with `shrinkWrap`, `disableScrolling`, and `scrollPhysics`
/// - Fully customizable loaders, error, and empty state widgets
///
/// ### Example:
/// ```dart
/// PagyListView<User>(
///   controller: userController,
///   itemBuilder: (context, index) {
///     final user = userController.items[index];
///     return UserTile(user: user);
///   },
///   itemSpacing: 8,
///   shimmerEffect: true,
///   placeholderItemModel: User.empty(),
/// )
/// ```
/// {@endtemplate}
class PagyListView<T> extends PagyBaseView<T> {
  /// Space between list items.
  final double itemSpacing;

  /// Custom separator builder between items.
  final Widget Function(BuildContext, int)? separatorBuilder;

  /// Creates a [PagyListView] instance.
  ///
  /// Requires a [PagyController] and an [itemBuilder].
  /// If [shimmerEffect] is enabled, you must provide a [placeholderItemModel].
  const PagyListView({
    super.key,
    required super.controller,
    required super.itemBuilder,
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
    super.emptyStateRetryBuilder,
    super.customLoader,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyListView: shimmerEffect is true but placeholderItemModel is null. '
          'Provide a placeholderItemModel when enabling shimmer placeholders.',
        );

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

  @override
  Widget buildShimmer(BuildContext context) {
    return PagyShimmer<T>(
      count: placeholderItemCount,
      itemBuilder: (c, _) => itemBuilder(c, placeholderItemModel as T),
      layoutBuilder: (childBuilder) => ListView.separated(
        separatorBuilder:
            separatorBuilder ?? (_, __) => SizedBox(height: itemSpacing),
        shrinkWrap: shrinkWrap,
        physics: disableScrolling
            ? const NeverScrollableScrollPhysics()
            : scrollPhysics,
        padding: padding,
        itemCount: placeholderItemCount,
        itemBuilder: childBuilder,
      ),
    );
  }
}
