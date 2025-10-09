import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection.dart';

class ConnectionService {
  static const String _connectionsKey = 'connections';

  // Get all connections
  Future<List<Connection>> getConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final connectionsJson = prefs.getString(_connectionsKey);
    
    if (connectionsJson == null) return [];
    
    final connectionsList = jsonDecode(connectionsJson) as List;
    return connectionsList.map((json) => Connection.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Save connections to storage
  Future<void> _saveConnections(List<Connection> connections) async {
    final prefs = await SharedPreferences.getInstance();
    final connectionsJson = jsonEncode(connections.map((conn) => conn.toJson()).toList());
    await prefs.setString(_connectionsKey, connectionsJson);
  }

  // Send connection request from student to trainer
  Future<bool> sendConnectionRequest({
    required String trainerId,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    try {
      final connections = await getConnections();
      
      // Check if connection already exists
      final existingConnection = connections.where((conn) => 
        conn.trainerId == trainerId && conn.studentId == studentId
      ).firstOrNull;
      
      if (existingConnection != null) {
        return false; // Connection already exists
      }

      final newConnection = Connection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        trainerId: trainerId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        status: ConnectionStatus.pending,
        createdAt: DateTime.now(),
      );

      connections.add(newConnection);
      await _saveConnections(connections);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Accept connection request (trainer only)
  Future<bool> acceptConnectionRequest(String connectionId) async {
    try {
      final connections = await getConnections();
      final connectionIndex = connections.indexWhere((conn) => conn.id == connectionId);
      
      if (connectionIndex == -1) return false;
      
      final connection = connections[connectionIndex];
      
      // Check if student already has an active connection
      final studentActiveConnection = connections.where((conn) =>
        conn.studentId == connection.studentId && 
        conn.status == ConnectionStatus.accepted
      ).firstOrNull;
      
      if (studentActiveConnection != null) {
        return false; // Student already has an active connection
      }

      final updatedConnection = connection.copyWith(
        status: ConnectionStatus.accepted,
        respondedAt: DateTime.now(),
      );

      connections[connectionIndex] = updatedConnection;
      await _saveConnections(connections);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Reject connection request (trainer only)
  Future<bool> rejectConnectionRequest(String connectionId) async {
    try {
      final connections = await getConnections();
      final connectionIndex = connections.indexWhere((conn) => conn.id == connectionId);
      
      if (connectionIndex == -1) return false;
      
      final connection = connections[connectionIndex];
      final updatedConnection = connection.copyWith(
        status: ConnectionStatus.rejected,
        respondedAt: DateTime.now(),
      );

      connections[connectionIndex] = updatedConnection;
      await _saveConnections(connections);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Disconnect connection (student or trainer)
  Future<bool> disconnectConnection(String studentId, String trainerId) async {
    try {
      final connections = await getConnections();
      final connectionIndex = connections.indexWhere((conn) =>
        conn.studentId == studentId && 
        conn.trainerId == trainerId &&
        conn.status == ConnectionStatus.accepted
      );
      
      if (connectionIndex == -1) return false;
      
      connections.removeAt(connectionIndex);
      await _saveConnections(connections);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get connections for a specific student
  Future<List<Connection>> getStudentConnections(String studentId) async {
    final connections = await getConnections();
    return connections.where((conn) => conn.studentId == studentId).toList();
  }

  // Get connections for a specific trainer
  Future<List<Connection>> getTrainerConnections(String trainerId) async {
    final connections = await getConnections();
    return connections.where((conn) => conn.trainerId == trainerId).toList();
  }

  // Get connected trainer for a student (if any)
  Future<String?> getConnectedTrainerId(String studentId) async {
    final connections = await getConnections();
    final activeConnection = connections.where((conn) =>
      conn.studentId == studentId && 
      conn.status == ConnectionStatus.accepted
    ).firstOrNull;
    
    return activeConnection?.trainerId;
  }

  // Get connected students for a trainer
  Future<List<String>> getConnectedStudentIds(String trainerId) async {
    final connections = await getConnections();
    return connections.where((conn) =>
      conn.trainerId == trainerId && 
      conn.status == ConnectionStatus.accepted
    ).map((conn) => conn.studentId).toList();
  }

  // Rate trainer (student only)
  Future<bool> rateTrainer(String studentId, String trainerId, int rating) async {
    try {
      final connections = await getConnections();
      final connectionIndex = connections.indexWhere((conn) =>
        conn.studentId == studentId && 
        conn.trainerId == trainerId &&
        conn.status == ConnectionStatus.accepted
      );
      
      if (connectionIndex == -1) return false;
      
      final connection = connections[connectionIndex];
      final updatedConnection = connection.copyWith(rating: rating);

      connections[connectionIndex] = updatedConnection;
      await _saveConnections(connections);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get average rating for a trainer
  Future<double> getTrainerAverageRating(String trainerId) async {
    final connections = await getConnections();
    final ratedConnections = connections.where((conn) =>
      conn.trainerId == trainerId && 
      conn.status == ConnectionStatus.accepted &&
      conn.rating != null
    ).toList();
    
    if (ratedConnections.isEmpty) return 0.0;
    
    final totalRating = ratedConnections.fold<int>(0, (sum, conn) => sum + (conn.rating ?? 0));
    return totalRating / ratedConnections.length;
  }
}
