import 'package:flutter/foundation.dart';
import '../models/connection.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class ConnectionProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  List<Connection> _connections = [];
  List<User> _trainers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Connection> get connections => _connections;
  List<User> get trainers => _trainers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize
  Future<void> initialize() async {
    await loadTrainers();
  }

  // Load all connections (deprecated - usando novo sistema)
  Future<void> loadConnections() async {
    // Este método não faz nada agora pois as conexões são carregadas diretamente nas telas
    _isLoading = false;
    notifyListeners();
  }

  // Load all trainers
  Future<void> loadTrainers() async {
    try {
      final users = await _authService.getUsers();
      _trainers = users.where((user) => user.isTrainer && user.approved == true).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar personal trainers: $e';
      notifyListeners();
    }
  }

  // Get connections for a specific student (mantido por compatibilidade mas retorna lista vazia)
  List<Connection> getStudentConnections(String studentId) {
    return [];
  }

  // Get connections for a specific trainer (mantido por compatibilidade mas retorna lista vazia)
  List<Connection> getTrainerConnections(String trainerId) {
    return [];
  }

  // Get connected trainer for a student (mantido por compatibilidade mas retorna null)
  User? getConnectedTrainer(String studentId) {
    return null;
  }

  // Get connected students for a trainer (mantido por compatibilidade mas retorna lista vazia)
  Future<List<User>> getConnectedStudents(String trainerId) async {
    return [];
  }

  // Search trainers
  List<User> searchTrainers({
    required String query,
    required String searchType, // 'name' or 'city'
  }) {
    if (query.trim().isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    
    return _trainers.where((trainer) {
      if (searchType == 'city') {
        return trainer.city?.toLowerCase().contains(lowercaseQuery) ?? false;
      } else {
        // Search by name or specialty
        final nameMatch = trainer.name.toLowerCase().contains(lowercaseQuery);
        final specialtyMatch = trainer.specialty?.toLowerCase().contains(lowercaseQuery) ?? false;
        return nameMatch || specialtyMatch;
      }
    }).toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
