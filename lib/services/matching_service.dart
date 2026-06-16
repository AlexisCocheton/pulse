import 'package:http/http.dart' as http;
import 'dart:convert';

class MatchingService {
  static const String _baseUrl = 'http://localhost:8000/api';

  Future<List<Map<String, dynamic>>> getMatchCandidates({
    required String userId,
    required double maxDistance,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/match-candidates?userId=$userId&maxDistance=$maxDistance&limit=$limit',
        ),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = (data['candidates'] as List)
            .map((c) => c as Map<String, dynamic>)
            .toList();
        return candidates;
      } else {
        throw Exception('Failed to load candidates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching candidates: $e');
    }
  }

  Future<double> calculateMatchScore({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/match-quality'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId1': userId1,
          'userId2': userId2,
        }),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['score'] as num).toDouble();
      } else {
        throw Exception('Failed to calculate score: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calculating score: $e');
    }
  }

  Future<void> trackInteraction({
    required String userId,
    required String targetId,
    required String action,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/track-interaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'targetId': targetId,
          'action': action,
        }),
      ).timeout(
        const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error tracking interaction: $e');
    }
  }
}
