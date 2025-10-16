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
  int _activeIndex = 0; // Active carousel index
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
            _recommendProduct("Recommended", products),
            SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScaffold(Widget bodyContent) {
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
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: bodyContent,
          ),
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
// Refactored Row content using Spacer for controlled, equal gaps
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // === 1. LEFT: Product Image ===
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    cartItem.product.image1,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),

                // **KEY CHANGE:** Explicit Spacer (Gap 1)
                // Uses 1/4 of the available remaining space for the first gap
                Spacer(flex: 2),

                // === 2. CENTER: Product Details, Color & Quantity Controls (Expanded) ===
                Expanded(
                  // We keep Expanded here to ensure the name and details wrap nicely,
                  // but the use of Spacer(flex: 1) before and after controls the
                  // horizontal space around this block.
                  flex: 5, // Give the content block most of the remaining flexible space
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Product Name
                      Text(
                        cartItem.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),

                      SizedBox(height: 4),

                      // Color Indicator
                      if (cartItem.selectedColor != null) ...[
                        Row(
                          children: [
                            Text(
                              'Color:',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            SizedBox(width: 5),
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Color(int.parse(
                                    '0xFF${cartItem.selectedColor!.colorCode.replaceAll("#", "")}')),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],

                      // Quantity Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () async {
                              await cartProvider.decrementQuantity(cartItem);
                              // _showMessage("Quantity decremented!");
                            },
                            child: Icon(Icons.remove_circle_outline, color: Colors.red, size: 16),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${cartItem.quantity}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await cartProvider.incrementQuantity(cartItem);
                              // _showMessage("Quantity incremented!");
                            },
                            child: Icon(Icons.add_circle_outline, color: Colors.green, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // **KEY CHANGE:** Explicit Spacer (Gap 2)
                // Uses 1/4 of the available remaining space for the second gap
                Spacer(flex: 1),

                // === 3. RIGHT: Total Price & Delete Button ===
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Total Price
                    Text(
                      '\$${cartItem.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    // Delete Button
                    InkWell(
                      onTap: () async {
                        await cartProvider.removeFromCart(cartItem);
                        // _showMessage("Item removed!");
                      },
                      child: Icon(Icons.delete_forever, color: Colors.red.shade600, size: 26),
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



  Widget _recommendProduct(String title, List<Product> items) {
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
              itemCount: items.length,
              itemBuilder: (context, index, realIndex) {
                double diff = (index - _activeIndex).toDouble();

                // Smooth vertical movement
                double verticalOffset = 20 * diff.abs();
                double scale = 1.0 - (0.1 * diff.abs());
                double opacity = 1.0 - (0.5 * diff.abs());

                scale = scale.clamp(0.8, 5.0);
                opacity = opacity.clamp(0.3, 5.0);
                verticalOffset = verticalOffset.clamp(0.0, 20.0);

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(4, verticalOffset),
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: _buildLiquidGlassCard(items[index]),
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: 260,
                viewportFraction: 0.6,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  setState(() => _activeIndex = index);
                },
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