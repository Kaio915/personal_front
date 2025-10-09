import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class ChatService {
  static const String _messagesKey = 'messages';

  // Get all messages
  Future<List<Message>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString(_messagesKey);
    
    if (messagesJson == null) return [];
    
    final messagesList = jsonDecode(messagesJson) as List;
    return messagesList.map((json) => Message.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Save messages to storage
  Future<void> _saveMessages(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = jsonEncode(messages.map((msg) => msg.toJson()).toList());
    await prefs.setString(_messagesKey, messagesJson);
  }

  // Send a message
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final messages = await getMessages();
      
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      );

      messages.add(newMessage);
      await _saveMessages(messages);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get messages between two users
  Future<List<Message>> getMessagesBetweenUsers(String userId1, String userId2) async {
    final messages = await getMessages();
    
    return messages.where((msg) =>
      (msg.senderId == userId1 && msg.receiverId == userId2) ||
      (msg.senderId == userId2 && msg.receiverId == userId1)
    ).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Get all conversations for a user (returns list of user IDs they've chatted with)
  Future<List<String>> getConversations(String userId) async {
    final messages = await getMessages();
    final Set<String> conversations = {};
    
    for (final message in messages) {
      if (message.senderId == userId) {
        conversations.add(message.receiverId);
      } else if (message.receiverId == userId) {
        conversations.add(message.senderId);
      }
    }
    
    return conversations.toList();
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(String senderId, String receiverId) async {
    try {
      final messages = await getMessages();
      bool hasChanges = false;
      
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        if (message.senderId == senderId && 
            message.receiverId == receiverId && 
            !message.isRead) {
          messages[i] = message.copyWith(isRead: true);
          hasChanges = true;
        }
      }
      
      if (hasChanges) {
        await _saveMessages(messages);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    final messages = await getMessages();
    
    return messages.where((msg) =>
      msg.receiverId == userId && !msg.isRead
    ).length;
  }

  // Get unread message count between two specific users
  Future<int> getUnreadMessageCountBetweenUsers(String currentUserId, String otherUserId) async {
    final messages = await getMessages();
    
    return messages.where((msg) =>
      msg.senderId == otherUserId && 
      msg.receiverId == currentUserId && 
      !msg.isRead
    ).length;
  }

  // Delete all messages between two users
  Future<bool> deleteConversation(String userId1, String userId2) async {
    try {
      final messages = await getMessages();
      
      messages.removeWhere((msg) =>
        (msg.senderId == userId1 && msg.receiverId == userId2) ||
        (msg.senderId == userId2 && msg.receiverId == userId1)
      );
      
      await _saveMessages(messages);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get last message between two users
  Future<Message?> getLastMessage(String userId1, String userId2) async {
    final messages = await getMessagesBetweenUsers(userId1, userId2);
    
    if (messages.isEmpty) return null;
    
    return messages.last;
  }
}
