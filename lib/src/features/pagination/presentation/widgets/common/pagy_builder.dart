import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../../../internal_imports.dart';
import '../../../../../../pagy.dart';
import '../../../../../core/utils/pagy_helpers.dart';

/// Signature for layout builder callback used in [PagyBuilder].
///
/// Provides the current [PagyState], total [itemCount], and an
/// [itemBuilder] function that can be passed to list/grid builders.
typedef LayoutBuilderCallback<T> = Widget Function(
  BuildContext context,
  PagyState<T> state,
  int itemCount,
  Widget Function(BuildContext, int) itemBuilder,
);

/// Signature for building a shimmer widget.
/// Used when shimmer placeholders are enabled.
typedef ShimmerBuilder = Widget Function(BuildContext context);

/// Signature for building an empty state widget.
///
/// The [retry] callback triggers a data reload when invoked.
/// Using a named parameter improves readability at call sites:
///
/// ```dart
/// emptyStateBuilder: ({required retry}) => MyEmptyWidget(onRefresh: retry),
/// ```
typedef PagyEmptyStateBuilder = Widget Function({required VoidCallback retry});

/// Core widget that powers [PagyBaseView], [PagyListView], and [PagyGridView].
///
/// This builder is responsible for:
/// - Listening to [PagyController] state changes
/// - Rendering shimmer placeholders during loading
/// - Handling full-screen error & empty states
/// - Rendering inline error/loader during pagination
/// - Integrating pull-to-refresh and infinite scroll
class PagyBuilder<T> extends StatelessWidget {
  /// Pagination controller that manages API calls and state.
  final PagyController<T>? controller;

  /// Function that builds the layout (List/Grid etc.).
  final LayoutBuilderCallback<T> layoutBuilder;

  /// Builder for individual list/grid items.
  final Widget Function(BuildContext, T item, int index) itemBuilder;

  /// Optional shimmer builder for custom shimmer layouts.
  final ShimmerBuilder? shimmerBuilder;

  /// Whether shimmer placeholders should be shown while loading.
  final bool shimmerEffect;

  /// Marks whether this builder is used inside a GridView.
  final bool isGridView;

  /// Number of columns in GridView (ignored for ListView).
  final int crossAxisCount;

  /// Horizontal spacing between grid items.
  final double crossAxisSpacing;

  /// Vertical spacing between grid items.
  final double mainAxisSpacing;

  /// Gap between list items.
  final double itemsGap;

  /// Number of shimmer items to show when loading.
  final int placeholderItemCount;

  /// Placeholder model for shimmer item rendering.
  final T? placeholderItemModel;

  /// Optional separator builder for ListView.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Custom loader widget for pagination.
  final Widget? customLoader;

  /// Limit number of visible items (useful for previews).
  final int? itemShowLimit;

  /// Whether the list/grid should shrink-wrap its content.
  final bool shrinkWrap;

  /// Whether to completely disable scrolling.
  final bool disableScrolling;

  /// Custom scroll physics for list/grid.
  final ScrollPhysics? scrollPhysics;

  /// Padding applied to the list/grid.
  final EdgeInsetsGeometry? padding;

  /// Custom error widget builder for displaying errors.
  final Widget Function(PagyError error, VoidCallback onRetry)?
      errorBuilder;

  /// Custom empty state widget builder with retry support.
  ///
  /// **Deprecated:** Use [emptyStateBuilder] instead for better readability
  /// with named `retry` parameter.
  @Deprecated('Use emptyStateBuilder instead. Will be removed in v2.0.0')
  final Widget Function(VoidCallback onRetry)? emptyStateRetryBuilder;

  /// Custom empty state widget builder with named retry parameter.
  ///
  /// Example:
  /// ```dart
  /// emptyStateBuilder: ({required retry}) => MyEmptyWidget(onRefresh: retry),
  /// ```
  final PagyEmptyStateBuilder? emptyStateBuilder;

  /// Custom message shown in empty state.
  ///
  /// Overrides the default "No data available" message.
  /// Only used when no custom [emptyStateBuilder] is provided.
  final String? emptyMessage;

  /// Custom icon shown in empty state.
  ///
  /// Only used when no custom [emptyStateBuilder] is provided.
  final IconData? emptyIcon;

  /// Whether to show the retry button in empty state.
  ///
  /// Defaults to `true`. Set to `false` if you prefer users to
  /// use pull-to-refresh instead.
  final bool showEmptyRetryButton;

  /// Whether to enable pull-to-refresh on empty state.
  ///
  /// When `true`, wraps the empty state in a [RefreshIndicator]
  /// allowing users to pull down to retry loading data.
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

  /// The scroll direction of the list/grid.
  ///
  /// Defaults to [Axis.vertical]. Set to [Axis.horizontal] for
  /// horizontal scrolling lists.
  final Axis scrollDirection;

