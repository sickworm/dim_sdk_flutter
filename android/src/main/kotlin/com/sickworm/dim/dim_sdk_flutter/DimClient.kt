
package com.sickworm.dim.dim_sdk_flutter

import chat.dim.common.Facebook
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
    private val facebook = Facebook.getInstance()

    private val localUser: LocalUser
        get() = client.currentUser

    var events: EventChannel.EventSink? = null

    private val station = ID.getInstance("gsp-s001@x5Zh9ixt8ECr59XLye1y5WWfaX4fcoaaSC")

    fun login(result: MethodChannel.Result) = launch {
        println("DimClient: login")
        client.launch(mapOf("Application" to this))
        NotificationCenter.getInstance().addObserver(this@DimClient, "DimClient")
        checkLogin()
        launch(Dispatchers.Main) {
            result.success(null)
        }
    }

    fun getLocalUser(result: MethodChannel.Result) = launch {
        checkLogin()
        val userInfo = UserInfo.fromEntity(localUser)
        launch(Dispatchers.Main) {
            result.success(userInfo.toMap())
        }
    }

    fun getContactList(result: MethodChannel.Result) = launch {
        checkLogin()
        val contactList = localUser.contacts.map {
            UserInfo.fromEntity(facebook.getUser(it)).toMap()
        }
        launch(Dispatchers.Main) {
            result.success(contactList +
                    UserInfo.fromEntity(facebook.getUser(station)).toMap())
        }
    }

    fun getChatSessionList(result: MethodChannel.Result) = launch {
        checkLogin()
        launch(Dispatchers.Main) {
            result.success(emptyList<Any>())
        }
    }

    fun sendMessage(call: MethodCall, result: MethodChannel.Result) = launch {
        checkLogin()
        val type = call.argument<Int>("type")
        val data = call.argument<String>("data")
        val receiverId = call.argument<String>("receiverId")
        println("sendMessage $type $data $receiverId")
        when (type) {
            ContentType.Text.ordinal -> sendMessage(TextContent(data), ID.getInstance(receiverId), result)
            else -> println("sendMessage not support type $type")
        }

    }

    private fun sendMessage(content: Content, receiver: ID, channelResult: MethodChannel.Result) {
        val iMsg = InstantMessage(content, client.currentUser.identifier, receiver)
        // prepare to send
        val callback = Callback { result, error ->
            println("DimClient: $result $error")
            launch(Dispatchers.Main) {
                channelResult.success(null)
            }
        }
        if (!messenger.sendMessage(iMsg, callback, true)) {
            println("DimClient: failed to send message: $iMsg")
        }
    }

    override fun onReceiveNotification(notification: Notification) {
        events?.success(null)
    }

    private suspend fun checkLogin() {
        while (!client.hasLogin()) {
            delay(10)
        }
    }
}