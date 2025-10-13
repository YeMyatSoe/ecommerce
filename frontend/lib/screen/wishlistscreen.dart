import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/screen/product_detail.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:ui';

final _storage = FlutterSecureStorage();

class WishlistScreen extends StatefulWidget {
  static const String apiUrl = 'http://10.0.2.2:8000/api/store';
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Product> wishlists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWishlists();
  }

  Future<void> fetchWishlists() async {
    setState(() => isLoading = true);

    String? token = await _storage.read(key: 'auth_token');
    String? userId = await _storage.read(key: 'user_id');

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed.')),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('${WishlistScreen.apiUrl}/wishlists/user/$userId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);

      if (decodedResponse is List) {
        List<Product> updatedWishlists = [];

        for (var wishlist in decodedResponse) {
          if (wishlist is Map && wishlist.containsKey('products')) {
            var products = wishlist['products'];
            if (products is List) {
              for (var productMap in products) {
                if (productMap is Map<String, dynamic>) {
                  updatedWishlists.add(await Product.fromJson(productMap));
                }
              }
            }
          }
        }

        setState(() {
          wishlists = updatedWishlists;
          isLoading = false;
        });
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load wishlists')),
      );
    }
  }

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // background
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Text(
          "Wishlist",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : wishlists.isEmpty
                ? Center(child: Text('No items in your wishlist.'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2;
                      double childAspectRatio = 0.65;

                      if (constraints.maxWidth >= 1200) {
                        crossAxisCount = 4;
                        childAspectRatio = 0.9;
                      } else if (constraints.maxWidth >= 800) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.8;
                      } else if (constraints.maxWidth >= 600) {
                        crossAxisCount = 2;
                        childAspectRatio = 0.7;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: wishlists.length,
                        itemBuilder: (context, index) {
                          var product = wishlists[index];
                          return _buildProductCard(product);
                        },
                      );
                    },
                  ),
      ),
    );
  }
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(context, product),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image + Stock Badge
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          product.image1.isNotEmpty ? product.image1 : 'fallback_image_url',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/placeholder_image.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _getStockStatusColor(product),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStockStatusText(product),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Rating: ${product.rating}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(36),
                    ),
                    onPressed: () => _navigateToProductDetail(context, product),
                    child: const Text(
                      'View',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockStatus(Product product) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: _getStockStatusColor(product),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStockStatusText(product),
        style: TextStyle(
          fontSize: 12.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStockStatusText(Product product) {
    if (product.stock > 1) {
      return "In Stock";
    } else if (product.stock == 1) {
      return "Only 1 Left!";
    } else {
      return "Out of Stock";
    }
  }

  Color _getStockStatusColor(Product product) {
    if (product.stock > 1) {
      return Colors.green;
    } else if (product.stock == 1) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
