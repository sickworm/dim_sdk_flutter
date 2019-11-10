package com.sickworm.dim.dim_sdk_flutter

import kotlin.reflect.full.memberProperties

fun <T : Any> T.toMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    this.javaClass.kotlin.memberProperties.map {
        map[it.name] = it.get(this)
    }
    return map
}

class UserInfo(
        val name: String,
        val avatar: String,
        val userId: String,
        val slogan: String)