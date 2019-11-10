package com.sickworm.dim.dim_sdk_flutter_example

import android.app.Application
import android.os.Bundle
import chat.dim.common.Messenger
import chat.dim.core.Callback
import chat.dim.dkd.InstantMessage
import chat.dim.mkm.ID
import chat.dim.model.AccountDatabase
import chat.dim.model.MessageProcessor
import chat.dim.model.NetworkConfig
import chat.dim.protocol.TextContent
import chat.dim.sechat.Client

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlin.concurrent.thread

class MainActivity: FlutterActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    val client: Client = Client.getInstance()
    val userDB = AccountDatabase.getInstance()
    val msgDB = MessageProcessor.getInstance()
    val networkConfig = NetworkConfig.getInstance()
    val messenger = Messenger.getInstance()
    client.launch(mapOf("Application" to this))
    val user = client.currentUser
    println("???1 $client")
    println("???2 $user")
    println("???3 ${user.contacts}")

    thread {
      Thread.sleep(5000)
      sendText(user.contacts[0], "hello dim")
      val stationID = ID.getInstance("gsp-s001@x5Zh9ixt8ECr59XLye1y5WWfaX4fcoaaSC")
      sendText(stationID, "hello station")
    }
  }

  private fun sendText(receiver: ID, text: String): InstantMessage {
    val client = Client.getInstance()
    val user = client.currentUser ?: throw NullPointerException("current user cannot be empty")
    // pack message content
    val sender = user.identifier
    val content = TextContent(text)
    if (receiver.type.isGroup) {
      content.group = receiver
    }
    val iMsg = InstantMessage(content, sender, receiver)
    // prepare to send
    val callback = Callback { result, error ->
      println("???4 $result $error")
    }
    val messenger = Messenger.getInstance()
    if (!messenger.sendMessage(iMsg, callback, true)) {
      println("???5 failed to send message: $iMsg")
    }
    return iMsg
  }
}
