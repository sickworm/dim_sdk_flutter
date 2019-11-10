package com.sickworm.dim.dim_sdk_flutter

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.Registrar

class DimSdkFlutterPlugin {
    companion object {

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            MethodChannel(registrar.messenger(), "dim_sdk_flutter").setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
                    else -> result.notImplemented()
                }
            }

            MethodChannel(registrar.messenger(), "dim_sdk_flutter/dim_data").setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLocalUserInfo" -> DimClient.getLocalUser(result)
                    "sendText" -> DimClient.sendText(call, result)
                    else -> result.notImplemented()
                }
            }

            EventChannel(registrar.view(), "dim_sdk_flutter/dim_data_listener").setStreamHandler(
                    object : EventChannel.StreamHandler {
                        override fun onListen(arguments: Any, events: EventChannel.EventSink) {
                            DimClient.events = events
                        }

                        override fun onCancel(arguments: Any) {
                        }
                    })
        }
    }

    init {
        DimClient.login()
    }
}
