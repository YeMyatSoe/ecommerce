import 'package:frontend/model/productsize.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductColor {
  final int? id; // optional
  final String colorName;
  final String colorCode;
  final String imageUrl;
  final int stock; // ✅ add stock
  final List<ProductSize> availableSizes; // ✅ sizes

  ProductColor({
    this.id,
    required this.colorName,
    required this.colorCode,
    required this.imageUrl,
    this.stock = 0, // default 0
    this.availableSizes = const [], // default empty
  });

  static int safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    return value is int ? value : int.tryParse(value.toString()) ?? defaultValue;
  }

  static String safeString(dynamic value, String defaultValue) {
    return value == null ? defaultValue : value.toString();
  }

  // Fetch color by name
  static Future<ProductColor> fromName(String colorName) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/store/colors/by_name/$colorName/'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> colorJson = json.decode(response.body);
      return ProductColor.fromJson(colorJson);
    } else {
      throw Exception('Failed to load color by name');
    }
  }

  static Future<ProductColor> fetchColorDetails(int colorId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/store/colors/$colorId/'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> colorJson = json.decode(response.body);
      return ProductColor.fromJson(colorJson);
    } else {
      throw Exception('Failed to load color details');
    }
  }

  // Fetch all color images for a product
  static Future<List<ProductColor>> fetchProductColors(int productId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/store/products/$productId/color-images/'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ProductColor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load product color images');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color_name': colorName,
      'color_code': colorCode,
      'image_url': imageUrl,
      'stock': stock, // ✅ include stock
      'sizes': availableSizes.map((s) => s.toJson()).toList(),
    };
  }

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    return ProductColor(
      id: json['id'],
      colorName: json['color_name'] ?? 'Unknown',
      colorCode: json['color_code'] ?? '#FFFFFF',
      imageUrl: (json['image'] != null && json['image'].toString().isNotEmpty)
          ? json['image']
          : '',
      stock: json['stock'] != null
          ? int.tryParse(json['stock'].toString()) ?? 0
          : 0, // ✅ parse stock
      availableSizes: (json['sizes'] as List<dynamic>?)
              ?.map((s) => ProductSize.fromJson(s))
              .toList() ??
          [],
    );
  }

  static Future<ProductColor> fromId(int colorId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/store/colors/$colorId/'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> colorJson = json.decode(response.body);
      return ProductColor.fromJson(colorJson);
    } else {
      throw Exception('Failed to load color details for ID: $colorId');
    }
  }

  static defaultColor() {
    return ProductColor(
      colorName: 'Default',
      colorCode: '#FFFFFF',
      imageUrl: '',
      stock: 0,
    );
  }
}