  /// Creates a [PagyBuilder].
  ///
  /// Use this widget indirectly via [PagyListView] or [PagyGridView],
  /// unless you need advanced customization.
  const PagyBuilder({
    super.key,
    required this.controller,
    required this.layoutBuilder,
    required this.itemBuilder,
    this.shimmerBuilder,
    this.shimmerEffect = false,
    this.isGridView = false,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.itemsGap = 20,
    this.placeholderItemCount = 6,
    this.placeholderItemModel,
    this.separatorBuilder,
    this.customLoader,
    this.itemShowLimit,
    this.shrinkWrap = false,
    this.disableScrolling = false,
    this.scrollPhysics,
    this.padding,
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
    this.scrollDirection = Axis.vertical,
  }) : assert(
          placeholderItemModel != null || !shimmerEffect || shimmerBuilder != null,
        'PagyBuilder: shimmerEffect is true but placeholderItemModel is null. '
        'Provide a placeholderItemModel or a custom shimmerBuilder.',
      );

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const MissingControllerWidget(name: 'PagyBuilder');
    }

    return ValueListenableBuilder<PagyState<T>>(
      valueListenable: controller!.controller,
      builder: (context, state, _) {
        // 1️⃣ Initial shimmer or loader
        if (state.isFetching) {
          return shimmerEffect && shimmerBuilder != null
              ? shimmerBuilder!(context)
              : _loader();
        }

        // 2️⃣ Full-screen error state (when no data available)
        final errorMessage = _errorMessage(state);
        if (errorMessage != null && state.data.isEmpty) {
          return _buildFullError(errorMessage);
        }

        // 3️⃣ Empty state
        if (state.data.isEmpty) {
          return _buildEmpty();
        }

        // 4️⃣ Normal list with optional inline error/footer
        final hasInlineError = errorMessage != null && state.data.isNotEmpty;
        final baseCount = calculatePagyItemCount(state, itemShowLimit);
        final totalCount = baseCount + (hasInlineError ? 1 : 0);

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!state.isMoreFetching &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent -
                        PagyConfig().scrollOffset) {
              controller!.loadData(refresh: false);
            }
            return false;
          },
          child: _buildRefreshWrapper(
            context,
            layoutBuilder(
              context,
              state,
              totalCount,
              (ctx, index) => _buildItem(ctx, index, state),
            ),
            enabled: enableRefreshIndicator,
          ),
        );
      },
    );
  }

  /// Builds an individual item in the list/grid.
  ///
  /// Handles:
  /// - Normal item rendering
  /// - Inline error footer
  /// - Inline shimmer footer
  /// - Inline loader
  Widget _buildItem(BuildContext context, int index, PagyState<T> state) {
    if (index < state.data.length) {
      return itemBuilder(context, state.data[index], index);
    }

    final error = state.error ??
        PagyError.unknown(
          message: state.errorMessage ?? "Unknown error",
        );
    final errorMessage = _errorMessage(state);
    if (errorMessage != null && state.data.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: errorBuilder?.call(
              error,
              () => controller!.loadData(refresh: false),
            ) ??
            PagyConfig().globalErrorBuilder?.call(
                  error,
                  () => controller!.loadData(refresh: false),
                ) ??
            DefaultErrorWidget(
              errorMessage: error.message,
              onRetry: () => controller!.loadData(refresh: false),
            ),
      );
    }

    // 🔹 Inline shimmer footer (when fetching more)
    if (state.isMoreFetching && shimmerEffect) {
      return _buildShimmerItem(context);
    }

    // 🔹 Inline loader fallback
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _loader(),
    );
  }

  /// Loader widget (custom or global).
  Widget _loader() =>
      customLoader ?? PagyConfig().globalLoader ?? const DefaultPagyLoader();

  /// Builds a full-screen error state widget.
  Widget _buildFullError(String message) {
    final state = controller!.controller.value;
    final error = state.error ?? PagyError.unknown(message: message);
    return errorBuilder?.call(error, () => controller!.loadData()) ??
        PagyConfig().globalErrorBuilder?.call(
              error,
              () => controller!.loadData(),
            ) ??
        DefaultErrorWidget(
          errorMessage: message,
          onRetry: () => controller!.loadData(),
        );
  }

  /// Builds a full-screen empty state widget.
  Widget _buildEmpty() {
    final retryCallback = () => controller!.loadData();

    // Priority: emptyStateBuilder > emptyStateRetryBuilder > global > default
    Widget emptyWidget;

    if (emptyStateBuilder != null) {
      emptyWidget = emptyStateBuilder!(retry: retryCallback);
    } else if (emptyStateRetryBuilder != null) {
      // ignore: deprecated_member_use_from_same_package
      emptyWidget = emptyStateRetryBuilder!(retryCallback);
    } else if (PagyConfig().globalEmptyBuilder != null) {
      emptyWidget = PagyConfig().globalEmptyBuilder!(retryCallback);
    } else {
      emptyWidget = DefaultEmptyWidget(
        onRetry: retryCallback,
        message: emptyMessage ?? PagyConfig().globalEmptyMessage,
        icon: emptyIcon ?? PagyConfig().globalEmptyIcon,
        showRetryButton:
            showEmptyRetryButton && PagyConfig().globalShowEmptyRetryButton,
      );
    }

    // Wrap with RefreshIndicator if enabled
    if (enableRefreshOnEmpty || PagyConfig().globalEnableRefreshOnEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return _buildRefreshWrapper(
            context,
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: emptyWidget,
              ),
            ),
            enabled: true,
          );
        },
      );
    }

    return emptyWidget;
  }

  /// Returns true if the given [state] has an error message.
  String? _errorMessage(PagyState<T> state) {
    final message = state.error?.message ?? state.errorMessage;
    if (message == null || message.isEmpty) return null;
    return message;
  }

  Widget _buildShimmerItem(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: itemBuilder(context, placeholderItemModel as T, 0),
    );
  }

  Widget _buildRefreshWrapper(
    BuildContext context,
    Widget child, {
    required bool enabled,
  }) {
    if (!enabled) return child;

    final refreshHandler = _handleRefresh;
    if (refreshIndicatorBuilder != null) {
      return refreshIndicatorBuilder!(context, child, refreshHandler);
    }
    return RefreshIndicator(onRefresh: refreshHandler, child: child);
  }

  Future<void> _handleRefresh() async {
    if (onRefresh != null) {
      await onRefresh!();
    }
    if (refreshTriggersPagyLoad || onRefresh == null) {
      await controller!.loadData();
    }
  }
}
