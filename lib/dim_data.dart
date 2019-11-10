import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class ChatSession {
  final UserInfo userInfo;
  final String sessionId;
  final String lastMessage;
  final int updateTime;

  const ChatSession(
      this.userInfo, this.sessionId, this.lastMessage, this.updateTime);
}

class UserInfo {
  final String name;
  final String avatar;
  final String userId;
  final String slogan;

  const UserInfo(this.name, this.avatar, this.userId, this.slogan);
}

class LocalUserKey {
  final String userId;
  final String keyData; // json

  const LocalUserKey(this.userId, this.keyData);
}

enum ContentType { Text, Image, File }

class Content {
  final ContentType type;
  final String data;

  const Content(this.type, this.data);

  String toString() {
    return 'Content: $type, $data';
  }
}

class ChatMessage {
  final String messageId;
  final Content content;
  final String senderId;
  final int createTime;
  final bool isSelf;
  final bool isSent;

  static Uuid _uuid = Uuid();

  static ChatMessage build(Content content, String senderId, int createTime,
      {isSelf = false, isSent = false}) {
    var messageId = _uuid.v1();
    return ChatMessage(messageId, content, senderId, createTime,
        isSelf: isSelf, isSent: isSent);
  }

  const ChatMessage(
      this.messageId, this.content, this.senderId, this.createTime,
      {this.isSelf = false, this.isSent = false});

  ChatMessage renewWithState({isSent = false}) {
    return ChatMessage(messageId, content, senderId, createTime,
        isSelf: isSelf, isSent: isSent);
  }
}

class Page {
  static const Page kLastPage = Page(0, 20);

  final int startIndex;
  final int size;
  final bool isTimeInc;
  const Page(this.startIndex, this.size, {this.isTimeInc = true});
}

abstract class IDimData {
  Future<List<UserInfo>> getContactList();
  // TODO add page select
  Future<List<ChatSession>> getChatSessionList();
  Future<String> getChatSessionId(String userId);
  Future<UserInfo> getUserInfo(String userId);
  Future<UserInfo> getLocalUserInfo();
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage});
  Future<void> addChatMessage(String sessionId, ChatMessage message);

  Future<void> setLocalUserInfo(UserInfo userInfo, LocalUserKey key);
  Future<void> addContact(UserInfo userInfo);
  Future<void> popSession(ChatSession chatSession);
}

class MockDimData extends IDimData {
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

  UserInfo _localUser = kTestLogin ? null : kMocklocalUser;
  List<UserInfo> _contacts = List();
  List<ChatSession> _chatSessions = [
    ChatSession(kMocklocalUser2, _userIdToSessionId(kMocklocalUser2.userId),
        'hi this is the last chat message', 0)
  ];
  Map<String, List<ChatMessage>> _chatMessages = {
    'sickworm2@mock_address2': List.generate(
        20,
        (i) => ChatMessage.build(Content(ContentType.Text, 'hello ${i + 1}'),
            i % 2 == 0 ? 'sickworm@mock_address' : 'sickworm2@mock_address2', i,
            isSelf: i % 2 == 0, isSent: true))
  };

  @override
  Future<List<UserInfo>> getContactList() {
    return Future.delayed(Duration(milliseconds: 300), () => [kMocklocalUser2]);
  }

  @override
  Future<List<ChatSession>> getChatSessionList() {
    return Future.delayed(Duration(milliseconds: 300), () => _chatSessions);
  }

  @override
  Future<String> getChatSessionId(String userId) {
    return Future.delayed(
        Duration(milliseconds: 0), () => _userIdToSessionId(userId));
  }

  @override
  Future<UserInfo> getUserInfo(String userId) {
    return Future.delayed(Duration(milliseconds: 300), () => _localUser);
  }

  @override
  Future<UserInfo> getLocalUserInfo() {
    return Future.delayed(Duration(milliseconds: 1000), () => _localUser);
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage}) {
    return Future.delayed(Duration(milliseconds: 50), () {
      // TODO test page
      var messages = _chatMessages[sessionId];
      if (messages == null) {
        return [];
      }
      return List.of(messages);
    });
  }

  @override
  Future<void> setLocalUserInfo(UserInfo userInfo, LocalUserKey key) {
    return Future.delayed(
        Duration(milliseconds: 50), () => _localUser = userInfo);
  }

  @override
  Future<void> addContact(UserInfo userInfo) {
    return Future.delayed(
        Duration(microseconds: 10), () => _contacts.add(userInfo));
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
  Future<void> addSessionChat(ChatSession chatSession, ChatMessage message) {
    return Future.delayed(Duration(milliseconds: 10), () {
      var sessionId = chatSession.sessionId;
      var messages = _chatMessages[sessionId];
      if (messages == null) {
        _chatMessages[sessionId] = [message];
        popSession(chatSession);
      } else {
        messages.add(message);
      }
    });
  }

  @override
  Future<void> addChatMessage(String sessionId, ChatMessage message) {
    return Future.delayed(Duration(milliseconds: 10), () {
      var messages = _chatMessages[sessionId];
      if (messages == null) {
        _chatMessages[sessionId] = [message];
      } else {
        var oldMessageIndex =
            messages.indexWhere((m) => m.messageId == message.messageId);
        if (oldMessageIndex != -1) {
          messages[oldMessageIndex] = message;
        } else {
          messages.add(message);
        }
      }
    });
  }

  static _userIdToSessionId(String userId) {
    return userId;
  }
}

class PlatformDimData extends IDimData {
  static const platform = const MethodChannel('dim_sdk_flutter/dim_data');

  @override
  Future<void> addChatMessage(String sessionId, ChatMessage message) {
    // TODO: implement addChatMessage
    return null;
  }

  @override
  Future<void> addContact(UserInfo userInfo) {
    // TODO: implement addContact
    return null;
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String sessionId,
      {Page page = Page.kLastPage}) async {
    return [];
  }

  @override
  Future<List<ChatSession>> getChatSessionList() async {
    return [];
  }

  @override
  Future<String> getChatSessionId(String userId) async {
    return _userIdToSessionId(userId);
  }

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
    // TODO: implement setLocalUser
    return null;
  }

  static _userIdToSessionId(String userId) {
    return userId;
  }
}

class DimDataManager extends PlatformDimData {
  static DimDataManager _instance = new DimDataManager._();
  static DimDataManager getInstance() {
    return _instance;
  }

  DimDataManager._();
}
