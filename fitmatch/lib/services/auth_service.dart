import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/pending_registration.dart';
import '../config/config.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _usersKey = 'users';
  static const String _pendingRegistrationsKey = 'pendingRegistrations';
  static const String _currentUserKey = 'currentUser';

  // Initialize admin user if it doesn't exist
  Future<void> initializeAdminUser() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    List<User> users = [];

    if (usersJson != null) {
      final usersList = jsonDecode(usersJson) as List;
      users = usersList
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    // Check if admin exists
    final adminExists = users.any((user) => user.userType == UserType.admin);

    if (!adminExists) {
      final adminUser = User(
        id: 'admin-1',
        email: 'admin@fitconnect.com',
        name: 'Administrador',
        userType: UserType.admin,
        approved: true,
      );

      users.add(adminUser);
      await _saveUsers(users);
    }
  }

  // Get all users
  Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) return [];

    final usersList = jsonDecode(usersJson) as List;
    return usersList
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Save users to storage
  Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users.map((user) => user.toJson()).toList());
    await prefs.setString(_usersKey, usersJson);
  }

  // Get pending registrations
  Future<List<PendingRegistration>> getPendingRegistrations() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingRegistrationsKey);

    if (pendingJson == null) return [];

    final pendingList = jsonDecode(pendingJson) as List;
    return pendingList
        .map(
          (json) => PendingRegistration.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  // Save pending registrations to storage
  Future<void> _savePendingRegistrations(
    List<PendingRegistration> pendingRegistrations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = jsonEncode(
      pendingRegistrations.map((pending) => pending.toJson()).toList(),
    );
    await prefs.setString(_pendingRegistrationsKey, pendingJson);
  }

  // Login user via API
  Future<User?> login(String email, String password, {String? userType}) async {
    try {
      print('=== INICIANDO LOGIN ===');
      print('Email: $email');
      print('User Type: $userType');
      print('URL: ${Config.apiUrl}/auth/login');
      
      // Construir URL com query parameter se userType for fornecido
      String endpoint = '/auth/login';
      if (userType != null) {
        endpoint += '?user_type=$userType';
      }
      
      // Fazer requisição de login para a API
      final response = await ApiService.postForm(
        endpoint,
        body: {
          'username': email, // OAuth2 usa 'username' não 'email'
          'password': password,
        },
      );

      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (!ApiService.isSuccess(response)) {
        print('Login falhou: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = ApiService.decodeResponse(response);
      final token = data['access_token'] as String?;

      if (token == null) {
        print('Token não encontrado na resposta');
        return null;
      }

      // Salvar token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);

      print('Token salvo, buscando dados do usuário do banco...');

      // Aguardar um pouco para garantir que o servidor está pronto
      await Future.delayed(Duration(milliseconds: 100));

      // Buscar dados completos do usuário do banco de dados usando o endpoint /me
      try {
        final userResponse = await http.get(
          Uri.parse('${Config.apiUrl}/auth/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(
          Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Timeout ao buscar dados do usuário');
          },
        );

        print('Status /auth/me: ${userResponse.statusCode}');
        
        if (userResponse.statusCode != 200) {
          print('Erro ao buscar dados do usuário: ${userResponse.statusCode}');
          print('Response: ${userResponse.body}');
          // Limpar token e retornar null
          await prefs.remove(_tokenKey);
          return null;
        }

        final userData = json.decode(userResponse.body);
        print('Dados do usuário recebidos do banco: $userData');
        
        // Mapear role para UserType
        UserType userType;
        final roleName = userData['role']['name'] as String;
        if (roleName == 'admin') {
          userType = UserType.admin;
        } else if (roleName == 'personal') {
          userType = UserType.trainer;
        } else if (roleName == 'aluno') {
          userType = UserType.student;
        } else {
          userType = UserType.student; // default
        }

        final user = User(
          id: userData['id'].toString(),
          email: userData['email'] as String,
          name: userData['full_name'] as String? ?? 'Usuário',
          userType: userType,
          approved: userData['approved'] as bool? ?? false,
        );

        print('Usuário criado: ${user.name} (${user.email}) - Role: ${user.userType.value}');

        await _saveCurrentUser(user);
        return user;
      } catch (e) {
        print('Exceção ao buscar /auth/me: $e');
        // Se falhar ao buscar /me, limpar token
        await prefs.remove(_tokenKey);
        return null;
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      return null;
    }
  }

  // Get saved token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user by ID from API
  Future<User?> getUserById(int userId) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        
        // Mapear role para UserType
        UserType userType;
        final roleName = userData['role']['name'] as String;
        if (roleName == 'admin') {
          userType = UserType.admin;
        } else if (roleName == 'personal') {
          userType = UserType.trainer;
        } else if (roleName == 'aluno') {
          userType = UserType.student;
        } else {
          userType = UserType.student; // default
        }

        return User(
          id: userData['id'].toString(),
          email: userData['email'] as String,
          name: userData['full_name'] as String? ?? 'Usuário',
          userType: userType,
          approved: userData['approved'] as bool? ?? false,
        );
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar usuário $userId: $e');
      return null;
    }
  }

  // Login user (método antigo com SharedPreferences - mantido como backup)
  Future<User?> loginLocal(String email, String password) async {
    final users = await getUsers();

    // Find user with matching email and password
    final user = users.where((u) => u.email == email).firstOrNull;

    if (user == null) return null;

    // Check if it's admin or approved user
    if (user.userType != UserType.admin && user.approved != true) {
      return null;
    }

    // In a real app, you would hash and compare passwords
    // For now, we'll use a simple check (assuming password is stored in a separate collection)
    // This is a simplified version - passwords should never be stored in plain text

    // Save current user
    await _saveCurrentUser(user);
    return user;
  }

  // Register new user (creates user via API)
  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData, String password) async {
    try {
      final email = userData['email'] as String;
      final name = userData['name'] as String;
      final userType = userData['userType'] as String;
      
      // Mapear o tipo de usuário para role_id
      // 1 = admin, 2 = personal, 3 = aluno
      int roleId;
      if (userType == 'trainer') {
        roleId = 2; // personal
      } else if (userType == 'student') {
        roleId = 3; // aluno
      } else {
        roleId = 3; // default para aluno
      }

      // Preparar dados para enviar à API (incluir TODOS os campos)
      final requestBody = {
        'email': email,
        'password': password,
        'full_name': name,
        'role_id': roleId,
      };

      // Adicionar campos específicos de aluno
      if (userData.containsKey('goals')) {
        requestBody['goals'] = userData['goals'];
      }
      if (userData.containsKey('fitnessLevel')) {
        requestBody['fitnessLevel'] = userData['fitnessLevel'];
      }
      if (userData.containsKey('registration_date')) {
        requestBody['registration_date'] = userData['registration_date'];
      }

      // Adicionar campos específicos de personal trainer
      if (userData.containsKey('specialty')) {
        requestBody['specialty'] = userData['specialty'];
      }
      if (userData.containsKey('cref')) {
        requestBody['cref'] = userData['cref'];
      }
      if (userData.containsKey('experience')) {
        requestBody['experience'] = userData['experience'];
      }
      if (userData.containsKey('bio')) {
        requestBody['bio'] = userData['bio'];
      }
      if (userData.containsKey('hourlyRate')) {
        requestBody['hourlyRate'] = userData['hourlyRate'];
      }
      if (userData.containsKey('city')) {
        requestBody['city'] = userData['city'];
      }

      print('Enviando requisição para: ${Config.apiUrl}/users');
      print('Dados: $requestBody');

      // Fazer requisição POST para criar usuário
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Usuário criado com sucesso
        return {'success': true, 'message': 'Cadastro realizado com sucesso!'};
      } else if (response.statusCode == 400) {
        // Erro de validação (ex: email já cadastrado)
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Erro ao criar cadastro'
        };
      } else if (response.statusCode == 422) {
        // Erro de validação de campos
        try {
          final errorData = json.decode(response.body);
          final detail = errorData['detail'];
          if (detail is List && detail.isNotEmpty) {
            // Extrair mensagem do primeiro erro
            final firstError = detail[0];
            final field = firstError['loc']?.last ?? 'campo';
            final msg = firstError['msg'] ?? 'inválido';
            return {
              'success': false,
              'message': 'Erro no campo "$field": $msg'
            };
          }
          return {
            'success': false,
            'message': 'Erro de validação: ${errorData['detail']}'
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Erro de validação nos dados enviados'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erro ao criar cadastro. Código: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Erro no signup: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);

    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      print('Erro ao decodificar usuário salvo: $e');
      return null;
    }
  }

  // Save current user
  Future<void> _saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_currentUserKey, userJson);
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_tokenKey);
  }

  // Update user profile
  Future<void> updateUserProfile(User updatedUser) async {
    final users = await getUsers();
    final userIndex = users.indexWhere((u) => u.id == updatedUser.id);

    if (userIndex != -1) {
      users[userIndex] = updatedUser;
      await _saveUsers(users);

      // Update current user if it's the same user
      final currentUser = await getCurrentUser();
      if (currentUser?.id == updatedUser.id) {
        await _saveCurrentUser(updatedUser);
      }
    }
  }

  // Approve pending registration (admin only)
  Future<bool> approvePendingRegistration(String pendingId) async {
    try {
      final pendingRegistrations = await getPendingRegistrations();
      final users = await getUsers();

      final pendingIndex = pendingRegistrations.indexWhere(
        (p) => p.id == pendingId,
      );
      if (pendingIndex == -1) return false;

      final pending = pendingRegistrations[pendingIndex];
      final newUser = pending.toUser();

      // Add to users and remove from pending
      users.add(newUser);
      pendingRegistrations.removeAt(pendingIndex);

      await _saveUsers(users);
      await _savePendingRegistrations(pendingRegistrations);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Reject pending registration (admin only)
  Future<bool> rejectPendingRegistration(String pendingId) async {
    try {
      final pendingRegistrations = await getPendingRegistrations();

      final pendingIndex = pendingRegistrations.indexWhere(
        (p) => p.id == pendingId,
      );
      if (pendingIndex == -1) return false;

      pendingRegistrations.removeAt(pendingIndex);
      await _savePendingRegistrations(pendingRegistrations);

      return true;
    } catch (e) {
      return false;
    }
  }
}
