import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

void log(String? msg, {String? name}) {
  if (kReleaseMode) {
    debugPrint("$name: $msg");
  } else {
    dev.log(name: name ?? "Pagy", msg ?? "No message provided");
  }
}
