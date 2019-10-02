import 'dart:async';

enum ContentType { Text, Image, File }

class Content {
  final ContentType type;
  final String data;

  Content(this.type, this.data);

  String toString() {
    return 'Content: $type, $data';
  }
}

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
  Future<void> send(Content content);
}

class EchoDimConnection extends IDimConnection {
  EchoDimConnection() : super();

  @override
  Future<void> launch(ServerInfo serverInfo) {
    return Future.delayed(Duration(milliseconds: 1500));
  }

  @override
  Future<void> send(Content content) {
    return Future.delayed(Duration(milliseconds: 1000), () {
      Future.delayed(Duration(milliseconds: 1000), () {
        receive(Content(ContentType.Text, content.data));
      });
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

  IDimConnection connection = EchoDimConnection();

  DimClient._() {
    connection.receive = _dispatch;
  }

  @override
  Future<void> launch(ServerInfo serverInfo) {
    return connection.launch(serverInfo);
  }

  @override
  Future<void> send(Content content) {
    return connection.send(content);
  }
}
