
package com.sickworm.dim.dim_sdk_flutter

import chat.dim.common.Facebook
import chat.dim.common.Messenger
import chat.dim.core.Callback
import chat.dim.crypto.PrivateKey
import chat.dim.crypto.impl.PrivateKeyImpl
import chat.dim.database.Immortals
import chat.dim.dkd.Content
import chat.dim.dkd.InstantMessage
import chat.dim.format.JSON
import chat.dim.mkm.*
import chat.dim.model.AccountDatabase
import chat.dim.model.MessageProcessor
import chat.dim.model.NetworkConfig
import chat.dim.notification.Notification
import chat.dim.notification.NotificationCenter
import chat.dim.notification.Observer
import chat.dim.protocol.ProfileCommand
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
    // use this built-in user to send messages before create account
    private val hulk = ID.getInstance("hulk@4YeVEN3aUnvC1DNUufCq1bs9zoBSJTzVEj")

    fun launchServer(result: MethodChannel.Result) = launch {
        println("DimClient: launchServer")
        client.launch(mapOf("Application" to this))
        client.login(facebook.getUser(hulk) as LocalUser?)
        NotificationCenter.getInstance().addObserver(this@DimClient, "MessageUpdated")
        checkLogin()
        launch(Dispatchers.Main) {
            result.success(null)
        }
    }

    fun getLocalUser(result: MethodChannel.Result) = launch {
        checkLogin()
        val userInfo = FUserInfo.fromEntity(localUser)
        launch(Dispatchers.Main) {
            result.success(userInfo.toMap())
        }
    }

    fun getContactList(result: MethodChannel.Result) = launch {
        checkLogin()
        val contactList = localUser.contacts.map {
            FUserInfo.fromEntity(facebook.getUser(it)).toMap()
        }
        launch(Dispatchers.Main) {
            result.success(contactList +
                    FUserInfo.fromEntity(facebook.getUser(station)).toMap())
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
            FContentType.Text.ordinal -> sendMessage(TextContent(data), ID.getInstance(receiverId), result)
            else -> println("sendMessage not support type $type")
        }

    }

    private fun sendMessage(content: Content, receiver: ID, channelResult: MethodChannel.Result) {
        val iMsg = InstantMessage(content, client.currentUser.identifier, receiver)
        // prepare to send
        val callback = Callback { result, error ->
            println("DimClient: sendMessage $result $error")
            launch(Dispatchers.Main) {
                println("DimClient: ????")
//                channelResult.success(null)
            }
        }
        if (!messenger.sendMessage(iMsg, callback, true)) {
            println("DimClient: sendMessage failed to send message: $iMsg")
        }
    }

    fun createAccount(call: MethodCall, channelResult: MethodChannel.Result) = launch {
        checkLogin()

        val name = call.argument<String>("name")
        val avatar = call.argument<String>("avatar")

        val privateKey = PrivateKeyImpl.generate(PrivateKey.RSA)
        val meta = Meta.generate(Meta.VersionDefault, privateKey, name)
        val id = meta.generateID(NetworkType.Main)
        val profile = Profile(id).apply {
            this.name = name
            // TODO use dim sdk to upload avatar
        }
        profile.sign(privateKey)

        // https://stackoverflow.com/questions/59127502/kotlin-coruntines-wont-execute-when-in-a-launch-and-callback
        sendProfile(id, meta, profile, privateKey, channelResult)
    }

    private fun sendProfile(id: ID, meta: Meta, profile: Profile,
                            privateKey: PrivateKey,
                            channelResult: MethodChannel.Result) {
        val profileCommand = ProfileCommand(id, meta, profile)
        val iMsg = InstantMessage(profileCommand, hulk, station)
        val callback = Callback { _, error ->
            println("DimClient: createAccount error $error")
            launch(Dispatchers.Main) {
                channelResult.success(FLocalUserInfo.fromProfile(profile, privateKey).toMap())
            }
        }
        if (!messenger.sendMessage(iMsg, callback, true)) {
            println("DimClient: createAccount failed to send message: $iMsg")
        }
    }

    fun login(call: MethodCall, channelResult: MethodChannel.Result) = launch {
        val name = call.argument<String>("name")!!
        val avatar = call.argument<String>("avatar")!!
        val userId = call.argument<String>("userId")!!
        val slogan = call.argument<String>("slogan")!!
        val extras = call.argument<String>("extras")!!
        val key = call.argument<String>("key")!!
        val fLocalUserInfo = FLocalUserInfo(name, avatar, userId, slogan, extras, key)

        val privateKey = PrivateKeyImpl.getInstance(JSON.decode(key))
        val meta = Meta.generate(Meta.VersionDefault, privateKey, name)
        val id = meta.generateID(NetworkType.Main)
        val profile = Profile(id).apply {
            this.name = name
            // TODO use dim sdk to upload avatar
        }
        profile.sign(privateKey)

        // bravo!!
        AccountDatabase.getInstance().saveMeta(meta, id)
        AccountDatabase.getInstance().saveProfile(profile)
        AccountDatabase.getInstance().savePrivateKey(privateKey, id)
        AccountDatabase.getInstance().addUser(id)

        val localUser = facebook.getUser(id) as LocalUser
        client.login(localUser)

        checkLogin()

        launch(Dispatchers.Main) {
            channelResult.success(null)
        }
    }

    override fun onReceiveNotification(notification: Notification) {
        val iMsg = notification.userInfo["msg"] as InstantMessage
        launch(Dispatchers.Main) {
            events?.success(FChatMessage.fromIMsg(iMsg).toMap())
        }
    }

    private suspend fun checkLogin() {
        while (!client.hasLogin()) {
            delay(10)
        }
    }
}