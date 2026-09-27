## 1.5.0

A correctness and polish release. No breaking API changes, but two runtime behaviors change — see **Changed** below.

### 🐛 Fixed

#### Error classification was broken on the default code path

The headline fix. `NetworkApiService` threw a bare `String` on failure, destroying the
original `DioException` before it reached the controller. Every error — timeout, `401`,
`500`, no connectivity — collapsed into `PagyError.unknown` with a null `statusCode`,
making `PagyErrorType` and its per-type suggestions effectively unreachable unless you
had opted into the Clean Architecture page use case.

Errors are now classified properly, and `error.type`, `error.statusCode`,
`error.suggestion`, and `error.originalException` all reach your `errorBuilder`. The
server's own message is preserved as `error.message`.

```dart
errorBuilder: (error, onRetry) {
  if (error.type == PagyErrorType.unauthorized) return LoginPrompt();
  return ErrorView(message: error.message, hint: error.suggestion, onRetry: onRetry);
}
```

#### Other fixes

| Fix | Detail |
|---|---|
| **Failed refresh no longer desyncs state** | `refresh()` cleared the item list *before* the request. On failure the UI still showed the old items while `controller.items` was empty, and the next helper call collapsed the visible list. The list is now cleared only once new data arrives. |
| **Duplicate load-more requests** | Two scroll notifications in one frame both fired a request; the second cancelled the first and refetched the same page. `loadData` now ignores a load-more while one is in flight. |
| **`ApiException` crash on non-string `message`** | A response like `{"message": {"en": "..."}}` threw a `TypeError` *inside* the error handler. Non-string messages now fall back to the type-based message. |
| **Inline shimmer crash** | Using `PagyBuilder` directly with a `shimmerBuilder` but no `placeholderItemModel` threw on load-more. It now falls back to the loader. |
| **Inconsistent "nothing loaded" state** | `reset()` reported `currentPage: 0` while a fresh controller reported `1`, so a never-loaded controller claimed `isLastPage == true`. Standardized on `0`. |
| **`headers` typing** | Was `dynamic` while `NetworkApiService` required `Map<String, String>?`, so `{'X-Foo': 1}` compiled and crashed at runtime. Now typed. |
| **Docs & typo** | `preserveFiltersOnRefresh` documented as defaulting to `false` when it is `true`; typo in the trailing-slash warning. |

### 🔄 Changed

**`limit` now defaults to `10`** (was `4`). If you never passed `limit`, your pages just got bigger. Pass `limit: 4` to keep the old size.

**`PagyParsers.simpleList` reads `total` as an item count, not a page count.** In the wild `{"data": [...], "total": 100}` almost always means 100 *items*. Pagy now derives the page count from `total` and your `limit`. If your API really does put a page count in `total`, switch to `PagyParsers.customKey(response, itemKey: 'data', totalKey: 'total')`.

Also changed:

- **Pull-to-refresh keeps your list on screen.** Previously the whole list was swapped for the shimmer/loader. The full-screen loading state is now shown only when there is nothing to display.
- **`assumeHasMoreWhenTotalPagesNull` stops at a short page.** A page returning fewer items than `limit` is treated as the last page, eliminating the guaranteed trailing empty request.
- **`PagyGridView`'s inline loader and error span the full width.** They previously rendered inside a single masonry cell, which looked broken with two or more columns. The data layout now builds on `CustomScrollView` + `SliverMasonryGrid` so the footer can be a full-width sliver. The shimmer placeholder layout has no footer and keeps using `MasonryGridView` unchanged.

### ➕ Added

- **`PagyGridView.gridDelegate`** — opt into the full masonry layout surface when the fixed-column default isn't enough. Omit it and nothing changes; supply one and `crossAxisCount` gives way to it while spacing still applies.

  ```dart
  PagyGridView<Photo>(
    controller: controller,
    // As many columns as fit, each at most 180px wide.
    gridDelegate: const SliverSimpleGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 180,
    ),
    itemBuilderWithIndex: (context, photo, i) => PhotoTile(photo: photo),
  )
  ```

  `SliverSimpleGridDelegate` and both built-in delegates are re-exported from `package:pagy/pagy.dart`, so you don't need a direct dependency on `flutter_staggered_grid_view`. Custom subclasses work too, and the paging footer stays full-width regardless.

