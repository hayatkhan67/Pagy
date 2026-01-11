import 'package:flutter/material.dart';

import '../controllers/pagy_controller.dart';
import 'common/pagy_builder.dart';
import 'common/pagy_shimmer.dart';
import 'pagy_grid_view.dart';
import 'pagy_list_view.dart';

/// Base widget for Pagy-powered list/grid views.
///
/// This widget provides the **common pagination boilerplate** used by
/// [PagyListView] and [PagyGridView]. It handles:
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
  ///
  /// **Deprecated:** Use [itemBuilderWithIndex] instead to access the item's index.
  @Deprecated(
      'Use itemBuilderWithIndex instead for access to index. Will be removed in v2.0.0')
  final Widget Function(BuildContext context, T item)? itemBuilder;

  /// Function that builds each item with access to its index.
  ///
  /// Example:
  /// ```dart
  /// itemBuilderWithIndex: (context, item, index) {
  ///   return ListTile(
  ///     leading: Text('#${index + 1}'),
  ///     title: Text(item.name),
  ///   );
  /// }
  /// ```
  final Widget Function(BuildContext context, T item, int index)?
      itemBuilderWithIndex;

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
  ///
  /// **Deprecated:** Use [emptyStateBuilder] instead for better readability
  /// with named `retry` parameter.
  @Deprecated('Use emptyStateBuilder instead. Will be removed in v2.0.0')
  final Widget Function(VoidCallback)? emptyStateRetryBuilder;

  /// Empty state builder with named retry parameter.
  ///
  /// Example:
  /// ```dart
  /// emptyStateBuilder: ({required retry}) => MyEmptyWidget(onRefresh: retry),
  /// ```
  final PagyEmptyStateBuilder? emptyStateBuilder;

  /// Custom message shown in empty state.
  ///
  /// Overrides the default "No data available" message.
  final String? emptyMessage;

  /// Custom icon shown in empty state.
  final IconData? emptyIcon;

  /// Whether to show the retry button in empty state.
  ///
  /// Defaults to `true`.
  final bool showEmptyRetryButton;

  /// Whether to enable pull-to-refresh on empty state.
  ///
  /// Defaults to `false`.
  final bool enableRefreshOnEmpty;

  /// Custom loader widget shown during pagination.
  final Widget? customLoader;

  /// Creates a base Pagy-powered view.
  ///
  /// - [controller] is required to manage pagination.
  /// - Either [itemBuilder] (deprecated) or [itemBuilderWithIndex] is required.
  /// - [shimmerEffect] requires [placeholderItemModel].
  const PagyBaseView({
    super.key,
    required this.controller,
    @Deprecated('Use itemBuilderWithIndex instead') this.itemBuilder,
    this.itemBuilderWithIndex,
    this.shimmerEffect = false,
    this.placeholderItemCount = 1,
    this.placeholderItemModel,
    this.shrinkWrap = false,
    this.disableScrolling = false,
    this.scrollPhysics,
    this.padding,
    this.itemShowLimit,
    this.errorBuilder,
    @Deprecated('Use emptyStateBuilder instead') this.emptyStateRetryBuilder,
    this.emptyStateBuilder,
    this.emptyMessage,
    this.emptyIcon,
    this.showEmptyRetryButton = true,
    this.enableRefreshOnEmpty = false,
    this.customLoader,
  })  : assert(
          itemBuilder != null || itemBuilderWithIndex != null,
          'Either itemBuilder or itemBuilderWithIndex must be provided',
        ),
        assert(
          placeholderItemModel != null || !shimmerEffect,
          'PagyBaseView: shimmerEffect is enabled but placeholderItemModel is null.',
        );

  /// Must be implemented by child classes to define how items are laid out.
  ///
  /// Examples:
  /// - `ListView.builder` in [PagyListView]
  /// - `GridView.builder` in [PagyGridView]
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
      itemBuilder: (c, index) {
        // Use effective item builder
        if (itemBuilderWithIndex != null) {
          return itemBuilderWithIndex!(c, placeholderItemModel as T, index);
        }
        // ignore: deprecated_member_use_from_same_package
        return itemBuilder!(c, placeholderItemModel as T);
      },
      layoutBuilder: (childBuilder) => buildLayout(
        context,
        placeholderItemCount,
        childBuilder,
      ),
    );
  }

  /// Gets the effective item builder that works with both old and new signatures
  Widget Function(BuildContext, T, int) get _effectiveItemBuilder {
    if (itemBuilderWithIndex != null) {
      return itemBuilderWithIndex!;
    }
    // Wrap old itemBuilder to match new signature
    // ignore: deprecated_member_use_from_same_package
    return (context, item, index) => itemBuilder!(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return PagyBuilder<T>(
      controller: controller,
      itemBuilder: _effectiveItemBuilder,
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
      // ignore: deprecated_member_use_from_same_package
      emptyStateRetryBuilder: emptyStateRetryBuilder,
      emptyStateBuilder: emptyStateBuilder,
      emptyMessage: emptyMessage,
      emptyIcon: emptyIcon,
      showEmptyRetryButton: showEmptyRetryButton,
      enableRefreshOnEmpty: enableRefreshOnEmpty,
      shimmerBuilder: shimmerEffect ? buildShimmer : null,
      layoutBuilder: (ctx, state, itemCount, itemBuilderFn) {
        return buildLayout(ctx, itemCount, itemBuilderFn);
      },
    );
  }
}
