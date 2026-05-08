part of 'pagy_controller.dart';

// =============================================================================
// PagyControllerHelpers — Improved API (v2)
// =============================================================================
//
// This extension provides a clean, intuitive API for manipulating paginated
// data in a PagyController. All methods keep the internal [PagyState] in sync.
//
// ## Quick Reference:
//
// | What you want                 | Method             |
// |-------------------------------|--------------------|
// | Add one item                  | `add()`            |
// | Add many items                | `addAll()`         |
// | Insert at position            | `insert()`         |
// | Update matching item          | `updateWhere()`    |
// | Remove matching items         | `remove()`         |
// | Remove at index               | `removeAt()`       |
// | Replace matching item         | `replace()`        |
// | Transform all items           | `map()`            |
// | Filter items in-place         | `where()`          |
// | Sort items                    | `sort()`           |
// | Upsert (update or insert)     | `upsertWhere()`    |
// | Batch multiple operations     | `batch()`          |
// | Listen to changes             | `onChange()`       |
// | Clear everything              | `clear()`          |
// | Reset to initial state        | `reset()`          |
// =============================================================================

/// Extension providing helper methods for manipulating paginated data
/// inside a [PagyController].
///
/// These utilities allow adding, updating, removing, or resetting items
/// in the local cache while keeping [PagyState] in sync.
///
/// ### Usage Example:
///
/// ```dart
/// // Add a new item to the top of the list
/// controller.add(newUser, position: InsertPosition.start);
///
/// // Update a specific user across the list
/// controller.updateWhere(
///   where: (user) => user.id == targetId,
///   update: (user) => user.copyWith(name: 'New Name'),
/// );
///
/// // Remove items matching a condition
/// controller.remove(where: (user) => user.isBlocked);
///
/// // Batch multiple changes (single UI rebuild)
/// controller.batch((items) {
///   items.removeWhere((u) => u.isBlocked);
///   items.sort((a, b) => a.name.compareTo(b.name));
/// });
/// ```
extension PagyControllerHelpers<T> on PagyController<T> {
  // ===========================================================================
  // 📊 State Inspection
  // ===========================================================================

  /// Whether the items list is empty.
  ///
  /// ```dart
  /// if (controller.isEmpty) {
  ///   showEmptyState();
  /// }
  /// ```
  bool get isEmpty => itemsList.isEmpty;

  /// Whether the items list is not empty.
  bool get isNotEmpty => itemsList.isNotEmpty;

  /// The number of items currently loaded.
  ///
  /// ```dart
  /// Text('${controller.length} items loaded');
  /// ```
  int get length => itemsList.length;

  /// The first item in the list, or `null` if empty.
  ///
  /// ```dart
  /// final newest = controller.first;
  /// ```
  T? get first => itemsList.isEmpty ? null : itemsList.first;

  /// The last item in the list, or `null` if empty.
  T? get last => itemsList.isEmpty ? null : itemsList.last;

  // ===========================================================================
  // ➕ Adding Items
  // ===========================================================================

  /// Adds a single [item] to the list.
  ///
  /// Use [position] to control where the item is placed:
  /// - [InsertPosition.end] (default) — appends to the bottom
  /// - [InsertPosition.start] — prepends to the top
  ///
  /// ```dart
  /// // Append to end (default)
  /// controller.add(newMessage);
  ///
  /// // Prepend to start (e.g. newest-first lists)
  /// controller.add(newPost, position: InsertPosition.start);
  /// ```
  void add(T item, {InsertPosition position = InsertPosition.end}) {
    switch (position) {
      case InsertPosition.start:
        itemsList.insert(0, item);
      case InsertPosition.end:
        itemsList.add(item);
    }
    _emit();
  }

  /// Adds multiple [items] to the list.
  ///
  /// Use [position] to control placement (same as [add]).
  ///
  /// ```dart
  /// controller.addAll(newUsers, position: InsertPosition.start);
  /// ```
  void addAll(List<T> items, {InsertPosition position = InsertPosition.end}) {
    switch (position) {
      case InsertPosition.start:
        itemsList.insertAll(0, items);
      case InsertPosition.end:
        itemsList.addAll(items);
    }
    _emit();
  }

  /// Inserts an [item] at a specific [index].
  ///
  /// If [index] is out of range, the item is safely appended to the end.
  ///
  /// ```dart
  /// controller.insert(2, pinnedItem);
  /// ```
  void insert(int index, T item) {
    if (index < 0 || index > itemsList.length) {
      itemsList.add(item);
    } else {
      itemsList.insert(index, item);
    }
    _emit();
  }