- **Custom Shimmer Support** — Pass your own `customShimmer` widget or `shimmerBuilder` callback to `PagyListView`, `PagyGridView`, `PagyHorizontalListView`, `PagyBaseView`, or `PagyBuilder` without needing a `placeholderItemModel`. You can also configure a global default shimmer via `PagyConfig().initialize(customShimmer: ...)`.
- **`PagyConfig().reset()`** — restores every setting to its default and allows `initialize()` to run again. Useful for tests and for re-login flows that swap the base URL or token.
- Calling `initialize()` more than once now logs a warning instead of silently doing nothing.

### ⚠️ Deprecated

- **`PagyController.itemsList`** — mutating it bypasses state emission and silently desyncs the UI. Read via `items`; mutate via the helper methods (`add`, `remove`, `updateWhere`, `batch`, …). Removal in v2.0.0.

---

## 1.4.0

### ✨ Redesigned Controller Helpers API

Complete overhaul of `PagyControllerHelpers` with a cleaner, more intuitive API. All old methods are preserved as `@Deprecated` and delegate to the new implementations — **zero breaking changes**.

#### New Methods

| Category | Method | Description |
|----------|--------|-------------|
| **Adding** | `add()` | Add single item with `InsertPosition` enum |
| **Adding** | `addAll()` | Add multiple items with `InsertPosition` enum |
| **Adding** | `insert()` | Insert at specific index (safe) |
| **Updating** | `update()` | Update item at index, returns success `bool` |
| **Updating** | `updateWhere()` | Update matching items with `where`/`update` pattern, returns count |
| **Removing** | `remove()` | Remove matching items with named `where:` param, returns count |
| **Removing** | `removeAt()` | Remove at index, returns removed item or `null` |
| **Replacing** | `replace()` | Replace first match with named params |
| **Replacing** | `upsertWhere()` | Update if found, insert if not |
| **Transforming** | `map()` | Transform all items |
| **Transforming** | `where()` | Keep only matching items (in-place filter) |
| **Transforming** | `sort()` | Sort items with comparator |
| **Transforming** | `swap()` | Swap two items by index |
| **Transforming** | `move()` | Move item from one index to another (drag-and-drop) |
| **Querying** | `contains()` | Check if any item matches |
| **Querying** | `firstWhereOrNull()` | Find first match or `null` |
| **Querying** | `indexOf()` | Find index of first match |
| **Batch** | `batch()` | Multiple operations → single UI rebuild |
| **State** | `isEmpty` / `isNotEmpty` / `length` / `first` / `last` | Quick state inspection |
| **Listening** | `onChange()` | Listen with auto-cancel callback |
| **Data** | `setData()` | Replace entire dataset |
| **Data** | `clear()` | Clear items (preserves pagination state) |
| **Advanced** | `modifyState()` | Direct state modification |

#### New `InsertPosition` Enum

Replaces the confusing `atStart` boolean with a self-documenting enum:

```dart
// Before (still works, deprecated):
controller.addItem(user, atStart: true);

// After:
controller.add(user, position: InsertPosition.start);
```

### 🚫 Deprecated Methods (backward compatible)

All old helpers now delegate to the new API and show deprecation warnings:

| Old (Deprecated) | New (Recommended) |
|------------------|-------------------|
| `listen()` | `onChange()` |
| `listenWithCancel()` | `onChange()` |
| `updateData()` | `setData()` |
| `addItem()` | `add()` |
| `addItems()` | `addAll()` |
| `updateItemAt()` | `update()` |
| `removeWhere()` | `remove(where:)` |
| `insertAt()` | `insert()` |
| `replaceWhere()` | `replace(where:, replacement:)` |
| `mapItems()` | `map()` |
| `modifyDirect()` | `modifyState()` |

### 🚀 Improvements

