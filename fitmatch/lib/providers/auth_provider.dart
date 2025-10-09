import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/pending_registration.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.initializeAdminUser();
      _currentUser = await _authService.getCurrentUser();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao inicializar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email ou senha incorretos, ou cadastro ainda não aprovado';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erro ao fazer login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Signup
  Future<bool> signup(Map<String, dynamic> userData, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.signup(userData, password);
      
      if (success) {
        _errorMessage = null;
      } else {
        _errorMessage = 'Email já cadastrado ou erro no cadastro';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao fazer cadastro: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao fazer logout: $e';
      notifyListeners();
    }
  }

  // Update profile
  Future<bool> updateProfile(User updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar perfil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    try {
      return await _authService.getUsers();
    } catch (e) {
      _errorMessage = 'Erro ao buscar usuários: $e';
      notifyListeners();
      return [];
    }
  }

  // Get pending registrations (admin only)
  Future<List<PendingRegistration>> getPendingRegistrations() async {
    try {
      return await _authService.getPendingRegistrations();
    } catch (e) {
      _errorMessage = 'Erro ao buscar registros pendentes: $e';
      notifyListeners();
      return [];
    }
  }

  // Approve pending registration (admin only)
  Future<bool> approvePendingRegistration(String pendingId) async {
    try {
      final success = await _authService.approvePendingRegistration(pendingId);
      if (!success) {
        _errorMessage = 'Erro ao aprovar cadastro';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao aprovar cadastro: $e';
      notifyListeners();
      return false;
    }
  }

  // Reject pending registration (admin only)
  Future<bool> rejectPendingRegistration(String pendingId) async {
    try {
      final success = await _authService.rejectPendingRegistration(pendingId);
      if (!success) {
        _errorMessage = 'Erro ao rejeitar cadastro';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao rejeitar cadastro: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
