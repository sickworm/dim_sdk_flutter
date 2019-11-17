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

data class FContent(
        val contentType: Int,
        val data: String) {

    companion object {
        fun fromIMsg(iMsg: InstantMessage) = when(iMsg.content.type) {
            ContentType.TEXT.value -> FContent(FContentType.Text.ordinal, iMsg.content["text"] as String)
            else -> FContent(FContentType.Text.ordinal, iMsg.toString())
        }
    }
}