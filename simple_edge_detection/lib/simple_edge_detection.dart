
import 'dart:async';

import 'package:flutter/services.dart';

class SimpleEdgeDetection {
  static const MethodChannel _channel =
      const MethodChannel('simple_edge_detection');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
