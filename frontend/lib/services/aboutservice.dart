import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/about_model.dart';

class AboutService {
  static const String apiUrl = 'http://127.0.0.1:8000/api/store/about/';

  static Future<AboutPageModel> fetchAboutData() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Invalid data format');
      }
      return AboutPageModel.fromJson(data);
    } else {
      throw Exception('Failed to load About page');
    }
  }
}
