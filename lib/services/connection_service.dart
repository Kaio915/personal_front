import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

enum ConnectionStatusEnum {
  pending,
  accepted,
  rejected;

  String toJson() => name;

  static ConnectionStatusEnum fromJson(String json) {
    return ConnectionStatusEnum.values.firstWhere((e) => e.name == json);
  }
}

class ConnectionModel {
  final int id;
  final int studentId;
  final int trainerId;
  final ConnectionStatusEnum status;

  ConnectionModel({
    required this.id,
    required this.studentId,
    required this.trainerId,
    required this.status,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      trainerId: json['trainer_id'] as int,
      status: ConnectionStatusEnum.fromJson(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'trainer_id': trainerId,
      'status': status.toJson(),
    };
  }
}

class ConnectionService {
  /// Cria uma nova solicitação de conexão
  Future<bool> createConnection(int studentId, int trainerId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/connections/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'trainer_id': trainerId,
        }),
      );

      print('Create connection status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Erro ao criar conexão: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro ao criar conexão: $e');
      return false;
    }
  }

  /// Busca conexões pendentes de um personal trainer
  Future<List<ConnectionModel>> getTrainerPendingConnections(int trainerId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/connections/trainer/$trainerId/pending'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ConnectionModel.fromJson(json)).toList();
      } else {
        print('Erro ao buscar conexões pendentes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erro ao buscar conexões pendentes: $e');
      return [];
    }
  }

  /// Busca todas as conexões de um personal trainer
  Future<List<ConnectionModel>> getTrainerConnections(int trainerId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/connections/trainer/$trainerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ConnectionModel.fromJson(json)).toList();
      } else {
        print('Erro ao buscar conexões: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erro ao buscar conexões: $e');
      return [];
    }
  }

  /// Busca todas as conexões de um aluno
  Future<List<ConnectionModel>> getStudentConnections(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/connections/student/$studentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ConnectionModel.fromJson(json)).toList();
      } else {
        print('Erro ao buscar conexões: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erro ao buscar conexões: $e');
      return [];
    }
  }

  /// Atualiza o status de uma conexão (aceitar/rejeitar)
  Future<bool> updateConnectionStatus(int connectionId, ConnectionStatusEnum status) async {
    try {
      final response = await http.patch(
        Uri.parse('${Config.apiUrl}/connections/$connectionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao atualizar conexão: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro ao atualizar conexão: $e');
      return false;
    }
  }

  /// Remove uma conexão
  Future<bool> deleteConnection(int connectionId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.apiUrl}/connections/$connectionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao deletar conexão: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro ao deletar conexão: $e');
      return false;
    }
  }
}
