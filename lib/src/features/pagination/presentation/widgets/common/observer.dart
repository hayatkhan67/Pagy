import 'package:flutter/material.dart';

import '../../../../../../pagy.dart';

/// {@template pagy_observer}
/// A lightweight widget that listens to a [PagyController] and rebuilds
/// whenever its [PagyState] changes.
///
/// `PagyObserver` is similar in spirit to Flutter's `ValueListenableBuilder`
/// or state management listeners. It uses [AnimatedBuilder] internally to
/// subscribe to changes from the controller and rebuild only the part
/// of the widget tree you wrap.
///
/// ### Features:
/// - Efficiently rebuilds only when pagination state updates
/// - Provides direct access to the current [PagyState]
/// - Works seamlessly with all `Pagy` views (List/Grid/custom)
/// - Ideal for building custom UIs like banners, footers, or badges
///
/// ### Example:
/// ```dart
/// PagyObserver<User>(
///   controller: userController,
///   builder: (context, state) {
///     if (state.isLoading) {
///       return const CircularProgressIndicator();
///     }
///     if (state.hasError) {
///       return Text('Error: ${state.error}');
///     }
///     return Text('Loaded ${state.items.length} users');
///   },
/// )
/// ```
/// {@endtemplate}
class PagyObserver<T> extends StatelessWidget {
  /// The controller whose state changes are observed.
  final PagyController<T> controller;

  /// The builder function that provides the current [PagyState].
  ///
  /// Called whenever the underlying [PagyController] notifies listeners.
  final Widget Function(BuildContext, PagyState<T>) builder;

  /// Creates a [PagyObserver] for the given [controller].
  const PagyObserver({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      /// Listens to the internal notifier of the [PagyController].
      animation: controller.controller,
      builder: (context, _) {
        return builder(context, controller.state);
      },
    );
  }
}