  // ===========================================================================
  // ✏️ Updating Items
  // ===========================================================================

  /// Updates items matching [where] using the [update] function.
  ///
  /// This is the recommended way to update items — it's clear, safe, and
  /// works great with `copyWith` patterns.
  ///
  /// By default updates **all** matching items. Set [firstOnly] to `true`
  /// to update only the first match.
  ///
  /// Returns the number of items updated.
  ///
  /// ```dart
  /// // Update friend status for a specific user across the list
  /// controller.updateWhere(
  ///   where: (user) => user.id == userId,
  ///   update: (user) => user.copyWith(friendStatus: FriendStatus.accepted),
  /// );
  ///
  /// // Update only the first match
  /// controller.updateWhere(
  ///   where: (item) => item.isDefault,
  ///   update: (item) => item.copyWith(isDefault: false),
  ///   firstOnly: true,
  /// );
  /// ```
  int updateWhere({
    required bool Function(T item) where,
    required T Function(T item) update,
    bool firstOnly = false,
  }) {
    int count = 0;
    for (int i = 0; i < itemsList.length; i++) {
      if (where(itemsList[i])) {
        itemsList[i] = update(itemsList[i]);
        count++;
        if (firstOnly) break;
      }
    }
    if (count > 0) _emit();
    return count;
  }

  /// Updates the item at [index] with [item].
  ///
  /// Returns `true` if the update succeeded, `false` if index was out of range.
  ///
  /// ```dart
  /// controller.update(0, updatedHeader);
  /// ```
  bool update(int index, T item) {
    if (index >= 0 && index < itemsList.length) {
      itemsList[index] = item;
      _emit();
      return true;
    }
    return false;
  }

  // ===========================================================================
  // ❌ Removing Items
  // ===========================================================================

  /// Removes all items matching the [where] condition.
  ///
  /// Returns the number of items removed.
  ///
  /// ```dart
  /// // Remove blocked users
  /// final removedCount = controller.remove(
  ///   where: (user) => user.isBlocked,
  /// );
  /// print('Removed $removedCount blocked users');
  ///
  /// // Remove a specific user by ID
  /// controller.remove(where: (user) => user.id == targetId);
  /// ```
  int remove({required bool Function(T item) where}) {
    final before = itemsList.length;
    itemsList.removeWhere(where);
    final removedCount = before - itemsList.length;
    if (removedCount > 0) _emit();
    return removedCount;
  }

  /// Removes the item at [index].
  ///
  /// Returns the removed item, or `null` if [index] was out of range.
  ///
  /// ```dart
  /// final removed = controller.removeAt(0);
  /// ```
  T? removeAt(int index) {
    if (index >= 0 && index < itemsList.length) {
      final item = itemsList.removeAt(index);
      _emit();
      return item;
    }
    return null;
  }

  // ===========================================================================
  // 🔄 Replacing Items
  // ===========================================================================

  /// Replaces the first item matching [where] with [replacement].
  ///
  /// Returns `true` if a replacement was made.
  ///
  /// ```dart
  /// controller.replace(
  ///   where: (user) => user.id == updatedUser.id,
  ///   replacement: updatedUser,
  /// );
  /// ```
  bool replace({
    required bool Function(T item) where,
    required T replacement,
  }) {
    final index = itemsList.indexWhere(where);
    if (index != -1) {
      itemsList[index] = replacement;
      _emit();
      return true;
    }
    return false;
  }

  /// Updates an existing item if found, or inserts it if not found.
  ///
  /// When a match is found via [where], the item is updated using [update].
  /// When no match is found, [item] is inserted at [position].
  ///
  /// Returns `true` if an existing item was updated, `false` if inserted.
  ///
  /// ```dart
  /// // Update user if exists, otherwise add to list
  /// final wasUpdated = controller.upsertWhere(
  ///   where: (u) => u.id == user.id,
  ///   update: (old) => old.copyWith(name: user.name),
  ///   item: user,
  /// );
  /// ```
  bool upsertWhere({
    required bool Function(T item) where,
    required T Function(T item) update,
    required T item,
    InsertPosition position = InsertPosition.end,
  }) {
    final index = itemsList.indexWhere(where);
    if (index != -1) {
      itemsList[index] = update(itemsList[index]);
      _emit();
      return true;
    } else {
      add(item, position: position);
      return false;
    }
  }

