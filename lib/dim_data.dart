class Contact {
  final String name;
  final String avatar;

  const Contact(this.name, this.avatar);
}

class ChatSession {
  final String name;
  final String sessionId;
  final String avatar;
  final String lastMessage;
  final int updateTime;

  const ChatSession(this.name, this.sessionId, this.avatar, this.lastMessage,
      this.updateTime);
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

abstract class IDimData {
  Future<List<Contact>> getContactList();
  Future<List<ChatSession>> getChatSessionList();
  Future<UserInfo> getUserInfo(String userId);
  Future<UserInfo> getLocalUserInfo();

  Future<void> setLocalUser(UserInfo userInfo, LocalUserKey key);
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
  UserInfo _localUser = kTestLogin ? null : kMocklocalUser;
  List<UserInfo> _contacts = List();
  List<ChatSession> _chatSessions = [
    ChatSession(
        'Sickworm',
        'sickworm@mock_address',
        'https://avatars3.githubusercontent.com/u/2757460?s=460&v=4',
        'hi this is the last chat message',
        0)
  ];

  Future<List<Contact>> getContactList() {
    return Future.delayed(
        Duration(milliseconds: 300),
        () => List.generate(
            20,
            (i) => Contact('Sickworm',
                'https://avatars3.githubusercontent.com/u/2757460?s=460&v=4')));
  }

  Future<List<ChatSession>> getChatSessionList() {
    return Future.delayed(Duration(milliseconds: 300), () => _chatSessions);
  }

  Future<UserInfo> getUserInfo(String userId) {
    return Future.delayed(Duration(milliseconds: 300), () => _localUser);
  }

  Future<UserInfo> getLocalUserInfo() {
    return Future.delayed(Duration(milliseconds: 1000), () => _localUser);
  }

  Future<void> setLocalUser(UserInfo userInfo, LocalUserKey key) {
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
      _chatSessions.add(chatSession);
    } else {
      _chatSessions.add(chatSession);
    }
    return null;
  }
}

class DimDataManager extends MockDimData {
  static DimDataManager _instance = new DimDataManager._();
  static DimDataManager getInstance() {
    return _instance;
  }

  DimDataManager._();
}
