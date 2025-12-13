import '../config/api_config.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _api = ApiService();

  Future<List<Conversation>> getConversations() async {
    final response = await _api.get(ApiConfig.conversationsUrl);

    if (response.success && response.data['data'] != null) {
      final conversations = response.data['data']['conversations'] as List;
      return conversations.map((c) => Conversation.fromJson(c)).toList();
    }

    return [];
  }

  Future<List<Message>> getConversationMessages(String conversationId) async {
    final response = await _api.get(ApiConfig.conversationUrl(conversationId));

    if (response.success && response.data['data'] != null) {
      final messages = response.data['data']['messages'] as List;
      return messages.map((m) => Message.fromJson(m)).toList();
    }

    return [];
  }

  Future<Message?> sendMessage({
    required String recipientId,
    required String content,
    String? rideId,
  }) async {
    final body = <String, dynamic>{
      'recipientId': recipientId,
      'content': content,
    };
    if (rideId != null) body['rideId'] = rideId;

    final response = await _api.post(ApiConfig.messagesUrl, body: body);

    // Check if message was moderated but still sent
    if (response.success) {
      if (response.data['moderated'] == true) {
        // Message was blocked by moderation
        return null;
      }
      if (response.data['data'] != null && response.data['data']['message'] != null) {
        return Message.fromJson(response.data['data']['message']);
      }
    }

    return null;
  }

  Future<UnreadCount> getUnreadCount() async {
    final response = await _api.get(ApiConfig.unreadMessagesUrl);

    if (response.success && response.data['data'] != null) {
      return UnreadCount.fromJson(response.data['data']);
    }

    return UnreadCount(count: 0);
  }

  Future<bool> markAsRead(String conversationId) async {
    final response = await _api.patch(ApiConfig.markReadUrl(conversationId));
    return response.success;
  }

  Future<bool> toggleBlock(String conversationId) async {
    final response = await _api.patch(ApiConfig.blockConversationUrl(conversationId));
    return response.success;
  }

  Future<bool> deleteConversation(String conversationId) async {
    final response = await _api.delete(ApiConfig.conversationUrl(conversationId));
    return response.success;
  }
}

class Conversation {
  final String oderId;
  final Participant? participant;
  final Message? lastMessage;
  final int unreadCount;
  final bool isBlocked;
  final String? rideId;
  final DateTime updatedAt;

  Conversation({
    required this.oderId,
    this.participant,
    this.lastMessage,
    required this.unreadCount,
    required this.isBlocked,
    this.rideId,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      oderId: json['_id'] ?? '',
      participant: json['participant'] != null
          ? Participant.fromJson(json['participant'])
          : null,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isBlocked: json['isBlocked'] ?? false,
      rideId: json['ride'] is String ? json['ride'] : (json['ride']?['_id'] ?? json['ride']?['id']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class Participant {
  final String oderId;
  final String name;
  final String? profilePicture;

  Participant({
    required this.oderId,
    required this.name,
    this.profilePicture,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      oderId: json['_id'] ?? '',
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'],
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }
}

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle both API format and socket format
    String senderId = '';
    if (json['sender'] is String) {
      senderId = json['sender'];
    } else if (json['sender'] is Map) {
      senderId = json['sender']?['_id'] ?? '';
    }
    
    String recipientId = '';
    if (json['recipient'] is String) {
      recipientId = json['recipient'];
    } else if (json['recipient'] is Map) {
      recipientId = json['recipient']?['_id'] ?? '';
    }
    
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: senderId,
      recipientId: recipientId,
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt'])
              : DateTime.fromMillisecondsSinceEpoch(
                  (json['createdAt'] as num).toInt()))
          : DateTime.now(),
    );
  }
}

class UnreadCount {
  final int count;

  UnreadCount({required this.count});

  factory UnreadCount.fromJson(Map<String, dynamic> json) {
    return UnreadCount(count: json['unreadCount'] ?? 0);
  }
}