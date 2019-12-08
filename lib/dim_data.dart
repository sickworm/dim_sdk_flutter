import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'dim_defs.dart';

/// Data Interface.
abstract class IDimData {
  Future<void> init();
  Future<List<String>> getContactList();
  // TODO add page select
  Future<List<ChatSession>> getChatSessionList();
  Future<String> getChatSessionId(String userId);
  Future<UserInfo> getUserInfo(String userId);
  Future<LocalUserInfo> getLocalUserInfo();
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage});
  Future<void> addChatMessage(ChatMessage message);

  Future<void> setLocalUserInfo(LocalUserInfo userInfo);
  Future<void> addContact(String userId);
  Future<void> addSession(ChatSession chatSession);
  Future<void> addUserInfo(UserInfo userInfo);
}

/// Storage data in ram.
class RamDimData extends IDimData {
  List<UserInfo> _userInfos = List();
  List<String> _contacts = List();
  List<ChatSession> _chatSessions = [];
  Map<String, List<ChatMessage>> _chatMessages = {};
  LocalUserInfo _localUser;

  @override
  Future<void> init() {
    return Future.value(null);
  }

  @override
  Future<List<String>> getContactList() async {
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
    return _userInfos.firstWhere((c) => c.userId == userId);
  }

  @override
  Future<LocalUserInfo> getLocalUserInfo() async {
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
  Future<void> setLocalUserInfo(LocalUserInfo userInfo) async {
    return _localUser = userInfo;
  }

  @override
  Future<void> addContact(String userId) async {
    _contacts.add(userId);
  }

  @override
  Future<void> addSession(ChatSession chatSession) async {
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

  @override
  Future<void> addUserInfo(UserInfo userInfo) {
    final index = _userInfos.indexWhere((u) => u.userId == userInfo.userId);
    if (index != -1) {
      _userInfos.removeAt(index);
    }
    _userInfos.add(userInfo);
    return null;
  }
}

/// Storage data in ram, but will
class CacheDimData extends RamDimData {
  bool contactsInited = false;
  bool sessionInited = false;
  Map<String, bool> messageInited = {};
  bool localUserInited = false;
  Map<String, bool> userInited = {};
}

/// Mock data for test.
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
    _userInfos = [kMocklocalUser, kMocklocalUser2];
    _contacts = [kMocklocalUser.userId, kMocklocalUser2.userId];
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

class PlatformDimData extends IDimData {
  static const platform = const MethodChannel('dim_sdk_flutter/dim_data');

  List<UserInfo> _contacts = List();

  @override
  Future<void> init() async {
    List listInfo = await platform.invokeMethod('getContactList');
    _contacts = List<UserInfo>.from(listInfo
        .map((c) => UserInfo(c['name'], c['avatar'], c['userId'], c['slogan'])));
  }

  @override
  Future<List<String>> getContactList() async {
    return _contacts.map((c) => c.userId);
  }

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    return _contacts.firstWhere((c) => c.userId == userId);
  }

  @override
  Future<LocalUserInfo> getLocalUserInfo() async {
    try {
      Map mapInfo = await platform.invokeMethod('getLocalUserInfo');
      return LocalUserInfo(mapInfo['name'], mapInfo['avatar'],
          mapInfo['userId'], mapInfo['slogan'], 'hidden_key');
    } on PlatformException catch (e) {
      print(e);
    }
    return null;
  }

  @override
  Future<void> addChatMessage(ChatMessage message) {
    throw Exception('not implements');
  }

  @override
  Future<void> addContact(String userId) {
    throw Exception('not implements');
  }

  @override
  Future<void> addSession(ChatSession chatSession) {
    throw Exception('not implements');
  }

  @override
  Future<void> addUserInfo(UserInfo userInfo) {
    throw Exception('not implements');
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage}) {
    throw Exception('not implements');
  }

  @override
  Future<String> getChatSessionId(String userId) {
    throw Exception('not implements');
  }

  @override
  Future<List<ChatSession>> getChatSessionList() {
    throw Exception('not implements');
  }

  @override
  Future<void> setLocalUserInfo(LocalUserInfo userInfo) {
    throw Exception('not implements');
  }
}

