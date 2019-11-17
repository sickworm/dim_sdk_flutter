package com.sickworm.dim.dim_sdk_flutter

import chat.dim.dkd.InstantMessage
import chat.dim.mkm.Entity
import chat.dim.protocol.ContentType
import kotlin.reflect.KVisibility
import kotlin.reflect.full.declaredMemberProperties

/**
 * See dim_data.dart
 */

fun <T : Any> T.toMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    this.javaClass.kotlin.declaredMemberProperties
            .filter { it.visibility == KVisibility.PUBLIC }
            .map { map[it.name] = it.get(this) }
    return map
}

data class FUserInfo(
        val name: String,
        val avatar: String,
        val userId: String,
        val slogan: String) {

    companion object {
        fun fromEntity(entity: Entity): FUserInfo {
            return FUserInfo(entity.name,
                    "https://avatars3.githubusercontent.com/u/2757460?s=460&v=4",
                    entity.identifier.toString(),
                    entity.identifier.toString())
        }
    }
}

enum class FContentType {
    Text,
    Image,
    File
}

data class FChatMessage(
        val id: Long,
        val type: Int,
        val data: String,
        val senderId: String,
        val receiverId: String,
        val createTime: Long,
        val isSelf: Boolean,
        val isSent: Boolean) {

    companion object {
        fun fromIMsg(iMsg: InstantMessage) = FChatMessage(
                id = iMsg.content.serialNumber,
                type = when(iMsg.content.type) {
                    ContentType.TEXT.value -> FContentType.Text.ordinal
                    else -> FContentType.Text.ordinal
                },
                data = when(iMsg.content.type) {
                    ContentType.TEXT.value -> iMsg.content["text"] as String
                    else -> iMsg.toString()
                },
                senderId = iMsg.envelope.sender.toString(),
                receiverId = iMsg.envelope.receiver.toString(),
                createTime = iMsg.envelope.time.time,
                isSelf = false,
                isSent = true)
    }
}
