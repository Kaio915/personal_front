import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  
  List<Message> _messages = [];
  List<String> _conversations = [];
  Map<String, User> _users = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Message> get messages => _messages;
  List<String> get conversations => _conversations;
  Map<String, User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize
  Future<void> initialize(String currentUserId) async {
    await loadConversations(currentUserId);
    await loadUsers();
  }

  // Load all conversations for a user
  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar conversas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all users for user lookup
  Future<void> loadUsers() async {
    try {
      final usersList = await _authService.getUsers();
      _users = {for (var user in usersList) user.id: user};
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar usuários: $e';
      notifyListeners();
    }
  }

  // Load messages between two users
  Future<void> loadMessagesBetweenUsers(String userId1, String userId2) async {
    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _chatService.getMessagesBetweenUsers(userId1, userId2);
      _errorMessage = null;
      
      // Mark messages as read
      await _chatService.markMessagesAsRead(userId2, userId1);
    } catch (e) {
      _errorMessage = 'Erro ao carregar mensagens: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;

    try {
      final success = await _chatService.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: content.trim(),
      );
      
      if (success) {
        // Reload messages to show the new message
        await loadMessagesBetweenUsers(senderId, receiverId);
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao enviar mensagem';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao enviar mensagem: $e';
      notifyListeners();
      return false;
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      return await _chatService.getUnreadMessageCount(userId);
    } catch (e) {
      return 0;
    }
  }

  // Get unread message count between two specific users
  Future<int> getUnreadMessageCountBetweenUsers(String currentUserId, String otherUserId) async {
    try {
      return await _chatService.getUnreadMessageCountBetweenUsers(currentUserId, otherUserId);
    } catch (e) {
      return 0;
    }
  }

  // Get last message with a user
  Future<Message?> getLastMessage(String userId1, String userId2) async {
    try {
      return await _chatService.getLastMessage(userId1, userId2);
    } catch (e) {
      return null;
    }
  }

  // Delete conversation
  Future<bool> deleteConversation(String userId1, String userId2) async {
    try {
      final success = await _chatService.deleteConversation(userId1, userId2);
      
      if (success) {
        await loadConversations(userId1);
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao deletar conversa';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao deletar conversa: $e';
      notifyListeners();
      return false;
    }
  }

  // Get user by ID
  User? getUserById(String userId) {
    return _users[userId];
  }

  // Get conversations with user details
  List<Map<String, dynamic>> getConversationsWithDetails(String currentUserId) {
    return _conversations.map((userId) {
      final user = _users[userId];
      return {
        'user': user,
        'userId': userId,
      };
    }).where((conv) => conv['user'] != null).toList();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    try {
      await _chatService.markMessagesAsRead(senderId, receiverId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao marcar mensagens como lidas: $e';
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear messages (for when switching conversations)
  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}