class DbDimData extends IDimData {
  Database _db;

  Future<void> init() async {
    _db = await openDatabase(await getDatabasesPath() + 'dim_data.db',
        onCreate: (db, version) async {
      await db.execute(
        '''CREATE TABLE chat_message(
          id INTEGER PRIMARY KEY NOT NULL,
          sessionId TEXT NOT NULL,
          senderId TEXT NOT NULL,
          receiverId TEXT NOT NULL,
          createTime INTEGER NOT NULL,
          isSelf BOOLEAN NOT NULL,
          isSent BOOLEAN NOT NULL,
          type INTEGER NOT NULL,
          data TEXT NOT NULL)''',
      );
      await db.execute(
        '''CREATE TABLE user_info(
          userId TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          avatar TEXT NOT NULL,
          slogan TEXT NOT NULL)''',
      );
      await db.execute(
        '''CREATE TABLE contact(
          userId TEXT PRIMARY KEY NOT NULL)''',
      );
      await db.execute(
        '''CREATE TABLE chat_session(
          sessionId INTEGER PRIMARY KEY NOT NULL,
          userId TEXT NOT NULL,
          lastMessage TEXT NOT NULL,
          updateTime INTEGER NOT NULL)''',
      );
      await db.execute(
        '''CREATE TABLE local_user_key(
          userId TEXT PRIMARY KEY NOT NULL,
          key TEXT NOT NULL)''',
      );

      _db = db;
      await addUserInfo(gsp001);
      await addUserInfo(gsp002);
    }, version: 1);
  }

