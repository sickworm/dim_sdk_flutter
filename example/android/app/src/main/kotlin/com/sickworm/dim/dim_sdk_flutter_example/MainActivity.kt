package com.sickworm.dim.dim_sdk_flutter_example

import android.os.Bundle
import chat.dim.model.AccountDatabase
import chat.dim.model.MessageProcessor
import chat.dim.model.NetworkConfig
import chat.dim.sechat.Client

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)


    val client = Client.getInstance()
    val userDB = AccountDatabase.getInstance()
    val msgDB = MessageProcessor.getInstance()
    val networkConfig = NetworkConfig.getInstance()
    
    client.launch(mapOf("Application" to this))
    val user = client.currentUser
    println(client)
    println(user)
  }
}
