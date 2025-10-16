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
        backgroundColor: Colors.transparent, // let gradient show
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A11CB), // deep purple
                Color(0xFF2575FC), // blue mix
              ],
            ),
          ),
      child: SafeArea(

        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : wishlists.isEmpty
                ? Center(child: Text('No items in your wishlist.'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2;
                      double childAspectRatio = 0.65;

                      if (constraints.maxWidth >= 1200) {
                        crossAxisCount = 6;
                        childAspectRatio = 0.8;
                      } else if (constraints.maxWidth >= 800) {
                        crossAxisCount = 6;
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
    ),
    );
  }
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(context, product),
      child: _buildLiquidGlass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      product.image1,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(
                          child: Icon(Icons.broken_image, size: 50)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.stock > 0 ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.stock > 0 ? "In Stock" : "Out of Stock",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
              child: Text(
                "\$${product.finalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
              child: Text(
                "Rating: ${product.rating}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildLiquidGlass({required Widget child, double borderRadius = 16}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
          child: child,
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