  @override
  Future<void> addChatMessage(ChatMessage message) {
    return _db.insert(
        'chat_message',
        {
          'id': message.id,
          'sessionId': message.sessionId,
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'createTime': message.createTime,
          'isSelf': message.isSelf? 1 : 0,
          'isSent': message.isSent? 1 : 0,
          'type': message.content.type.index,
          'data': message.content.data
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> addContact(String userId) {
    return _db.insert('contact', {'userId': userId},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> addUserInfo(UserInfo userInfo) {
    return _db.insert(
        'user_info',
        {
          'name': userInfo.name,
          'avatar': userInfo.avatar,
          'userId': userInfo.userId,
          'slogan': userInfo.slogan
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage}) async {
    final result = await _db.query('chat_message',
        orderBy: 'createTime ASC');
    return List<ChatMessage>.from(result
        .map((m) => ChatMessage.forSdk(
              m['id'],
              m['sessionId'],
              Content(intToContentType(m['type']), m['data']),
              m['senderId'],
              m['receiverId'],
              m['createTime'],
              m['isSelf'] == 1? true : false,
              m['isSent'] == 1? true : false,
            )));
  }

  @override
  Future<String> getChatSessionId(String userId) async {
    return userIdToSessionId(userId);
  }

  @override
  Future<List<ChatSession>> getChatSessionList() async {
    final result = await _db.query('chat_session');
    return List<ChatSession>.from(result
        .map((m) => ChatSession(
            m['sessionId'], m['userId'], m['updateTime'], m['lastMessage'])));
  }

  @override
  Future<List<String>> getContactList() async {
    final result = await _db.query('contact');
    return List<String>.from(result.map((m) => m['userId']));
  }

  @override
  Future<LocalUserInfo> getLocalUserInfo() async {
    final result = await _db.query('local_user_key');
    if (result.length == 0) {
      return null;
    }
    final userId = result[0]['userId'];
    final key = result[0]['key'];
    final userInfo = await getUserInfo(userId);
    return LocalUserInfo(
        userInfo.name, userInfo.userId, userInfo.avatar, userInfo.slogan, key,
        extras: userInfo.extras);
  }

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    final result =
        await _db.query('user_info', where: 'userId = ?', whereArgs: [userId]);
    if (result.length <= 0) {
      return null;
    }
    var m = result[0];
    return UserInfo(m['name'], m['avatar'], m['userId'], m['slogan']);
  }

  @override
  Future<void> addSession(ChatSession chatSession) {
    return _db.insert(
        'chat_session',
        {
          'sessionId': chatSession.sessionId,
          'userId': chatSession.userInfo.userId,
          'updateTime': chatSession.updateTime,
          'lastMessage': chatSession.lastMessage
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> setLocalUserInfo(LocalUserInfo userInfo) {
    return Future.wait([
      _db.insert(
          'local_user_key', {'userId': userInfo.userId, 'key': userInfo.key},
          conflictAlgorithm: ConflictAlgorithm.replace),
      addUserInfo(userInfo)
    ]);
  }
}

class DimDataManager extends IDimData {
  static DimDataManager _instance = new DimDataManager._();
  static DimDataManager getInstance() {
    return _instance;
  }

  DimDataManager._();

  final _dbData = DbDimData();
  final _cacheData = CacheDimData();

  @override
  Future<void> addChatMessage(ChatMessage message) async {
    if (_cacheData.messageInited[message.sessionId] != true) {
      await getChatMessages(message.sessionId);
    }
    return Future.wait(
        [_dbData.addChatMessage(message), _cacheData.addChatMessage(message)]);
  }

  @override
  Future<void> addContact(String userId) async {
    if (!_cacheData.contactsInited) {
      await getContactList();
    }
    return Future.wait(
        [_dbData.addContact(userId), _cacheData.addContact(userId)]);
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage}) async {
    // TODO support page
    if (_cacheData.messageInited[sessionId] != true) {
      final messages = await _dbData.getChatMessages(sessionId);
      await Future.wait(messages.map((m) => _cacheData.addChatMessage(m)));
      _cacheData.messageInited[sessionId] = true;
    }
    return _cacheData.getChatMessages(sessionId);
  }

  @override
  Future<String> getChatSessionId(String userId) {
    return _dbData.getChatSessionId(userId);
  }

  @override
  Future<List<ChatSession>> getChatSessionList() async {
    if (!_cacheData.sessionInited) {
      final sessions = await _dbData.getChatSessionList();
      await Future.wait(sessions.map((s) => _cacheData.addSession(s)));
      _cacheData.sessionInited = true;
    }
    return _cacheData.getChatSessionList();
  }

  @override
  Future<List<String>> getContactList() async {
    if (!_cacheData.contactsInited) {
      final contacts = await _dbData.getContactList();
      await Future.wait(contacts.map((c) => _cacheData.addContact(c)));
      _cacheData.contactsInited = true;
    }
    var contactList = await _cacheData.getContactList();
    contactList.add(gsp001.userId);
    contactList.add(gsp002.userId);
    return contactList;
  }

  @override
  Future<LocalUserInfo> getLocalUserInfo() async {
    if (!_cacheData.localUserInited) {
      final localUser = await _dbData.getLocalUserInfo();
      await _cacheData.setLocalUserInfo(localUser);
      _cacheData.localUserInited = true;
    }
    return _cacheData.getLocalUserInfo();
  }

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    if (_cacheData.userInited[userId] != true) {
      final user = await _dbData.getUserInfo(userId);
      await _cacheData.addUserInfo(user);
      _cacheData.userInited[userId] = true;
    }
    return _cacheData.getUserInfo(userId);
  }

  @override
  Future<void> init() {
    final a = _dbData.init();
    final b = _cacheData.init();
    return Future.wait([a, b]);
  }

  @override
  Future<void> addSession(ChatSession chatSession) async {
    if (!_cacheData.sessionInited) {
      final sessions = await _dbData.getChatSessionList();
      await Future.wait(sessions.map((s) => _cacheData.addSession(s)));
      _cacheData.sessionInited = true;
    }
    return _cacheData.getChatSessionList();
  }

  @override
  Future<void> setLocalUserInfo(LocalUserInfo userInfo) async {
    return Future.wait([
      _dbData.setLocalUserInfo(userInfo),
      _cacheData.setLocalUserInfo(userInfo),
      Future.sync(() => _cacheData.localUserInited = true)
    ]);
  }

  @override
  Future<void> addUserInfo(UserInfo userInfo) {
    return Future.wait([
      _dbData.addUserInfo(userInfo),
      _cacheData.addUserInfo(userInfo),
      Future.sync(() => _cacheData.userInited[userInfo.userId] = true)
    ]);
  }
}
