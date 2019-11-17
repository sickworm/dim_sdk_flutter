import 'dart:math';

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

ContentType intToContentType(int index) {
  return ContentType.values.firstWhere((v) => v.index == index);
}

class Content {
  final ContentType type;
  final String data;

  const Content(this.type, this.data);

  String toString() {
    return 'Content: $type, $data';
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
      this.receiverId, this.createTime, this.isSelf, this.isSent);

  ChatMessage copy(
      {int createTime, String senderId, String receiverId, bool isSent}) {
    var realCreateTime = createTime == null ? this.createTime : createTime;
    var realIsSent = isSent == null ? this.isSent : isSent;
    var realSenderId = senderId == null ? this.senderId : senderId;
    var realReceiverid = receiverId == null ? this.receiverId : receiverId;
    return ChatMessage.forSdk(id, sessionId, content, realSenderId,
        realReceiverid, realCreateTime, isSelf, realIsSent);
  }
}

class Page {
  static const Page kLastPage = Page(0, 20);

  final int startIndex;
  final int size;
  final bool isTimeInc;
  const Page(this.startIndex, this.size, {this.isTimeInc = true});
}

var _random = Random();
int generateId() {
  return _random.nextInt(2 ^ 53);
}

String userIdToSessionId(String userId) {
  return userId;
}
