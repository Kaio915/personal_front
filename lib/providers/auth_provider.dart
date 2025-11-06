import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/pending_registration.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAttemptingLogin = false; // Nova flag para prevenir redirecionamentos

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAttemptingLogin => _isAttemptingLogin;

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
  Future<bool> login(String email, String password, {String? userType}) async {
    print('📱 AuthProvider.login - INÍCIO');
    _isLoading = true;
    _isAttemptingLogin = true;
    _errorMessage = null;
    print('   Antes notifyListeners: isLoading=$_isLoading, isAttemptingLogin=$_isAttemptingLogin');
    notifyListeners();

    try {
      final user = await _authService.login(email, password, userType: userType);
      
      if (user != null) {
        print('   ✅ Login bem-sucedido');
        _currentUser = user;
        _isLoading = false;
        _isAttemptingLogin = false;
        print('   Antes notifyListeners (sucesso): isLoading=$_isLoading, isAttemptingLogin=$_isAttemptingLogin');
        notifyListeners();
        return true;
      } else {
        print('   ❌ Login falhou - credenciais incorretas');
        _errorMessage = 'Email ou senha incorretos, ou cadastro ainda não aprovado';
        _isLoading = false;
        // Manter isAttemptingLogin = true para evitar redirecionamento
        // A tela de login vai resetar isso depois de mostrar o erro
        print('   Antes notifyListeners (falha): isLoading=$_isLoading, isAttemptingLogin=$_isAttemptingLogin');
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('   ⚠️ Erro no login: $e');
      _errorMessage = 'Erro ao fazer login: $e';
      _isLoading = false;
      // Manter isAttemptingLogin = true para evitar redirecionamento
      // A tela de login vai resetar isso depois de mostrar o erro
      print('   Antes notifyListeners (erro): isLoading=$_isLoading, isAttemptingLogin=$_isAttemptingLogin');
      notifyListeners();
      return false;
    }
  }

  // Signup
  Future<bool> signup(Map<String, dynamic> userData, String password) async {
    _isLoading = true;
    _errorMessage = null;
    // NÃO notificar listeners durante signup para evitar desmonte do widget
    // notifyListeners();

    try {
      final result = await _authService.signup(userData, password);
      
      if (result['success'] == true) {
        _errorMessage = null;
      } else {
        _errorMessage = result['message'] ?? 'Erro ao fazer cadastro';
      }
      
      _isLoading = false;
      // NÃO notificar listeners aqui - deixar a tela de signup controlar
      // notifyListeners();
      return result['success'] ?? false;
    } catch (e) {
      _errorMessage = 'Erro ao fazer cadastro: $e';
      _isLoading = false;
      // NÃO notificar listeners aqui - deixar a tela de signup controlar
      // notifyListeners();
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

  // Reset login attempt flag
  void resetLoginAttempt() {
    print('🔄 AuthProvider.resetLoginAttempt - Resetando flag');
    _isAttemptingLogin = false;
    print('   Antes notifyListeners: isAttemptingLogin=$_isAttemptingLogin');
    notifyListeners();
  }
}
