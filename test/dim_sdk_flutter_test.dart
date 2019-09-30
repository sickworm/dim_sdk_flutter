import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dim_sdk_flutter/dim_sdk_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('dim_sdk_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await DimSdkFlutter.platformVersion, '42');
  });
}
