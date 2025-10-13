import 'package:flutter/material.dart';
import 'package:frontend/model/products.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WishlistProvider with ChangeNotifier {
  Future<void> addToWishlist(Product product, String token) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/store/wishlists/'); // API URL
    
    final body = json.encode({
      'name': 'My Wishlist', // You can customize the name
      'description': 'A list of my favorite products',
      'products': [product.id],  // Sending the product ID
    });

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Pass the authentication token
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        print('Product added to wishlist');
        notifyListeners();  // Update UI or trigger any needed actions
      } else {
        throw Exception('Failed to add to wishlist: ${response.statusCode}');
      }
    } catch (error) {
      print('Error adding to wishlist: $error');
      throw error; // Rethrow to handle in UI
    }
  }
}
