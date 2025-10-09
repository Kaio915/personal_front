import 'package:flutter/foundation.dart';
import '../models/connection.dart';
import '../models/user.dart';
import '../services/connection_service.dart';
import '../services/auth_service.dart';

class ConnectionProvider with ChangeNotifier {
  final ConnectionService _connectionService = ConnectionService();
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
    await loadConnections();
    await loadTrainers();
  }

  // Load all connections
  Future<void> loadConnections() async {
    _isLoading = true;
    notifyListeners();

    try {
      _connections = await _connectionService.getConnections();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar conexões: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  // Get connections for a specific student
  List<Connection> getStudentConnections(String studentId) {
    return _connections.where((conn) => conn.studentId == studentId).toList();
  }

  // Get connections for a specific trainer
  List<Connection> getTrainerConnections(String trainerId) {
    return _connections.where((conn) => conn.trainerId == trainerId).toList();
  }

  // Get connected trainer for a student
  User? getConnectedTrainer(String studentId) {
    final activeConnection = _connections.where((conn) =>
      conn.studentId == studentId && 
      conn.status == ConnectionStatus.accepted
    ).firstOrNull;
    
    if (activeConnection == null) return null;
    
    return _trainers.where((trainer) => trainer.id == activeConnection.trainerId).firstOrNull;
  }

  // Get connected students for a trainer
  Future<List<User>> getConnectedStudents(String trainerId) async {
    final activeConnections = _connections.where((conn) =>
      conn.trainerId == trainerId && 
      conn.status == ConnectionStatus.accepted
    ).toList();
    
    final users = await _authService.getUsers();
    final students = <User>[];
    
    for (final connection in activeConnections) {
      final student = users.where((user) => user.id == connection.studentId).firstOrNull;
      if (student != null) {
        students.add(student);
      }
    }
    
    return students;
  }

  // Send connection request
  Future<bool> sendConnectionRequest({
    required String trainerId,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _connectionService.sendConnectionRequest(
        trainerId: trainerId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
      );
      
      if (success) {
        await loadConnections(); // Refresh connections
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao enviar solicitação de conexão';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao enviar solicitação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Accept connection request
  Future<bool> acceptConnectionRequest(String connectionId) async {
    try {
      final success = await _connectionService.acceptConnectionRequest(connectionId);
      
      if (success) {
        await loadConnections(); // Refresh connections
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao aceitar solicitação';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao aceitar solicitação: $e';
      notifyListeners();
      return false;
    }
  }

  // Reject connection request
  Future<bool> rejectConnectionRequest(String connectionId) async {
    try {
      final success = await _connectionService.rejectConnectionRequest(connectionId);
      
      if (success) {
        await loadConnections(); // Refresh connections
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao rejeitar solicitação';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao rejeitar solicitação: $e';
      notifyListeners();
      return false;
    }
  }

  // Disconnect connection
  Future<bool> disconnectConnection(String studentId, String trainerId) async {
    try {
      final success = await _connectionService.disconnectConnection(studentId, trainerId);
      
      if (success) {
        await loadConnections(); // Refresh connections
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao desconectar';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao desconectar: $e';
      notifyListeners();
      return false;
    }
  }

  // Rate trainer
  Future<bool> rateTrainer(String studentId, String trainerId, int rating) async {
    try {
      final success = await _connectionService.rateTrainer(studentId, trainerId, rating);
      
      if (success) {
        await loadConnections(); // Refresh connections
        _errorMessage = null;
      } else {
        _errorMessage = 'Erro ao avaliar personal trainer';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Erro ao avaliar: $e';
      notifyListeners();
      return false;
    }
  }

  // Get trainer average rating
  Future<double> getTrainerAverageRating(String trainerId) async {
    try {
      return await _connectionService.getTrainerAverageRating(trainerId);
    } catch (e) {
      return 0.0;
    }
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