- **Return values**: `update()`, `remove()`, `removeAt()`, `replace()`, `swap()`, `move()` return success/count for better control flow.
- **Named parameters**: `remove(where:)`, `replace(where:, replacement:)`, `updateWhere(where:, update:)` are self-documenting.
- **Batch operations**: `batch()` allows multiple list mutations with a single UI rebuild.
- **Query helpers**: `contains()`, `firstWhereOrNull()`, `indexOf()` for quick lookups without `.items`.
- **Comprehensive docs**: Every method includes dartdoc with usage examples.

## 1.3.0

### ✨ Features
- **Stack Trace Support**: `PagyError` now captures and stores `StackTrace` for easier debugging. Accessed via `error.stackTrace`.
- **Flexible Refresh**: Added custom refresh indicator support via `refreshIndicatorBuilder` and custom `onRefresh` logic.
- **Persistence Control**: Added `preserveFiltersOnRefresh` (global config + per-call) and `clearFilters()` to manage filter state during refreshes.
- **Clean Architecture**: Optional pathway with `PagyPageRepository` and `GetPaginatedPageUseCase`.

### 🚀 Improvements
- **Filtered State**: Filters are now persisted across `loadMore()` calls.
- **Enhanced Logging**: Improved debug logging with stacktrace for API and parsing failures.
- **Pagination Fallbacks**: Added support for `hasMore/totalItems` metadata and `PagyConfig.assumeHasMoreWhenTotalPagesNull`.
- **Payload Reuse**: `PagyController` now reuses initial `payloadData` if per-call payload is omitted.
- **Smart Formatting**: Avoid sending null `page`/`limit` params; clear `errorMessage` when error is fixed.

### 🛠️ Bug Fixes
- **Filter Persistence**: Changed `preserveFiltersOnRefresh` default to `true` to ensure pull-to-refresh keeps current filters.
- **Retry Logic**: Fixed `PagyBuilder` and `PagyControllerLoader` to correctly preserve filters and state during manual retries.
- **Initialization**: Fixed config race conditions where controllers could lock in an unconfigured state.
- **Logic**: Fixed `loadMore()` to always fetch next page correctly.
- **UI**: Relaxed shimmer placeholder requirements when custom `shimmerBuilder` is used.

### 🧪 Testing
- Added comprehensive unit tests for filter persistence, retry behavior, metadata fallbacks, and stacktrace handling.

## 1.2.0

### 🎯 Horizontal ListView & Dynamic Height Support

- ✨ **New Widget**: Added `PagyHorizontalListView<T>` for horizontal scrolling pagination.
- 📏 **Dynamic Height Support**: Added `useDynamicHeight` parameter for intrinsic sizing support.
- 📐 **Column/Flex Layout Ready**: Height is automatically determined by content when `useDynamicHeight: true`.
- 🏗️ **Smart Auto-Fallback**: Automatically detects unbounded height constraints and switches to dynamic layout - fixes "Horizontal viewport was given unbounded height" errors!
- 🛡️ **PagyObserver Enhancements**: Added `nullBuilder` for custom null controller handling.
- 🔄 **Feature Parity**: Full support for shimmers, error states, and empty states in horizontal mode.
- 🎨 **Customizable Spacing**: Easy configuration of `itemSpacing` and `separatorBuilder`.
- ⚠️ **Performance Note**: Dynamic height builds all items upfront (not lazy) - use with caution for very large lists.

### Example Usage

```dart
// Fixed Height (Uses efficient ListView.separated)
SizedBox(
  height: 200,
  child: PagyHorizontalListView<Category>(
    controller: categoryController,
    itemBuilderWithIndex: (context, category, index) {
      return CategoryCard(category: category);
    },
    itemSpacing: 12,
  ),
)

// Dynamic Height (Auto-sized to tallest child - perfect for Columns)
PagyHorizontalListView<Product>(
  controller: productController,
  useDynamicHeight: true,
  itemBuilderWithIndex: (context, product, index) {
    return ProductCard(product: product);
  },
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
- Updated dependencies:
  pagy: ^1.3.0

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
