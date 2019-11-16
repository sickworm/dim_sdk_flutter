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
  final String receiverId;
  final int createTime;
  final bool isSelf;
  final bool isSent;

  static Uuid _uuid = Uuid();

  static ChatMessage build(
      Content content, String senderId, String receiverId, int createTime,
      {isSelf = false, isSent = false}) {
    var messageId = _uuid.v1();
    return ChatMessage(messageId, content, senderId, receiverId, createTime,
        isSelf: isSelf, isSent: isSent);
  }

  const ChatMessage(this.messageId, this.content, this.senderId,
      this.receiverId, this.createTime,
      {this.isSelf = false, this.isSent = false});

  ChatMessage renewWithState({isSent = false}) {
    return ChatMessage(messageId, content, senderId, receiverId, createTime,
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

String _userIdToSessionId(String userId) {
  return userId;
}

class RamDimData extends IDimData {
  List<UserInfo> _contacts = List();
  List<ChatSession> _chatSessions = [];
  Map<String, List<ChatMessage>> _chatMessages = {};
  UserInfo _localUser;

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
    return _userIdToSessionId(userId);
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
  Future<void> addChatMessage(String sessionId, ChatMessage message) async {
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
      ChatSession(kMocklocalUser2, _userIdToSessionId(kMocklocalUser2.userId),
          'hi this is the last chat message', 0)
    ];
    _chatMessages = {
      'sickworm2@mock_address2': List.generate(
          20,
          (i) => ChatMessage.build(
              Content(ContentType.Text, 'hello ${i + 1}'),
              i % 2 == 0 ? kMocklocalUser.userId : kMocklocalUser2.userId,
              i % 2 == 0 ? kMocklocalUser2.userId : kMocklocalUser.userId,
              i,
              isSelf: i % 2 == 0,
              isSent: true))
    };
  }
}

class PlatformDimData extends RamDimData {
  static const platform = const MethodChannel('dim_sdk_flutter/dim_data');

  @override
  Future<void> addChatMessage(String sessionId, ChatMessage message) async {
    return null;
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
}

class DimDataManager extends PlatformDimData {
  static DimDataManager _instance = new DimDataManager._();
  static DimDataManager getInstance() {
    return _instance;
  }

  DimDataManager._();
}
