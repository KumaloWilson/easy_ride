import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class DevLogs {
  static final Logger _logger = Logger();

  static void info(String msg) {
    if (kDebugMode) {
      _logger.i(msg);
    }
  }

  static void debug(String msg) {
    if (kDebugMode) {
      _logger.i(msg);
    }
  }

  static void warning(String msg) {
    if (kDebugMode) {
      _logger.w(msg);
    }
  }

  static void error(String msg, {dynamic? exception}) {
    if (kDebugMode) {
      _logger.e("$msg $exception");
    }
  }
}
