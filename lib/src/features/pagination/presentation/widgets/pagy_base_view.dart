import 'package:flutter/material.dart';

import '../../../../../pagy.dart';
import 'common/pagy_builder.dart';
import 'common/pagy_shimmer.dart';

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
  final Widget Function(PagyError error, VoidCallback onRetry)? errorBuilder;

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

  /// Whether to wrap the list/grid with a refresh indicator.
  ///
  /// Defaults to `true`.
  final bool enableRefreshIndicator;

  /// Custom refresh handler for pull-to-refresh.
  ///
  /// If provided, it runs before the default Pagy refresh.
  final RefreshCallback? onRefresh;

  /// Whether the refresh action should also trigger Pagy reload.
  ///
  /// Defaults to `true`. Set to `false` to fully override refresh.
  final bool refreshTriggersPagyLoad;

  /// Custom builder for refresh indicator wrapping.
  ///
  /// Use this to provide a custom refresh widget.
  final Widget Function(BuildContext, Widget, RefreshCallback)?
      refreshIndicatorBuilder;

  /// Custom loader widget shown during pagination.
  final Widget? customLoader;

  /// Custom shimmer widget shown during initial loading.
  ///
  /// When provided, this overrides the default skeleton shimmer and does not
  /// require [placeholderItemModel].
  final Widget? customShimmer;

  /// Custom builder for shimmer loading state.
  ///
  /// When provided, this overrides the default skeleton shimmer and does not
  /// require [placeholderItemModel].
  final ShimmerBuilder? shimmerBuilder;

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
    this.enableRefreshIndicator = true,
    this.onRefresh,
    this.refreshTriggersPagyLoad = true,
    this.refreshIndicatorBuilder,
    this.customLoader,
    this.customShimmer,
    this.shimmerBuilder,
  })  : assert(
          itemBuilder != null || itemBuilderWithIndex != null,
          'Either itemBuilder or itemBuilderWithIndex must be provided',
        ),
        assert(
          placeholderItemModel != null ||
              !shimmerEffect ||
              customShimmer != null ||
              shimmerBuilder != null,
          'PagyBaseView: shimmerEffect is enabled but placeholderItemModel is null. '
          'Provide a placeholderItemModel, customShimmer, or shimmerBuilder.',
        );

  /// The scroll direction of the view.
  ///
  /// Subclasses can override this to specify horizontal scrolling.
  /// Defaults to [Axis.vertical].
  Axis get scrollDirection => Axis.vertical;

  /// Whether the inline loader/error footer should be delivered to
  /// [buildLayout] via its `footer` argument rather than rendered as the last
  /// item.
  ///
  /// Multi-column layouts override this to `true` so the footer can span the
  /// full width instead of occupying a single cell.
  bool get separateFooter => false;

  /// Must be implemented by child classes to define how items are laid out.
  ///
  /// [footer] is non-null only when [separateFooter] is `true` and there is an
  /// inline loader or error to show below the items.
  ///
  /// Examples:
  /// - `ListView.builder` in [PagyListView]
  /// - `GridView.builder` in [PagyGridView]
  Widget buildLayout(
    BuildContext context,
    int itemCount,
    Widget Function(BuildContext, int) itemBuilderFn, {
    Widget? footer,
  });

  /// Builds the shimmer placeholder layout.
  ///
  /// Can be overridden by child classes for custom shimmer appearance.
  Widget buildShimmer(BuildContext context) {
    final override = resolveShimmerOverride(context);
    if (override != null) return override;
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

  /// The loading widget to show instead of the skeleton built from
  /// [placeholderItemModel], or `null` to build that skeleton.
  ///
  /// Precedence: [customShimmer] > [shimmerBuilder] > skeleton from
  /// [placeholderItemModel].
  @protected
  Widget? resolveShimmerOverride(BuildContext context) {
    if (customShimmer != null) return customShimmer;
    if (shimmerBuilder != null) return shimmerBuilder!(context);
    return null;
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
    final effectiveShimmer =
        shimmerEffect || customShimmer != null || shimmerBuilder != null;
    return PagyBuilder<T>(
      controller: controller,
      itemBuilder: _effectiveItemBuilder,
      shimmerEffect: effectiveShimmer,
      placeholderItemCount: placeholderItemCount,
      placeholderItemModel: placeholderItemModel,
      customLoader: customLoader,
      customShimmer: customShimmer,
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
      enableRefreshIndicator: enableRefreshIndicator,
      onRefresh: onRefresh,
      refreshTriggersPagyLoad: refreshTriggersPagyLoad,
      refreshIndicatorBuilder: refreshIndicatorBuilder,
      scrollDirection: scrollDirection,
      separateFooter: separateFooter,
      shimmerBuilder: effectiveShimmer ? buildShimmer : null,
      layoutBuilder: (ctx, state, itemCount, itemBuilderFn, footer) {
        return buildLayout(ctx, itemCount, itemBuilderFn, footer: footer);
      },
    );
  }
}