  // ===========================================================================
  // 🔀 Transforming Items
  // ===========================================================================

  /// Transforms all items using the [transform] function.
  ///
  /// Useful for bulk updates like toggling a property across all items.
  ///
  /// ```dart
  /// // Mark all notifications as read
  /// controller.map((n) => n.copyWith(isRead: true));
  ///
  /// // Update friend status for a specific user
  /// controller.map(
  ///   (user) => user.id == targetId
  ///       ? user.copyWith(friendStatus: newStatus)
  ///       : user,
  /// );
  /// ```
  void map(T Function(T item) transform) {
    final updated = itemsList.map(transform).toList();
    itemsList
      ..clear()
      ..addAll(updated);
    _emit();
  }

  /// Removes items that do **not** match the [test] condition.
  ///
  /// This is the opposite of [remove] — it **keeps** matching items.
  ///
  /// Returns the number of items removed.
  ///
  /// ```dart
  /// // Keep only active users
  /// controller.where((user) => user.isActive);
  /// ```
  int where(bool Function(T item) test) {
    final before = itemsList.length;
    itemsList.retainWhere(test);
    final removedCount = before - itemsList.length;
    if (removedCount > 0) _emit();
    return removedCount;
  }

  /// Sorts the items using the provided [compare] function.
  ///
  /// ```dart
  /// // Sort by name A-Z
  /// controller.sort((a, b) => a.name.compareTo(b.name));
  ///
  /// // Sort by date, newest first
  /// controller.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  /// ```
  void sort(int Function(T a, T b) compare) {
    itemsList.sort(compare);
    _emit();
  }

  /// Swaps items at [indexA] and [indexB].
  ///
  /// Returns `true` if the swap succeeded.
  ///
  /// ```dart
  /// controller.swap(0, 1); // Swap first two items
  /// ```
  bool swap(int indexA, int indexB) {
    if (indexA < 0 ||
        indexB < 0 ||
        indexA >= itemsList.length ||
        indexB >= itemsList.length) {
      return false;
    }
    final temp = itemsList[indexA];
    itemsList[indexA] = itemsList[indexB];
    itemsList[indexB] = temp;
    _emit();
    return true;
  }

  /// Moves an item from [from] to [to] index.
  ///
  /// Useful for drag-and-drop reordering.
  ///
  /// Returns `true` if the move succeeded.
  ///
  /// ```dart
  /// controller.move(from: 3, to: 0); // Move 4th item to the top
  /// ```
  bool move({required int from, required int to}) {
    if (from < 0 ||
        to < 0 ||
        from >= itemsList.length ||
        to >= itemsList.length) {
      return false;
    }
    final item = itemsList.removeAt(from);
    itemsList.insert(to, item);
    _emit();
    return true;
  }

  // ===========================================================================
  // 🔍 Querying Items
  // ===========================================================================

  /// Checks if any item matches the [test] condition.
  ///
  /// ```dart
  /// if (controller.contains((u) => u.id == userId)) {
  ///   print('User is in the list');
  /// }
  /// ```
  bool contains(bool Function(T item) test) {
    return itemsList.any(test);
  }

