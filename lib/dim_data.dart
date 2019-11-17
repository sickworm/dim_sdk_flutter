import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'dim_defs.dart';

abstract class IDimData {
  Future<void> init();
  Future<List<UserInfo>> getContactList();
  // TODO add page select
  Future<List<ChatSession>> getChatSessionList();
  Future<String> getChatSessionId(String userId);
  Future<UserInfo> getUserInfo(String userId);
  Future<UserInfo> getLocalUserInfo();
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage});
  Future<void> addChatMessage(ChatMessage message);

  Future<void> setLocalUserInfo(UserInfo userInfo, LocalUserKey key);
  Future<void> addContact(UserInfo userInfo);
  Future<void> popSession(ChatSession chatSession);
}

class RamDimData extends IDimData {
  List<UserInfo> _contacts = List();
  List<ChatSession> _chatSessions = [];
  Map<String, List<ChatMessage>> _chatMessages = {};
  UserInfo _localUser;

  @override
  Future<void> init() {
    return null;
  }

  @override
  Future<List<UserInfo>> getContactList() async {
    return List.of(_contacts);
  }

  @override
  Future<List<ChatSession>> getChatSessionList() async {
    return List.of(_chatSessions);
  }

  @override
  Future<String> getChatSessionId(String userId) async {
    return userIdToSessionId(userId);
  }

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    return _contacts.firstWhere((c) => c.userId == userId);
  }

  @override
  Future<UserInfo> getLocalUserInfo() async {
    return _localUser;
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage}) async {
    // TODO test page
    var messages = _chatMessages[sessionId];
    if (messages == null) {
      return [];
    }
    return List.of(messages);
  }

  @override
  Future<void> setLocalUserInfo(UserInfo userInfo, LocalUserKey key) async {
    return _localUser = userInfo;
  }

  @override
  Future<void> addContact(UserInfo userInfo) async {
    _contacts.add(userInfo);
  }

  @override
  Future<void> popSession(ChatSession chatSession) async {
    ChatSession oldSession =
        _chatSessions.firstWhere((s) => s.sessionId == chatSession.sessionId);
    if (oldSession != null) {
      _chatSessions.remove(oldSession);
    }
    _chatSessions.add(chatSession);
    return null;
  }

  @override
  Future<void> addChatMessage(ChatMessage message) async {
    var messages = _chatMessages[message.sessionId];
    if (messages == null) {
      _chatMessages[message.sessionId] = [message];
    } else {
      var oldMessageIndex = messages.indexWhere((m) => m.id == message.id);
      if (oldMessageIndex != -1) {
        messages[oldMessageIndex] = message;
      } else {
        messages.add(message);
      }
    }
  }
}

class MockDimData extends RamDimData {
  static const kTestLogin = false;
  static const UserInfo kMocklocalUser = UserInfo(
      'Sickworm',
      'https://avatars3.githubusercontent.com/u/2757460?s=460&v=4',
      'sickworm@mock_address',
      'I am Sickworm');
  static const UserInfo kMocklocalUser2 = UserInfo(
      'Sickworm2',
      'https://avatars3.githubusercontent.com/u/2757460?s=460&v=4',
      'sickworm2@mock_address2',
      'I am Sickworm2');

  MockDimData() {
    _localUser = kTestLogin ? null : kMocklocalUser;
    _contacts = [kMocklocalUser, kMocklocalUser2];
    _chatSessions = [
      ChatSession(kMocklocalUser2, userIdToSessionId(kMocklocalUser2.userId),
          'hi this is the last chat message', 0)
    ];
    _chatMessages = {
      'sickworm2@mock_address2': List.generate(
          20,
          (i) => ChatMessage(
              userIdToSessionId(kMocklocalUser2.userId),
              Content(ContentType.Text, 'hello ${i + 1}'),
              i % 2 == 0 ? kMocklocalUser.userId : kMocklocalUser2.userId,
              i % 2 == 0 ? kMocklocalUser2.userId : kMocklocalUser.userId,
              DateTime.now().millisecondsSinceEpoch,
              isSelf: i % 2 == 0,
              isSent: true))
    };
  }
}

class PlatformDimData extends RamDimData {
  static const platform = const MethodChannel('dim_sdk_flutter/dim_data');

  @override
  Future<List<UserInfo>> getContactList() async {
    try {
      List listInfo = await platform.invokeMethod('getContactList');
      return listInfo
          .map(
              (c) => UserInfo(c['name'], c['avatar'], c['userId'], c['slogan']))
          .toList();
    } on PlatformException catch (e) {
      print(e);
    }
    return [];
  }

  @override
  Future<UserInfo> getLocalUserInfo() async {
    try {
      Map mapInfo = await platform.invokeMethod('getLocalUserInfo');
      return UserInfo(mapInfo['name'], mapInfo['avatar'], mapInfo['userId'],
          mapInfo['slogan']);
    } on PlatformException catch (e) {
      print(e);
    }
    return null;
  }
}

class DbDimData extends IDimData {
  Database _db;

  Future<void> init() async {
    _db = await openDatabase(await getDatabasesPath() + 'dim_data.db',
        onCreate: (db, version) {
      return db.execute(
        '''CREATE TABLE chat_message(
          id INTEGER PRIMARY KEY,
          sessionId TEXT,
          senderId TEXT,
          receiverId TEXT,
          createTime INTEGER,
          isSelf BOOLEAN,
          isSent BOOLEAN,
          type INTEGER,
          data TEXT)''',
      );
    }, version: 1);
  }

  @override
  Future<void> addChatMessage(ChatMessage message) {
    return _db.insert(
        'chat_message',
        {
          'sessionId': message.sessionId,
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'createTime': message.createTime,
          'isSelf': message.isSelf,
          'isSent': message.isSent,
          'type': message.content.type.index,
          'data': message.content.data
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> addContact(UserInfo userInfo) {
    // TODO: implement addContact
    return null;
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage}) {
    return _db.query('chat_message').then((result) => result
        .map((m) => ChatMessage.forSdk(
              m['id'],
              m['sessionId'],
              Content(m['type'], m['data']),
              m['senderId'],
              m['receiverId'],
              m['createTime'],
              m['isSelf'],
              m['isSent'],
            ))
        .toList());
  }

  @override
  Future<String> getChatSessionId(String userId) async {
    return userIdToSessionId(userId);
  }

  @override
  Future<List<ChatSession>> getChatSessionList() async {
    // TODO: implement getContactList
    return [];
  }

  @override
  Future<List<UserInfo>> getContactList() async {
    // TODO: implement getContactList
    return [];
  }

  @override
  Future<UserInfo> getLocalUserInfo() async {
    // TODO: implement getContactList
    return null;
  }

  @override
  Future<UserInfo> getUserInfo(String userId) {
    // TODO: implement getUserInfo
    return null;
  }

  @override
  Future<void> popSession(ChatSession chatSession) {
    // TODO: implement popSession
    return null;
  }

  @override
  Future<void> setLocalUserInfo(UserInfo userInfo, LocalUserKey key) {
    // TODO: implement setLocalUserInfo
    return null;
  }
}

class DimDataManager extends PlatformDimData {
  static DimDataManager _instance = new DimDataManager._();
  static DimDataManager getInstance() {
    return _instance;
  }

  DimDataManager._();
}
