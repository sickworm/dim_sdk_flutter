import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'dim_data.dart';

final Logger log = new Logger('DimClient');

class ServerInfo {
  String name;
  String ip;
  int port;
}

typedef OnReceive = void Function(Content message);

abstract class IDimConnection {
  OnReceive receive;
  IDimConnection();
  Future<void> launch(ServerInfo serverInfo);
  Future<void> send(Content content, String receverId);
}

class EchoDimConnection extends IDimConnection {
  EchoDimConnection() : super();

  @override
  Future<void> launch(ServerInfo serverInfo) {
    return Future.delayed(Duration(milliseconds: 1500));
  }

  @override
  Future<void> send(Content content, String receverId) {
    return Future.delayed(Duration(milliseconds: 1000), () {
      Future.delayed(Duration(milliseconds: 1000), () {
        receive(Content(ContentType.Text, content.data));
      });
    });
  }
}

class PlatformDimConnection extends IDimConnection {
  static const platform = const MethodChannel('dim_sdk_flutter/dim_client');
  static const listener =
      const EventChannel('dim_sdk_flutter/dim_client_listener');

  @override
  Future<void> launch(ServerInfo serverInfo) {
    listener.receiveBroadcastStream().listen((data) {
      log.info("listener receive $data");
      var content =
          Content(intToContentType(data["contentType"]), data["data"]);
      receive(content);
    }, onError: (error) {
      log.warning("listener error $error");
    });
    return platform.invokeMethod("launch");
  }

  @override
  Future<void> send(Content content, String receiverId) {
    return platform.invokeMethod("sendMessage", {
      "type": content.type.index,
      "data": content.data,
      "receiverId": receiverId
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

  _dispatch(Content content) {
    for (OnReceive listener in listeners) {
      listener(content);
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

  @override
  Future<void> launch(ServerInfo serverInfo) {
    return connection.launch(serverInfo);
  }

  @override
  Future<void> send(Content content, String receverId) {
    return connection.send(content, receverId);
  }
}
