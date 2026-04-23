import 'dart:convert';
import 'package:http/http.dart' as http;

class BinLevelService {
  // 10.0.2.2 is the special alias for the host loopback (your laptop) in Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5000';

  static Future<Map<String, dynamic>> fetchLevels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_levels'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load bin levels');
      }
    } catch (e) {
      print('Error fetching bin levels: $e');
      return {'plastic': 0, 'paper': 0, 'warnings': []};
    }
  }
}
