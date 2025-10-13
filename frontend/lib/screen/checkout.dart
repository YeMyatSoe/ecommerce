import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/provider/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  TextEditingController addressController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController regionController = TextEditingController();
  TextEditingController paymentController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  bool isLoading = false;
  final _storage = FlutterSecureStorage();

  bool cartLoading = true; // ✅ Track cart load state

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    // ✅ Ensure cart is loaded from backend first
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.loadCartFromBackend();
      setState(() {
        cartLoading = false; // ✅ mark cart loaded
      });
    });
  }
  Future<void> _checkLoginStatus() async {
    String? token = await _storage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      try {
        Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
        int expiryTime = decodedToken['exp'];
        DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTime * 1000);

        if (expiryDate.isBefore(DateTime.now())) {
          await _storage.delete(key: 'auth_token');
          setState(() {});
        }
      } catch (e) {
        await _storage.delete(key: 'auth_token');
        setState(() {});
      }
    }
  }
Future<void> _submitOrder() async {
  String? token = await _storage.read(key: 'auth_token');
  String? userId = await _storage.read(key: 'user_id');

  if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }

  final cartProvider = Provider.of<CartProvider>(context, listen: false);

  List<Map<String, dynamic>> items = [];
  for (var cartItem in cartProvider.cartItems) {
    String? colorName = cartItem.selectedColor?.colorName;
    String? sizeName = cartItem.selectedSize?.name;
    int? productId = cartItem.product.id;

    // Validate color selection
    if (colorName == null || colorName.isEmpty || productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a color for all items'))
      );
      return;
    }

    // Validate size if a size is expected
    // Option 2: just check if selectedSize exists
    if (cartItem.selectedSize == null || cartItem.selectedSize!.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a size for ${cartItem.product.name}'))
      );
      return;
    }

    items.add({
      'product_id': productId,
      'color_name': colorName,
      'size_name': sizeName ?? '',
      'quantity': cartItem.quantity,
    });
  }

  if (items.isEmpty) {
    print("No valid items to submit");
    return;
  }

  final orderItemData = {
    'user_id': userId,
    'color_size_quantities': items, // backend expects this key
  };

  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/store/orders/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(orderItemData),
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Order successfully submitted.");

      // Delete cart on backend
      await _deleteCart();

      // Clear cart in provider
      cartProvider.clearCart();

      // Navigate back or show order confirmation
      Navigator.pushReplacementNamed(context, '/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit order: ${response.body}'))
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error submitting order. Please try again later.'))
    );
  }
}

  Future<void> _deleteCart() async {
    String? token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) return;

    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/api/store/delete_cart/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        print("Cart deleted successfully.");
      } else {
        print("Failed to delete cart: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error deleting cart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Colors.green.shade600,
        elevation: 4,
      ),
      body: cartLoading
          ? Center(child: CircularProgressIndicator()) // ✅ wait for cart
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Shipping Address'),
                    SizedBox(height: 10),
                    _buildTextField(addressController,
                        'Enter shipping address', Icons.location_on),
                    _buildTextField(
                        phoneController, 'Enter phone number', Icons.phone),
                    _buildTextField(postalCodeController,
                        'Enter postal code', Icons.location_city),
                    _buildTextField(
                        countryController, 'Enter country', Icons.flag),
                    _buildTextField(regionController, 'Enter region', Icons.map),
                    SizedBox(height: 20),

                    _buildSectionTitle('Billing Information'),
                    SizedBox(height: 10),
                    _buildPaymentMethodSelector(),
                    _buildTextField(paymentController,
                        'Enter payment type (e.g., PayPal, Visa, etc.)',
                        Icons.credit_card),
                    SizedBox(height: 20),

                    _buildTextField(
                        discountController, 'Enter discount code', Icons.local_offer),
                    SizedBox(height: 20),

                    _buildCartSummary(cartProvider), // ✅ shows fresh cart

                    if (isLoading) _buildLoadingIndicator(),
                    SizedBox(height: 20),

                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (addressController.text.isEmpty ||
                              phoneController.text.isEmpty ||
                              postalCodeController.text.isEmpty ||
                              countryController.text.isEmpty ||
                              regionController.text.isEmpty ||
                              paymentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Please fill out all fields')));
                          } else {
                            bool confirm = await _showConfirmationDialog();
                            if (confirm) {
                              setState(() => isLoading = true);
                              await _submitOrder();
                              setState(() => isLoading = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                        ),
                        child: Text('Checkout',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade700)),
          filled: true,
          fillColor: Colors.green.shade50,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select payment method',
        prefixIcon: Icon(Icons.payment),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.green.shade50,
      ),
      items: <String>['PayPal', 'ApplePay', 'Visa', 'MasterCard', 'Credit', 'JCB']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          paymentController.text = newValue ?? '';
        });
      },
    );
  }
Widget _buildCartSummary(CartProvider cartProvider) {
  int totalItems = cartProvider.cartItems.fold(0, (sum, item) => sum + item.quantity);

  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Your Items: $totalItems', // Show total quantity
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Total Price: \$${cartProvider.totalPrice.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700)));
  }

  Future<bool> _showConfirmationDialog() async {
    return (await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Order'),
              content: Text('Are you sure you want to place this order?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Confirm')),
              ],
            );
          },
        )) ??
        false;
  }
}
