// cart_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/model/brand.dart';
import 'package:frontend/model/productcolor.dart';
import 'package:frontend/model/productsize.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/model/products.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  final String apiUrl = 'http://10.0.2.2:8000/api/store/getcart/';
  String _userId = '';
  double _discount = 0.0;
  final _storage = FlutterSecureStorage();

  List<CartItem> get cartItems => _cartItems;

  int get totalQuantity =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice) - _discount;

  double get discount => _discount;

  Future<void> setUserId(String userId) async {
    _userId = userId;
    await loadCartFromBackend();
  }

  void applyPromoCode(String promoCode) {
    if (promoCode == "DISCOUNT10") {
      _discount = totalPrice * 0.10;
    } else if (promoCode == "DISCOUNT20") {
      _discount = totalPrice * 0.20;
    } else {
      _discount = 0.0;
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _discount = 0.0;
    notifyListeners();
  }

  /// Load the cart from backend
  Future<void> loadCartFromBackend() async {
    final token = await _storage.read(key: 'auth_token');
    final userId = await _storage.read(key: 'user_id');
    if (token == null || userId == null) return;

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print("Failed to load cart: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);
      if (data is! Map || data['cart_items'] == null) return;

      final List<CartItem> cartItemsList = [];
      for (var item in data['cart_items']) {
        try {
          CartItem cartItem = await CartItem.fromJson(item); // supports color & size
          cartItemsList.add(cartItem);
        } catch (e) {
          print("Error parsing cart item: $e");
        }
      }

      _cartItems = cartItemsList;
      notifyListeners();
    } catch (e) {
      print("Error loading cart: $e");
    }
  }

  /// Add item to cart (merged version)
  Future<void> addToCart(CartItem newItem, String token) async {
    String? userId = await _storage.read(key: 'user_id');
    if (userId == null) {
      print("User ID not found in storage.");
      return;
    }

    // Prepare color-size-quantity payload
    List<Map<String, dynamic>> colorSizeQuantities = [];

    if (newItem.selectedColor != null && newItem.selectedSize != null) {
      colorSizeQuantities.add({
        'color_name': newItem.selectedColor!.colorName,
        'size_name': newItem.selectedSize!.name,
        'quantity': newItem.quantity,
      });
    } else {
      print("Cannot add to cart: color or size not selected.");
      return;
    }

    final payload = {
      'product_id': newItem.product.id,
      'color_size_quantities': colorSizeQuantities,
    };
    print("Adding to cart payload: ${json.encode(payload)}");

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/store/cart/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 201) {
        print("Item added to cart successfully.");
        await loadCartFromBackend();
      } else if (response.statusCode == 400) {
        print("Failed to add item: ${response.body}");
      } else {
        print("Unexpected response: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error adding to cart: $e");
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(CartItem cartItem) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/store/cart/remove/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cartItem.toApiJson()), // includes size + color
      );

      if (response.statusCode == 200) {
        await loadCartFromBackend();
      } else {
        print('Failed to remove from cart: ${response.body}');
      }
    } catch (e) {
      print('Error removing from cart: $e');
    }
  }

  /// Increment quantity
  Future<void> incrementQuantity(CartItem cartItem) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/store/cart/increment/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cartItem.toApiJson()), // include size + color
      );

      if (response.statusCode == 200) {
        await loadCartFromBackend();
      } else {
        print('Increment failed: ${response.body}');
      }
    } catch (e) {
      print('Error incrementing quantity: $e');
    }
  }

  /// Decrement quantity
  Future<void> decrementQuantity(CartItem cartItem) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/store/cart/decrement/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cartItem.toApiJson()), // include size + color
      );

      if (response.statusCode == 200) {
        await loadCartFromBackend();
      } else {
        print('Decrement failed: ${response.body}');
      }
    } catch (e) {
      print('Error decrementing quantity: $e');
    }
  }
}
