import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/user.dart';

class TrainerService {
  /// Busca todos os personal trainers aprovados
  Future<List<User>> getApprovedTrainers() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/trainers/approved'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          // Mapear role para UserType
          UserType userType = UserType.trainer;
          final roleName = json['role']['name'] as String;
          if (roleName == 'personal') {
            userType = UserType.trainer;
          }

          return User(
            id: json['id'].toString(),
            email: json['email'] as String,
            name: json['full_name'] as String? ?? 'Personal Trainer',
            userType: userType,
            approved: json['approved'] as bool? ?? false,
            // Campos específicos de trainer viriam aqui se existissem
          );
        }).toList();
      } else {
        print('Erro ao buscar trainers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erro ao buscar trainers: $e');
      return [];
    }
  }

  /// Busca trainers por nome ou cidade
  Future<List<User>> searchTrainers(String query) async {
    try {
      final trainers = await getApprovedTrainers();
      
      if (query.isEmpty) {
        return trainers;
      }

      // Filtrar por nome (pode adicionar mais campos no futuro)
      return trainers.where((trainer) {
        return trainer.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Erro ao buscar trainers: $e');
      return [];
    }
  }
}
