import 'dart:developer';

import 'package:flutter/foundation.dart';

void pagyLog(Object? message, {String? name}) {
  if (!kReleaseMode) {
    final tag = name != null ? '[$name]' : '[Pagy]';
    // ignore: avoid_print
    log('$tag $message');
  }
}
