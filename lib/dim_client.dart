import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:permission/permission.dart';

import 'dim_defs.dart';

final Logger log = new Logger('DimClient');

class ServerInfo {
  String name;
  String ip;
  int port;
}

typedef OnReceive = void Function(ChatMessage message);

abstract class IDimConnection {
  OnReceive receive;
  IDimConnection();
  Future<void> launch(ServerInfo serverInfo);
  Future<void> send(ChatMessage chatMessage);
}

class EchoDimConnection extends IDimConnection {
  EchoDimConnection() : super();

  @override
  Future<void> launch(ServerInfo serverInfo) {
    return Future.delayed(Duration(milliseconds: 1500));
  }

  @override
  Future<void> send(ChatMessage chatMessage) {
    return Future.delayed(Duration(milliseconds: 1000), () {
      Future.delayed(Duration(milliseconds: 1000), () {
        receive(chatMessage.copy(
            createTime: DateTime.now().millisecondsSinceEpoch,
            senderId: chatMessage.receiverId,
            receiverId: chatMessage.receiverId));
      });
    });
  }
}

class PlatformDimConnection extends IDimConnection {
  static const platform = const MethodChannel('dim_sdk_flutter/dim_client');
  static const listener =
      const EventChannel('dim_sdk_flutter/dim_client_listener');

  @override
  Future<void> launch(ServerInfo serverInfo) async {
    listener.receiveBroadcastStream().listen((data) {
      log.info('listener receive $data');
      var message = ChatMessage.forSdk(
          data['id'],
          userIdToSessionId(data['senderId']),
          Content(intToContentType(data['type']), data['data']),
          data['senderId'],
          data['receiverId'],
          data['createTime'],
          data['isSelf'],
          data['isSent']);
      receive(message);
    }, onError: (error) {
      log.warning('listener error $error');
    });
    return platform.invokeMethod('launch');
  }

  @override
  Future<void> send(ChatMessage chatMessage) {
    return platform.invokeMethod('sendMessage', {
      'type': chatMessage.content.type.index,
      'data': chatMessage.content.data,
      'receiverId': chatMessage.receiverId
    });
  }
}

class DispatchDimConnection {
  List<OnReceive> listeners = List();

  addListener(OnReceive receiver) {
    if (receiver != null) {
      listeners.add(receiver);
    }
  }

  removeListener(OnReceive receiver) {
    if (receiver != null) {
      listeners.remove(receiver);
    }
  }

  _dispatch(ChatMessage chatMessage) {
    for (OnReceive listener in listeners) {
      listener(chatMessage);
    }
  }
}

class DimClient extends IDimConnection with DispatchDimConnection {
  static DimClient _instance = new DimClient._();
  static DimClient getInstance() {
    return _instance;
  }

  IDimConnection connection = PlatformDimConnection();

  DimClient._() {
    connection.receive = _dispatch;
  }

  Future<void> checkPermission() async {
    while (true) {
      var status =
          (await Permission.getPermissionsStatus([PermissionName.Storage]))[0]
              .permissionStatus;
      if (status == PermissionStatus.notAgain) {
        await Permission.openSettings();
      } else if (status == PermissionStatus.allow) {
        break;
      } else {
        await Permission.requestPermissions([PermissionName.Storage]);
      }
    }
  }

  @override
  Future<void> launch(ServerInfo serverInfo) {
    return connection.launch(serverInfo);
  }

  @override
  Future<void> send(ChatMessage chatMessage) {
    return connection.send(chatMessage);
  }
}