  /// Returns the first item matching [test], or `null` if none found.
  ///
  /// ```dart
  /// final admin = controller.firstWhereOrNull((u) => u.isAdmin);
  /// ```
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in itemsList) {
      if (test(item)) return item;
    }
    return null;
  }

  /// Returns the index of the first item matching [test], or `-1`.
  ///
  /// ```dart
  /// final index = controller.indexOf((u) => u.id == userId);
  /// if (index != -1) {
  ///   controller.update(index, updatedUser);
  /// }
  /// ```
  int indexOf(bool Function(T item) test) {
    return itemsList.indexWhere(test);
  }

  // ===========================================================================
  // ⚡ Batch Operations
  // ===========================================================================

  /// Performs multiple modifications in a single batch, triggering only
  /// **one** UI rebuild at the end.
  ///
  /// This is more efficient than calling multiple helpers individually,
  /// as each individual call would trigger a separate rebuild.
  ///
  /// ```dart
  /// controller.batch((items) {
  ///   // Remove blocked users
  ///   items.removeWhere((u) => u.isBlocked);
  ///
  ///   // Add new user at the top
  ///   items.insert(0, newUser);
  ///
  ///   // Sort by name
  ///   items.sort((a, b) => a.name.compareTo(b.name));
  /// });
  /// ```
  void batch(void Function(List<T> items) operations) {
    operations(itemsList);
    _emit();
  }

  // ===========================================================================
  // 📢 Listening
  // ===========================================================================

  /// Attaches a listener that is called whenever the items list changes.
  ///
  /// Returns a callback to remove the listener (for cleanup).
  ///
  /// ```dart
  /// final cancel = controller.onChange((items) {
  ///   print('${items.length} items loaded');
  /// });
  ///
  /// // Later, to stop listening:
  /// cancel();
  /// ```
  VoidCallback onChange(void Function(List<T> items) onChanged) {
    void listener() => onChanged(List<T>.from(itemsList));
    controller.addListener(listener);
    return () => controller.removeListener(listener);
  }

  // ===========================================================================
  // 🗑️ Clearing & Resetting
  // ===========================================================================

  /// Clears all items from the list.
  ///
  /// Unlike [reset], this preserves pagination state (page numbers, etc.).
  ///
  /// ```dart
  /// controller.clear();
  /// ```
  void clear() {
    itemsList.clear();
    _emit();
  }

  /// Replaces the entire dataset with [newData].
  ///
  /// ```dart
  /// controller.setData(filteredUsers);
  /// ```
  void setData(List<T> newData) {
    itemsList
      ..clear()
      ..addAll(newData);
    _emit();
  }

  /// Resets the controller to its initial empty state.
  ///
  /// Clears all items **and** resets pagination state (page, totalPages).
  ///
  /// ```dart
  /// controller.reset();
  /// ```
  void reset() {
    _clearItems();
  }

  /// Internal helper to reset items and pagination state.
  void _clearItems() {
    itemsList.clear();
    controller.value = controller.value.copyWith(
      data: [],
      currentPage: 0,
      totalPages: 1,
    );
  }

  // ===========================================================================
  // ⚙️ Advanced
  // ===========================================================================

  /// Directly modifies the [PagyState] using an [updater] callback.
  ///
  /// This allows advanced customizations of the state while keeping the
  /// item list and state synchronized. Use this when you need to modify
  /// pagination metadata alongside items.
  ///
  /// ```dart
  /// controller.modifyState((state) => state.copyWith(
  ///   data: [...state.data, newItem],
  ///   totalPages: state.totalPages + 1,
  /// ));
  /// ```
  void modifyState(ValueUpdater<PagyState<T>> updater) {
    final updated = updater(controller.value);
    itemsList
      ..clear()
      ..addAll(updated.data);
    controller.value = updated;
  }

  /// Disposes the underlying [ValueNotifier] to free resources.
  ///
  /// After calling this, the controller should not be used.
  void dispose() {
    cancelToken?.cancel("PagyController disposed");
    controller.dispose();
  }

  /// Internal helper to emit the current list and update [PagyState].
  void _emit() {
    controller.value = controller.value.copyWith(data: [...itemsList]);
  }

  // ===========================================================================
  // 🚫 Deprecated Methods (kept for backward compatibility)
  // ===========================================================================

  /// Attaches a listener that is called whenever the items list changes.
  ///
  /// **Deprecated:** Use [onChange] instead, which returns a cancel callback.
  ///
  /// ```dart
  /// // Before:
  /// controller.listen((items) { ... });
  ///
  /// // After:
  /// final cancel = controller.onChange((items) { ... });
  /// ```
  @Deprecated('Use onChange() instead. Will be removed in v2.0.0')
  void listen(void Function(List<T> items) onChanged) {
    controller.addListener(() {
      onChanged(List<T>.from(itemsList));
    });
  }

  /// Attaches a listener and returns a callback to remove it.
  ///
  /// **Deprecated:** Use [onChange] instead — same behavior, better name.
  @Deprecated('Use onChange() instead. Will be removed in v2.0.0')
  VoidCallback listenWithCancel(void Function(List<T> items) onChanged) {
    return onChange(onChanged);
  }

  /// Replaces the entire dataset with [newData].
  ///
  /// **Deprecated:** Use [setData] instead for clarity.
  ///
  /// ```dart
  /// // Before:
  /// controller.updateData(newList);
  ///
  /// // After:
  /// controller.setData(newList);
  /// ```
  @Deprecated('Use setData() instead. Will be removed in v2.0.0')
  void updateData(List<T> newData) {
    setData(newData);
  }

  /// Adds a single [item] to the list.
  ///
  /// **Deprecated:** Use [add] instead.
  ///
  /// ```dart
  /// // Before:
  /// controller.addItem(user, atStart: true);
  ///
  /// // After:
  /// controller.add(user, position: InsertPosition.start);
  /// ```
  @Deprecated('Use add() instead. Will be removed in v2.0.0')
  void addItem(T item, {bool atStart = false}) {
    add(
      item,
      position: atStart ? InsertPosition.start : InsertPosition.end,
    );
  }

  /// Adds multiple [items] to the list.
  ///
  /// **Deprecated:** Use [addAll] instead.
  ///
  /// ```dart
  /// // Before:
  /// controller.addItems(users, atStart: true);
  ///
  /// // After:
  /// controller.addAll(users, position: InsertPosition.start);
  /// ```
  @Deprecated('Use addAll() instead. Will be removed in v2.0.0')
  void addItems(List<T> items, {bool atStart = false}) {
    addAll(
      items,
      position: atStart ? InsertPosition.start : InsertPosition.end,
    );
  }

  /// Updates the item at [index] with [newItem].
  ///
  /// **Deprecated:** Use [update] instead.
  ///
  /// ```dart
  /// // Before:
  /// controller.updateItemAt(0, newItem);
  ///
  /// // After:
  /// controller.update(0, newItem);
  /// ```
  @Deprecated('Use update() instead. Will be removed in v2.0.0')
  void updateItemAt(int index, T newItem) {
    update(index, newItem);
  }

  /// Removes items matching [test].
  ///
  /// **Deprecated:** Use [remove] instead.
  ///
  /// ```dart
  /// // Before:
  /// controller.removeWhere((u) => u.id == id);
  ///
  /// // After:
  /// controller.remove(where: (u) => u.id == id);
  /// ```
  @Deprecated('Use remove() instead. Will be removed in v2.0.0')
  void removeWhere(bool Function(T item) test) {
    remove(where: test);
  }

  /// Inserts an [item] at a specific [index].
  ///
  /// **Deprecated:** Use [insert] instead.
  ///
  /// ```dart
  /// // Before:
  /// controller.insertAt(2, item);
  ///
  /// // After:
  /// controller.insert(2, item);
  /// ```
  @Deprecated('Use insert() instead. Will be removed in v2.0.0')
  void insertAt(int index, T item) {
    insert(index, item);
  }

  /// Replaces the first item matching [test] with [newItem].
  ///
  /// **Deprecated:** Use [replace] instead.
  ///
  /// ```dart
  /// // Before:
  /// controller.replaceWhere((u) => u.id == id, updatedUser);
  ///
  /// // After:
  /// controller.replace(
  ///   where: (u) => u.id == id,
  ///   replacement: updatedUser,
  /// );
  /// ```
  @Deprecated('Use replace() instead. Will be removed in v2.0.0')
  void replaceWhere(bool Function(T item) test, T newItem) {
    replace(where: test, replacement: newItem);
  }

  /// Maps all items using [mapper].
  ///
  /// **Deprecated:** Use [map] instead.
  ///
  /// ```dart
  /// // Before:
  /// controller.mapItems((u) => u.copyWith(isOnline: false));
  ///
  /// // After:
  /// controller.map((u) => u.copyWith(isOnline: false));
  /// ```
  @Deprecated('Use map() instead. Will be removed in v2.0.0')
  void mapItems(T Function(T old) mapper) {
    map(mapper);
  }

  /// Directly modifies the [PagyState].
  ///
  /// **Deprecated:** Use [modifyState] instead for clarity.
  ///
  /// ```dart
  /// // Before:
  /// controller.modifyDirect((state) => state.copyWith(...));
  ///
  /// // After:
  /// controller.modifyState((state) => state.copyWith(...));
  /// ```
  @Deprecated('Use modifyState() instead. Will be removed in v2.0.0')
  void modifyDirect(ValueUpdater<PagyState<T>> updater) {
    modifyState(updater);
  }
}

/// Controls where a new item is inserted in the list.
///
/// Used by [PagyControllerHelpers.add] and [PagyControllerHelpers.addAll].
enum InsertPosition {
  /// Insert at the beginning of the list (index 0).
  ///
  /// Best for newest-first lists (e.g., feeds, messages).
  start,

  /// Insert at the end of the list.
  ///
  /// Best for oldest-first lists (default behavior).
  end,
}

/// Signature for functions that update a given [PagyState].
typedef ValueUpdater<S> = S Function(S state);
