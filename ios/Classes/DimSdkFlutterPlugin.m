#import "DimSdkFlutterPlugin.h"
#import <dim_sdk_flutter/dim_sdk_flutter-Swift.h>

@implementation DimSdkFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDimSdkFlutterPlugin registerWithRegistrar:registrar];
}
@end
