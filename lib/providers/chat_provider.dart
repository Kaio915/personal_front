import 'package:flutter/foundation.dart';
import 'dart:async';
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
  Map<String, int> _unreadCounts = {};
  // Track conversations that were locally cleared (so they remain listed)
  Map<String, bool> _locallyCleared = {};
  Timer? _unreadPollTimer;
  bool _isLoading = false;
  String? _errorMessage;

  List<Message> get messages => _messages;
  List<String> get conversations => _conversations;
  Map<String, User> get users => _users;
  Map<String, int> get unreadCounts => _unreadCounts;
  Map<String, bool> get locallyCleared => _locallyCleared;
  int get totalUnreadCount => _unreadCounts.values.fold(0, (a, b) => a + b);
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
      // Ensure we have user details for each conversation participant.
      await _fetchMissingUsersForConversations();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar conversas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch from API any users that are referenced in conversations but missing locally
  Future<void> _fetchMissingUsersForConversations() async {
    try {
      for (final userId in _conversations) {
        if (!_users.containsKey(userId)) {
          // AuthService.getUserById expects an int
          final intId = int.tryParse(userId);
          if (intId == null) continue;
          final fetched = await _authService.getUserById(intId);
          if (fetched != null) {
            _users[userId] = fetched;
          }
        }
      }
    } catch (e) {
      // non-fatal: just set error message and continue
      _errorMessage = 'Erro ao obter dados de usuários: $e';
    }
  }

  // Load all users for user lookup
  Future<void> loadUsers() async {
    try {
      final usersList = await _authService.getUsers();
      // Merge fetched users into existing map to avoid removing users
      // that were retrieved from the API via _fetchMissingUsersForConversations.
      final fetchedMap = {for (var user in usersList) user.id: user};
      _users = {
        ..._users, // keep previously fetched users
        ...fetchedMap,
      };
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
      // Update local unread counts cache for this conversation
      _unreadCounts[userId2] = 0;
    } catch (e) {
      _errorMessage = 'Erro ao carregar mensagens: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start polling unread counts for the current user
  void startUnreadPolling(String currentUserId, {Duration interval = const Duration(seconds: 5)}) {
    _unreadPollTimer?.cancel();
    // Run immediately once
    _pollUnreadCounts(currentUserId);
    _unreadPollTimer = Timer.periodic(interval, (_) {
      _pollUnreadCounts(currentUserId);
    });
  }

  // Stop polling unread counts
  void stopUnreadPolling() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = null;
  }

  Future<void> _pollUnreadCounts(String currentUserId) async {
    try {
      // Ensure conversations are up-to-date
      await loadConversations(currentUserId);
      for (final otherId in _conversations) {
        final count = await getUnreadMessageCountBetweenUsers(currentUserId, otherId);
        _unreadCounts[otherId] = count;
      }
      notifyListeners();
    } catch (e) {
      // ignore polling errors
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
        // If the conversation was locally cleared, restore it when sending a new message
        _locallyCleared[receiverId] = false;
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

  // Delete conversation. If localOnly is true, only remove it locally for this user
  Future<bool> deleteConversation(String userId1, String userId2, {bool localOnly = false}) async {
    try {
      if (localOnly) {
        // Remove messages locally and remove conversation from local list
        _messages = [];
        // Do NOT remove the conversation entry — keep it visible in the list
        // Mark this conversation as locally cleared so UI can reflect empty state
        _locallyCleared[userId2] = true;
        // Clear unread count for that conversation
        _unreadCounts[userId2] = 0;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

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
