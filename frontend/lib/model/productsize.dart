import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductSize {
  final int id;
  final String name;
  final int stock;

  ProductSize({
    required this.id,
    required this.name,
    required this.stock,
  });

  /// Factory that tolerates different JSON shapes
  factory ProductSize.fromJson(Map<String, dynamic> json) {
    // API might use 'size_name' or 'name' — handle both.
    final nameValue = json['size_name'] ?? json['name'] ?? json['size'] ?? '';
    return ProductSize(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: nameValue.toString(),
      stock: json['stock'] is int
          ? json['stock']
          : int.tryParse(json['stock'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'size_name': name,
      'stock': stock,
    };
  }

  // Update this base URL if your API host is different
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const String _sizesPath = '/api/store/sizes/';

  /// Fetch a size by id from the backend. Throws on failure.
  static Future<ProductSize> fromId(int id) async {
    final uri = Uri.parse('$_baseUrl$_sizesPath$id/');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ProductSize.fromJson(data);
    } else {
      throw Exception(
          'Failed to fetch size by id ($id): ${response.statusCode}');
    }
  }

  /// Attempt to fetch a size by name. Tries `?name=` then falls back to `?search=` if needed.
  /// Expects either an object or a list response; returns the first match if it's a list.
  static Future<ProductSize> fromName(String name) async {
    // try ?name= query
    var uri =
        Uri.parse('$_baseUrl$_sizesPath?name=${Uri.encodeComponent(name)}');
    var response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty) {
        return ProductSize.fromJson(decoded[0]);
      } else if (decoded is Map<String, dynamic>) {
        return ProductSize.fromJson(decoded);
      }
    }

    // fallback to ?search=
    uri = Uri.parse('$_baseUrl$_sizesPath?search=${Uri.encodeComponent(name)}');
    response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty) {
        return ProductSize.fromJson(decoded[0]);
      } else if (decoded is Map<String, dynamic>) {
        return ProductSize.fromJson(decoded);
      }
    }

    throw Exception('Size not found with name "$name" (status codes tried).');
  }

  /// Safe variants that return null instead of throwing
  static Future<ProductSize?> tryFromId(int id) async {
    try {
      return await fromId(id);
    } catch (e) {
      // optionally print/log
      print('tryFromId failed: $e');
      return null;
    }
  }

  static Future<ProductSize?> tryFromName(String name) async {
    try {
      return await fromName(name);
    } catch (e) {
      print('tryFromName failed: $e');
      return null;
    }
  }
}
