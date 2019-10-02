import 'dart:async';
import 'package:flutter/services.dart';

export 'dim_client.dart';
export 'dim_data.dart';
export 'dim_utils.dart';

class DimSdkFlutter {
  static const MethodChannel _channel = const MethodChannel('dim_sdk_flutter');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
