import 'package:flutter/material.dart';

import '../../../../../../pagy.dart';

class PagyObserver<T> extends StatelessWidget {
  final PagyController<T> controller;
  final Widget Function(BuildContext, PagyState<T>) builder;

  const PagyObserver({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.controller,
      builder: (context, _) {
        return builder(context, controller.state);
      },
    );
  }
}
