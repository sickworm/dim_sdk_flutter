
package com.sickworm.dim.dim_sdk_flutter

import chat.dim.common.Messenger
import chat.dim.core.Callback
import chat.dim.dkd.Content
import chat.dim.dkd.InstantMessage
import chat.dim.mkm.ID
import chat.dim.mkm.LocalUser
import chat.dim.model.AccountDatabase
import chat.dim.model.MessageProcessor
import chat.dim.model.NetworkConfig
import chat.dim.notification.Notification
import chat.dim.notification.NotificationCenter
import chat.dim.notification.Observer
import chat.dim.protocol.TextContent
import chat.dim.sechat.Client
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

@Suppress("EXPERIMENTAL_API_USAGE")
object DimClient: CoroutineScope, Observer {

    override val coroutineContext = newSingleThreadContext("DimClient")

    // the way to init, cool!
    private val client: Client = Client.getInstance()
    private val userDB = AccountDatabase.getInstance()
    private val msgDB = MessageProcessor.getInstance()
    private val networkConfig = NetworkConfig.getInstance()
    private val messenger = Messenger.getInstance()

    private val user:LocalUser
        get() = client.currentUser

    var events: EventChannel.EventSink? = null

    init {
        // TODO optimize
        login()
    }

    fun login() = launch {
        println("DimClient: login")
        client.launch(mapOf("Application" to this))
        NotificationCenter.getInstance().addObserver(this@DimClient, "DimClient")
    }

    fun getLocalUser(result: MethodChannel.Result) = launch {
        checkLogin()
        val userInfo = UserInfo(
                user.name,
                "https://avatars3.githubusercontent.com/u/2757460?s=460&v=4",
                user.identifier.toString(),
                user.identifier.toString())
        launch(Dispatchers.Main) {
            result.success(userInfo.toMap())
        }
    }

    fun sendText(call: MethodCall, result: MethodChannel.Result) = launch {
        checkLogin()
        val text = call.argument<String>("text")
        val receiver = call.argument<String>("receiver")
        sendMessage(TextContent(text), ID.getInstance(receiver), result)
    }

    private fun sendMessage(content: Content, receiver: ID, channelResult: MethodChannel.Result) {
        val iMsg = InstantMessage(content, client.currentUser, receiver)
        // prepare to send
        val callback = Callback { result, error ->
            println("DimClient: $result $error")
            channelResult.success(null)
        }
        val messenger = Messenger.getInstance()
        if (!messenger.sendMessage(iMsg, callback, true)) {
            println("DimClient: failed to send message: $iMsg")
        }
    }

    override fun onReceiveNotification(notification: Notification) {
        events?.success(null)
    }

    private suspend fun checkLogin() {
        while (!client.hasLogin()) {
            delay(500)
        }
    }
}