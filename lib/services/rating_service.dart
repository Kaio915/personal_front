import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class RatingService {
  Future<bool> rateTrainer(int studentId, int trainerId, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/ratings/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trainer_id': trainerId,
          'student_id': studentId,
          'rating': rating,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Erro ao enviar avaliação: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getTrainerRating(int trainerId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/ratings/trainer/$trainerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erro ao buscar avaliação do trainer: $e');
      return null;
    }
  }
}
