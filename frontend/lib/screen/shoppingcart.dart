// shopping_cart_screen.dart
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/model/productcolor.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/provider/auth_provider.dart';
import 'package:frontend/provider/cart_provider.dart';
import 'package:frontend/screen/checkout.dart';
import 'package:frontend/screen/product_detail.dart';
import 'package:frontend/services/prodct_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:ui'; // 👈 Needed for BackdropFilter
class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  _ShoppingCartScreenState createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  TextEditingController promoCodeController = TextEditingController();
  String? promoCodeMessage;
  List<Product> products = [];
  bool _isDataFetched = false;

  @override
  void initState() {
    super.initState();
    // ✅ Use the CartProvider to load the cart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadCartFromBackend();
    });
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_isDataFetched) return;
    try {
      final productService = ProductService();
      final fetchedProducts = await productService.fetchProducts();
      setState(() {
        products = fetchedProducts;
        _isDataFetched = true;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() => _isDataFetched = true);
    }
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _navigateToCheckOut() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutPage()),
    );
  }
  
  // 🔹 Show SnackBar message
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Consumer is the key. It rebuilds the widget when CartProvider notifies.
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        // We no longer need _isLoading because the provider handles the state.
        if (cartProvider.cartItems.isEmpty) {
          // If the provider's list is empty, show the empty cart message.
          return _buildScaffold(_emptyCartWidget());
        }

        // Use the cartProvider's data directly
        final cartItems = cartProvider.cartItems;
        return _buildScaffold(
          Column(
            children: [
              _cartItemsList(cartItems, cartProvider),
              Divider(color: Colors.grey[300], thickness: 1),
              _promoCodeSection(cartProvider),
              SizedBox(height: 20),
              _checkoutButton(),
              SizedBox(height: 20),
              _recommendProduct("Recommended Items"),
              SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScaffold(Widget bodyContent) {
    return Scaffold(
      backgroundColor: Colors.blue, // background
      appBar: AppBar(
        title: Text('Shopping Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: bodyContent,
          ),
        ),
      ),
    );
  }

  Widget _emptyCartWidget() {
    return Column(
      children: [
        Icon(Icons.shopping_cart_outlined, size: 50, color: Colors.grey),
        SizedBox(height: 20),
        Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/products'),
          child: Text('Browse Products'),
        ),
      ],
    );
  }

  Widget _cartItemsList(List<CartItem> items, CartProvider cartProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        CartItem cartItem = items[index];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    cartItem.product.image1,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 15),

                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cartItem.product.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      // Text('Price: \$${cartItem.product.finalPrice}'),
                      // Text('Brand: ${cartItem.product.brand}'),
                      if (cartItem.selectedColor != null) ...[
                        // SizedBox(height: 5),
                        // Text('Color: ${cartItem.selectedColor!.colorName}'),
                        SizedBox(height: 5),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(int.parse(
                                '0xFF${cartItem.selectedColor!.colorCode.replaceAll("#", "")}')),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      // Quantity controls
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () async {
                              await cartProvider.decrementQuantity(cartItem);
                              _showMessage("Quantity decremented!");
                            },
                          ),
                          Text('${cartItem.quantity}'),
                          IconButton(
                            icon: Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () async {
                              await cartProvider.incrementQuantity(cartItem);
                              _showMessage("Quantity incremented!");
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Total price & delete
                Column(
                  children: [
                    Text('\$${cartItem.totalPrice}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await cartProvider.removeFromCart(cartItem);
                        _showMessage("Item removed!");
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _promoCodeSection(CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Apply Promo Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 10),
        TextField(
          controller: promoCodeController,
          decoration: InputDecoration(
            hintText: 'Enter promo code',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          ),
          onSubmitted: (value) {
            cartProvider.applyPromoCode(value);
            if (cartProvider.discount > 0) {
              _showMessage("Promo code applied!", isError: false);
            } else {
              _showMessage("Invalid promo code.", isError: true);
            }
          },
        ),
      ],
    );
  }

  Widget _checkoutButton() {
    return ElevatedButton(
      onPressed: _navigateToCheckOut,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      child: Text('Checkout', style: TextStyle(fontSize: 16)),
    );
  }



  Widget _recommendProduct(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Carousel
        LayoutBuilder(
          builder: (context, constraints) {
            double viewportFraction = 0.9;
            if (constraints.maxWidth > 1200) viewportFraction = 0.22;
            else if (constraints.maxWidth > 800) viewportFraction = 0.3;
            else if (constraints.maxWidth > 600) viewportFraction = 0.45;

            return CarouselSlider.builder(
              itemCount: products.length,
              itemBuilder: (context, index, realIndex) {
                final product = products[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildLiquidGlassCard(product), // 👈 using your new style
                );
              },
              options: CarouselOptions(
                height: 300,
                enlargeCenterPage: true,
                viewportFraction: viewportFraction,
                enableInfiniteScroll: true,
              ),
            );
          },
        ),
      ],
    );
  }

// ------------------ LIQUID GLASS CARD ------------------
  Widget _buildLiquidGlassCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      product.image1, // 👈 switched to image2
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Product Info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "\$${product.finalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

}