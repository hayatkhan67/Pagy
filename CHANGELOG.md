## Unreleased

- 🛠️ Fixed config initialization so controllers created before `PagyConfig.initialize()` no longer lock in an unconfigured state.
- 🔁 Persisted filters across `loadMore()` and improved retry to reuse the last request page/params.
- 📦 `PagyController` now reuses constructor `payloadData` when per-call payload is not provided.
- ✅ Improved error handling by storing `PagyError` in state and rendering it in widgets.
- 🧩 Added optional Clean Architecture pathway with `PagyPageRepository` and `GetPaginatedPageUseCase`.
- 🧪 Added `PagyController` unit tests for filter persistence, payload fallback, and retry behavior.
- 🔧 Fixed `loadMore()` to always fetch the next page (`refresh: false`).
- 🧭 Added `preserveFiltersOnRefresh` (config + `loadData` arg) and `clearFilters()` helper to control refresh filter behavior.
- ➕ Added pagination fallbacks when `totalPages` is missing via `PagyResponseParser.hasMore/totalItems` and `PagyConfig.assumeHasMoreWhenTotalPagesNull`.
- 🧹 Avoid sending null `page`/`limit` pagination params.
- 🧼 `PagyState.copyWith(clearError: true)` now clears `errorMessage`.
- ✨ Relaxed shimmer placeholder assert when a custom `shimmerBuilder` is provided.
- 🧪 Added tests for filter preservation, missing totalPages pagination, and `clearError` behavior.
- 🔄 Added flexible refresh customization: custom refresh handler, optional default reload, and custom refresh indicator wrapper.

## 1.2.0

### 🎯 Horizontal ListView Pagination

- ✨ **New Widget**: Added `PagyHorizontalListView<T>` for horizontal scrolling pagination
- 🔄 **All Features Supported**: Shimmer effects, error handling, empty state, and pull-to-refresh work seamlessly
- 📐 **Flexible Spacing**: Configure `itemSpacing` for horizontal gaps between items
- 🎨 **Custom Separators**: Optional `separatorBuilder` for custom item separators
- 📝 **Same API Pattern**: Follows existing `PagyListView` and `PagyGridView` conventions

### Example Usage

```dart
SizedBox(
  height: 200,
  child: PagyHorizontalListView<Category>(
    controller: categoryController,
    itemBuilderWithIndex: (context, category, index) {
      return CategoryCard(category: category);
    },
    itemSpacing: 12,
    shimmerEffect: true,
    placeholderItemModel: Category.empty(),
  ),
)
```

## 1.1.1

### 🎯 ItemBuilder Enhancement

- ✨ **Index Parameter Support**: Added `itemBuilderWithIndex` parameter that includes item index access
- 🔧 **Better Item Builders**: Now you can build widgets that need to know their position (e.g., "#1", "#2", etc.)
- 📝 **Backward Compatible**: Old `itemBuilder` (without index) still works but is deprecated
- 🔄 **Automatic Migration**: Use `itemBuilderWithIndex: (context, item, index) => ...` instead of `itemBuilder: (context, item) => ...`

## 1.1.0

### 🎯 UX Improvements & New Features

- 🔄 **Refresh on Empty**: Added support for pull-to-refresh when the list is empty
- 💬 **Empty State Customization**: Added `emptyStateBuilder`, `emptyMessage`, and `emptyIcon` for comprehensive empty state customization
- ✨ **Built-in Response Parsers**: Added `PagyParsers` class with pre-built parsers for common API response structures (Laravel, Django, etc.)
- 🏷️ **Better Error Handling**: Introduced `PagyError` class with error types, helpful suggestions, and status codes
- 📊 **Pagination Metadata**: Added `PagyMetadata` for easy access to pagination info in UI (`currentPage`, `totalPages`, `progress`, etc.)
- 🔧 **Convenience Methods**: Added `refresh()`, `applyFilters()`, `search()`, and `loadMore()` methods to `PagyController`
- ⚙️ **Enhanced Configuration**: Added validation for `baseUrl`, helpful warnings, and better error messages
- 📝 **Improved Naming**: Introduced clearer parameter names with deprecation strategy:
  - `responseMapper` → `responseParser`
  - `additionalQueryParams` → `query`
  - `paginationMode` → `payloadMode` (controller & config)
  - `apiLogs` → `enableLogs`
- 📚 **Comprehensive Documentation**: Complete README rewrite with examples, migration guide, and common use case
- 🔄 **Full Backward Compatibility**: All old parameter names still work (deprecated, will be removed in v2.0.0)

## 1.0.0

- 🚀 Remapped the entire package to Clean Architecture for improved scalability and maintainability.
- 📝 Added support for custom headers in API requests.
- 🏗️ Introduced a separate builder option in `PagyListView` for more flexible UI rendering.
- ⏹️ Implemented automatic cancellation of previous API calls when new requests are triggered.
- 🔒 Added interceptor support for advanced request/response handling (e.g., token blacklist).
- 🔗 `PagyController` now integrates seamlessly with both BLoC and Riverpod.
- 🧩 Added dependency injection test hooks, removing strict reliance on global `PagyConfig`.
- 📊 Enhanced logging system to allow monitoring and saving of request/response logs.
- 🌗 Integrated automatic theme support to adapt to the user's app theme (light/dark).

## 0.0.4

- Added POST request support and enhanced API interactions.
- Improved `.gitignore`.
- Updated dependencies.

## 0.0.3+1

- Set Dio compatible version.

## 0.0.3

- Fixed dependency issues.
- Updated compatibility for Flutter 3.32.
- Added functionality to limit the number of displayed items.

## 0.0.2

- Fixed logo.
- Improved example.

## 0.0.1

- Initial release.
- Added assets path.
