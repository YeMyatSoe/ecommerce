import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/provider/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isLoggedIn = false;
  String _userId = ''; // User ID to track the current logged-in user

  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;

  // Login function
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/store/login/'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['access_token'];
        final userId = responseData['user_id'];

        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'auth_token', value: token);
          await _storage.write(key: 'user_id', value: userId.toString());
          await _storage.write(key: 'is_logged_in', value: 'true');

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);

          _userId = userId.toString();
          _isLoggedIn = true;
          notifyListeners(); // Notify listeners about login state change
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print("Error during login: $e");
      return false;
    }
  }

  Future<void> refreshAccessToken(BuildContext context) async {
    try {
      String? refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/api/store/refresh-token/'),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final newAccessToken = responseData['access_token'];

          await _storage.write(key: 'auth_token', value: newAccessToken);
          print('new Token $newAccessToken');
        } else {
          // Handle token refresh failure (e.g., log out the user)
          await logout(context); // Pass context from the widget layer
        }
      }
    } catch (e) {
      print("Error refreshing token: $e");
    }
  }

// Modify the logout function to accept context
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);

    // Delete authentication details from secure storage
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');

    // Reset local variables
    _userId = ''; // Reset user ID on logout
    _isLoggedIn = false;

    // Reset or clear cart items when the user logs out
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Optionally clear the cart items (if needed)
    cartProvider.clearCart(); // You should define clearCart() in CartProvider

    // Notify listeners about the logout state change
    notifyListeners();
  }

  // Check login status
  Future<void> checkLoginStatus() async {
    String? token = await _storage.read(key: 'auth_token');
    _isLoggedIn = token != null && token.isNotEmpty;

    if (_isLoggedIn) {
      _userId = (await _storage.read(key: 'user_id')) ?? '';
    }

    notifyListeners(); // Notify listeners about the login state
  }
}
