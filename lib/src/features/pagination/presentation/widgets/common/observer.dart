import 'package:flutter/material.dart';

import '../../../../../../pagy.dart';
import 'pagy_missing_controller_widget.dart';

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
/// - Supports nullable controller (shows [MissingControllerWidget] when null)
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
  ///
  /// If null, [MissingControllerWidget] is displayed instead.
  final PagyController<T>? controller;

  /// The builder function that provides the current [PagyState].
  ///
  /// Called whenever the underlying [PagyController] notifies listeners.
  final Widget Function(BuildContext context, PagyState<T> state) builder;

  /// Creates a [PagyObserver] for the given [controller].
  const PagyObserver({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const MissingControllerWidget(name: 'PagyObserver');
    }

    return AnimatedBuilder(
      /// Listens to the internal notifier of the [PagyController].
      animation: controller!.controller,
      builder: (context, _) {
        return builder(context, controller!.state);
      },
    );
  }
}
