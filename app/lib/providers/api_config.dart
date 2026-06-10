import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

final String baseUrl = () {
  if (kIsWeb) {
    return 'http://localhost:3000';
  }
  try {
    if (Platform.isAndroid) {
      // 10.0.2.2 points to localhost on the host machine from the Android emulator
      return 'http://10.0.2.2:3000';
    }
  } catch (_) {
    // If Platform check fails (e.g. on web target if not guarded properly)
  }
  return 'http://localhost:3000';
}();
