import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

class PagyListenerBuilder<T> extends StatelessWidget {
  final PagyController<T> controller;
  final Widget Function(BuildContext context, PagyState<T> state) builder;

  const PagyListenerBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PagyState<T>>(
      valueListenable: controller.controller,
      builder: (context, value, _) => builder(context, value),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:pagy/pagy.dart';

class PagyListenerBuilder<T> extends StatefulWidget {
  final PagyController<T> controller;
  final Widget Function(BuildContext context, PagyState<T> state) builder;

  const PagyListenerBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  State<PagyListenerBuilder<T>> createState() => _PagyListenerBuilderState<T>();
}

class _PagyListenerBuilderState<T> extends State<PagyListenerBuilder<T>> {
  late PagyState<T> _state;

  @override
  void initState() {
    super.initState();
    _state = widget.controller.state;
    widget.controller.controller.addListener(_listener);
  }

  void _listener() {
    if (mounted) {
      setState(() {
        _state = widget.controller.state;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _state);
  }
}
*/
