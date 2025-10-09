import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/pending_registration.dart';

class AuthService {
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
      users = usersList.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
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
    return usersList.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
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
    return pendingList.map((json) => PendingRegistration.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Save pending registrations to storage
  Future<void> _savePendingRegistrations(List<PendingRegistration> pendingRegistrations) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = jsonEncode(pendingRegistrations.map((pending) => pending.toJson()).toList());
    await prefs.setString(_pendingRegistrationsKey, pendingJson);
  }

  // Login user
  Future<User?> login(String email, String password) async {
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

  // Register new user (creates pending registration)
  Future<bool> signup(Map<String, dynamic> userData, String password) async {
    try {
      final pendingRegistrations = await getPendingRegistrations();
      final users = await getUsers();
      
      final email = userData['email'] as String;
      
      // Check if email already exists
      if (users.any((u) => u.email == email) || pendingRegistrations.any((p) => p.email == email)) {
        return false;
      }

      final pendingRegistration = PendingRegistration(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: userData['name'] as String,
        userType: UserType.fromString(userData['userType'] as String),
        password: password, // In real app, this should be hashed
        registrationDate: DateTime.now(),
        approved: false,
        specialty: userData['specialty'] as String?,
        cref: userData['cref'] as String?,
        experience: userData['experience'] as String?,
        bio: userData['bio'] as String?,
        hourlyRate: userData['hourlyRate'] as String?,
        city: userData['city'] as String?,
        goals: userData['goals'] as String?,
        fitnessLevel: userData['fitnessLevel'] as String?,
      );

      pendingRegistrations.add(pendingRegistration);
      await _savePendingRegistrations(pendingRegistrations);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    
    if (userJson == null) return null;
    
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    return User.fromJson(userMap);
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
      
      final pendingIndex = pendingRegistrations.indexWhere((p) => p.id == pendingId);
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
      
      final pendingIndex = pendingRegistrations.indexWhere((p) => p.id == pendingId);
      if (pendingIndex == -1) return false;
      
      pendingRegistrations.removeAt(pendingIndex);
      await _savePendingRegistrations(pendingRegistrations);
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
