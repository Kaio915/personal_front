import 'dart:convert';
import '../models/message.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ChatService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    final token = await _authService.getToken();
    return token;
  }

  // Send a message
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      print('💬 Sending message from $senderId to $receiverId');

      final token = await _getToken();
      print('🔐 Token present: ${token != null}');
      if (token == null) {
        print('❌ No token found');
        return false;
      }

      final body = {
        'receiver_id': int.parse(receiverId),
        'content': content,
      };

      print('📤 POST /messages/ body: $body');

      final response = await ApiService.post(
        '/messages/',
        body: body,
        token: token,
      );

      print('📥 Response status: ${response.statusCode}');
      try {
        print('📦 Response body: ${response.body}');
      } catch (_) {}

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  // Get messages between two users
  Future<List<Message>> getMessagesBetweenUsers(String userId1, String userId2) async {
    try {
      print('📥 Loading messages between $userId1 and $userId2');

      final token = await _getToken();
      print('🔐 Token present: ${token != null}');
      if (token == null) {
        print('❌ No token found');
        return [];
      }

      final response = await ApiService.get(
        '/messages/conversation/$userId2',
        token: token,
      );

      print('📥 Response status: ${response.statusCode}');
      try {
        print('📦 Response body: ${response.body}');
      } catch (_) {}

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((json) => Message.fromJson(json)).toList();
        print('✅ Loaded ${messages.length} messages');
        return messages;
      }

      print('❌ Failed to load messages: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error loading messages: $e');
      return [];
    }
  }

  // Get all conversations for a user (returns list of user IDs they've chatted with)
  Future<List<String>> getConversations(String userId) async {
    try {
      print('📋 Loading conversations for user $userId');
      
      final token = await _getToken();
      if (token == null) {
        print('❌ No token found');
        return [];
      }
      
      final response = await ApiService.get(
        '/messages/conversations',
        token: token,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final conversations = data.map((id) => id.toString()).toList();
        print('✅ Found ${conversations.length} conversations');
        return conversations;
      }
      
      print('❌ Failed to load conversations: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error loading conversations: $e');
      return [];
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(String senderId, String receiverId) async {
    try {
      print('✔️ Marking messages from $senderId as read');
      
      final token = await _getToken();
      if (token == null) {
        print('❌ No token found');
        return false;
      }
      
      final response = await ApiService.patch(
        '/messages/read/$senderId',
        body: {},
        token: token,
      );
      
      if (response.statusCode == 200) {
        print('✅ Messages marked as read');
        return true;
      }
      
      print('❌ Failed to mark messages as read: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error marking messages as read: $e');
      return false;
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      print('🔎 getUnreadMessageCount for $userId');
      final token = await _getToken();
      print('🔐 Token present: ${token != null}');
      if (token == null) return 0;
      
      final response = await ApiService.get(
        '/messages/unread/count',
        token: token,
      );
      print('📥 Unread count response status: ${response.statusCode}');
      try { print('📦 Unread count response body: ${response.body}'); } catch (_) {}
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // Get unread message count between two specific users
  Future<int> getUnreadMessageCountBetweenUsers(String currentUserId, String otherUserId) async {
    try {
      print('🔎 getUnreadMessageCountBetweenUsers: current=$currentUserId other=$otherUserId');
      final token = await _getToken();
      print('🔐 Token present: ${token != null}');
      if (token == null) return 0;
      
      final response = await ApiService.get(
        '/messages/unread/count/$otherUserId',
        token: token,
      );
      print('📥 Unread count between response status: ${response.statusCode}');
      try { print('📦 Unread count between response body: ${response.body}'); } catch (_) {}
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // Delete all messages between two users
  Future<bool> deleteConversation(String userId1, String userId2) async {
    try {
      print('🗑️ Deleting conversation between $userId1 and $userId2');
      
      final token = await _getToken();
      if (token == null) {
        print('❌ No token found');
        return false;
      }
      
      final response = await ApiService.delete(
        '/messages/conversation/$userId2',
        token: token,
      );
      
      if (response.statusCode == 200) {
        print('✅ Conversation deleted');
        return true;
      }
      
      print('❌ Failed to delete conversation: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      return false;
    }
  }

  // Get last message between two users
  Future<Message?> getLastMessage(String userId1, String userId2) async {
    try {
      final messages = await getMessagesBetweenUsers(userId1, userId2);
      
      if (messages.isEmpty) return null;
      
      return messages.last;
    } catch (e) {
      print('❌ Error getting last message: $e');
      return null;
    }
  }
}
