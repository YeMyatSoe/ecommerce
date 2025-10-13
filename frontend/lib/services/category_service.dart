import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/store/';

  // Fetch categories
  Future<List<dynamic>> fetchCategories() async {
    final response = await http.get(Uri.parse('${baseUrl}categories/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
