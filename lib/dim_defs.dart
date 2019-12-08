import 'dart:math';

class ChatSession {
  final String userId;
  final String sessionId;
  final String lastMessage;
  final int updateTime;

  const ChatSession(
      this.userId, this.sessionId, this.lastMessage, this.updateTime):
        assert(userId != null),
        assert(sessionId != null),
        assert(lastMessage != null),
        assert(updateTime != null);

  String toString() {
    return '{ChatSession: $userId, $sessionId, $lastMessage, $updateTime}';
  }
}

class UserInfo {
  final String name;
  final String avatar;
  final String userId;
  final String slogan;
  final String extras;

  const UserInfo(this.name, this.avatar, this.userId, this.slogan,
      {this.extras = ""}):
        assert(name != null),
        assert(avatar != null),
        assert(userId != null),
        assert(slogan != null),
        assert(extras != null);

  String toString() {
    return '{UserInfo: $name, $userId}';
  }
}

class LocalUserInfo extends UserInfo {
  final String key;

  const LocalUserInfo(
      String name, String avatar, String userId, String slogan, this.key,
      {extras}):
        assert(key != null),
        super(name, avatar, userId, slogan, extras: extras);

  String toString() {
    return '{LocalUserInfo: $name, $userId}';
  }
}

enum ContentType { Text, Image, File }

ContentType intToContentType(int index) {
  return ContentType.values.firstWhere((v) => v.index == index);
}

class Content {
  final ContentType type;
  final String data;

  const Content(this.type, this.data):
        assert(type != null),
        assert(data != null);

  String toString() {
    return '{Content: $type, $data}';
  }
}

class ChatMessage {
  final int id;
  final String sessionId;
  final Content content;
  final String senderId;
  final String receiverId;
  final int createTime;
  final bool isSelf;
  final bool isSent;

  ChatMessage(sessionId, content, senderId, receiverId, createTime,
      {isSelf = false, isSent = false})
      : this.forSdk(generateId(), sessionId, content, senderId, receiverId,
            createTime, isSelf, isSent);

  ChatMessage.forSdk(this.id, this.sessionId, this.content, this.senderId,
      this.receiverId, this.createTime, this.isSelf, this.isSent):
        assert(id != null),
        assert(sessionId != null),
        assert(content != null),
        assert(senderId != null),
        assert(receiverId != null),
        assert(createTime != null),
        assert(isSelf != null),
        assert(isSent != null);

  ChatMessage copy(
      {int createTime, String senderId, String receiverId, bool isSent}) {
    var realCreateTime = createTime == null ? this.createTime : createTime;
    var realIsSent = isSent == null ? this.isSent : isSent;
    var realSenderId = senderId == null ? this.senderId : senderId;
    var realReceiverId = receiverId == null ? this.receiverId : receiverId;
    return ChatMessage.forSdk(id, sessionId, content, realSenderId,
        realReceiverId, realCreateTime, isSelf, realIsSent);
  }

  String toString() {
    return '{ChatMessage: $id, $sessionId, $content, $senderId, $receiverId, '
        '$createTime, $isSelf, $isSent}';
  }
}

class Page {
  static const Page kLastPage = Page(0, 20);

  final int startIndex;
  final int size;
  final bool isTimeInc;
  const Page(this.startIndex, this.size, {this.isTimeInc = true}):
      assert(startIndex != null),
        assert(size != null),
        assert(isTimeInc != null);

  String toString() {
    return '{Page: $startIndex, $size, $isTimeInc}';
  }
}

final _random = Random();
int generateId() {
  return _random.nextInt(2 ^ 53);
}

String userIdToSessionId(String userId) {
  return userId;
}

final gsp001 = UserInfo(
    'gsp-s001',
    'https://avatars3.githubusercontent.com/u/2757460?s=460&v=4',
    'gsp-s001@x5Zh9ixt8ECr59XLye1y5WWfaX4fcoaaSC', '');

final gsp002 = UserInfo(
    'gsp-s002',
    'https://avatars3.githubusercontent.com/u/2757460?s=460&v=4',
    'gsp-s002@wpjUWg1oYDnkHh74tHQFPxii6q9j3ymnyW', '');
