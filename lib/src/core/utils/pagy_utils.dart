import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../../../pagy.dart';

typedef PagyLogger = void Function(Object? message, {String? name});

/// Default logger implementation (used when no custom logger is provided).
void defaultPagyLogger(Object? message, {String? name}) {
  if (!kReleaseMode) {
    final tag = name != null ? '[$name]' : '[Pagy]';
    // ignore: avoid_print
    log('$tag $message');
  }
}

/// Public wrapper used throughout the package and by users.
/// Always forwards to the current logger in PagyConfig.
void pagyLog(Object? message, {String? name}) {
  // always forward to configured logger; safe even before initialize()
  PagyConfig().logger(message, name: name);
}
