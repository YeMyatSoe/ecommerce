import 'dart:convert'; // To parse JSON responses
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/model/productcolor.dart';
import 'package:frontend/model/productsize.dart';
import 'package:frontend/model/review_form.dart';
import 'package:frontend/provider/cart_provider.dart';
import 'package:frontend/provider/wishlist_provider.dart';
import 'package:frontend/screen/login.dart';
import 'package:frontend/screen/shoppingcart.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:frontend/services/prodct_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:ui';
final storage = FlutterSecureStorage();

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

bool _isExpanded = false;
bool isRefreshing = false; // Prevent multiple token refresh attempts

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _firstProduct;
  Product? _secondProduct;
  List<Product> _relatedAccessories = [];
  bool _showDetails = false;
  late int _quantity;
  List<ProductColor> _productColors = [];
  ProductColor? _selectedColor;
  List<ProductSize> _productSizes = [];   // Update dynamically based on color
ProductSize? _selectedSize;

  late String _currentImage;
  num _rating = 0;
  bool _isLoggedIn = false;
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _nameController =
      TextEditingController(); // User's name for review
  List<Product> _relatedProducts = [];
  final ProductService _productService = ProductService();
  List<Review> _reviews = [];
// Flag to track expanded replies
  final _storage = FlutterSecureStorage(); // For storing access tokens securely

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Fix: Call this method with parentheses
    _quantity = 0; // Default quantity
    _currentImage = widget.product.image1;
    _fetchRelatedProducts(); // Fetch related products based on the category
    _fetchRelatedAccessories(); // Updated function name
    _fetchReviews();
    _loadLikedState();
    _loadUserData();
    loadProductColors(widget.product.id);
  }

  Future<void> _loadUserData() async {
    String? userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      // Set userId and load cart items
      CartProvider cartProvider =
          Provider.of<CartProvider>(context, listen: false);
      await cartProvider.setUserId(userId);
    }
  }

  // Convert color code string to actual Color object
  Color _getColorFromCode(String colorCode) {
    try {
      if (colorCode.isNotEmpty) {
        if (!colorCode.startsWith('#')) {
          colorCode = '#' + colorCode;
        }
        if (colorCode.length == 7) {
          return Color(int.parse('0xFF' + colorCode.replaceFirst('#', '')));
        } else {
          return const Color.fromARGB(255, 5, 252, 26); // Default color (green)
        }
      }
    } catch (e) {
      return const Color.fromARGB(
          255, 207, 39, 39); // Default error color (red)
    }
    return const Color.fromARGB(255, 47, 4, 241); // Default color (blue)
  }

  Future<void> _checkLoginStatus() async {
    String? token = await _storage.read(key: 'auth_token');
    print('token in detail $token');
    if (token != null && token.isNotEmpty) {
      // Decode JWT token to check expiration date (if you're using JWT)
      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      int expiryTime = decodedToken['exp'];
      DateTime expiryDate =
          DateTime.fromMillisecondsSinceEpoch(expiryTime * 1000);

      // If the token has expired, log the user out
      if (expiryDate.isBefore(DateTime.now())) {
        await _storage.delete(key: 'auth_token');
        setState(() {
          _isLoggedIn = false;
        });
        print('Token has expired. Please log in again.');
      } else {
        setState(() {
          _isLoggedIn = true; // Token is valid, so the user is logged in
        });
      }
    } else {
      setState(() {
        _isLoggedIn = false; // No token found, user is not logged in
      });
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8000/api/store/products/${widget.product.id}/reviews/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> reviewJson = json.decode(response.body);
        setState(() {
          _reviews = reviewJson.map((json) => Review.fromJson(json)).toList();
        });
      } else {
        print("Failed to load reviews. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  Future<void> _submitReview() async {
    String? token = await _storage.read(key: 'auth_token');

    if (_reviewController.text.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      final newReview = {
        'rating': _rating.toDouble(),
        'comment': _reviewController.text,
      };

      try {
        final response = await http.post(
          Uri.parse(
              'http://10.0.2.2:8000/api/store/product/${widget.product.id}/reviews/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', // Add token to headers
          },
          body: json.encode(newReview),
        );

        if (response.statusCode == 201) {
          print("Review submitted!");
          _fetchReviews(); // Reload reviews after submission
          _nameController.clear();
          _reviewController.clear();
        } else if (response.statusCode == 401) {
          // Token might be expired, prompt the user to log in again
          print("Unauthorized: Please log in again.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Session expired. Please log in again.")),
          );
          // Optionally, redirect the user to the login page
          Navigator.pushNamed(context, '/login');
        } else {
          print("Failed to submit review. Status code: ${response.statusCode}");
        }
      } catch (e) {
        print("Error submitting review: $e");
      }
    } else {
      print("You must be logged in to submit a review.");
    }
  }

  Future<void> _loadLikedState() async {
    if (!_isLoggedIn) {
      print("You need to be logged in to view or like reviews.");
      return;
    }

    for (var review in _reviews) {
      // Load the 'liked_review_${review.id}' from local storage
      String? hasLikedStr =
          await storage.read(key: 'liked_review_${review.id}');
      String? likeCountStr = await storage.read(key: 'like_count_${review.id}');

      // Check if the review has been liked
      bool? hasLiked = hasLikedStr == 'true';
      int? likeCount = likeCountStr != null ? int.tryParse(likeCountStr) : 0;

      // Apply the loaded values to the review's properties
      setState(() {
        review.hasLiked = hasLiked; // Default to false if null
        review.likes = likeCount ?? 0; // Default to 0 if null
      });
    }
  }

  Future<void> _likeReview(int reviewId, Review review) async {
    String? token = await _storage.read(key: 'auth_token');
    if (!_isLoggedIn || token == null || token.isEmpty) {
      print("You need to be logged in to like a review.");
      return;
    }

    // Update the UI immediately to reflect the like state change
    setState(() {
      review.hasLiked = !review.hasLiked; // Toggle the like state
      review.likes +=
          review.hasLiked ? 1 : -1; // Increment or decrement like count
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/store/reviews/$reviewId/like/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Get updated like count and 'has_liked' status from the response
        final int updatedLikeCount = responseBody['like_count'] ?? review.likes;
        final bool hasLiked = responseBody['has_liked'] ?? false;

        print(
            "Like response: like_count=$updatedLikeCount, has_liked=$hasLiked");

        // Update UI based on network response
        setState(() {
          review.likes = updatedLikeCount;
          review.hasLiked = hasLiked;
        });

        // Save updated like state and like count to local storage
        await _storage.write(
            key: 'liked_review_${review.id}', value: hasLiked.toString());
        await _storage.write(
            key: 'like_count_${review.id}', value: updatedLikeCount.toString());

        print("Like added successfully, updated like count: $updatedLikeCount");
      } else {
        print('Failed to like review. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error liking review: $e');
    }
  }

  Future<void> _replyReview(int reviewId, String replyText) async {
    String? token = await _storage.read(key: 'auth_token');
    if (!_isLoggedIn || token == null || token.isEmpty) {
      print("You need to be logged in to reply to a review.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/store/reviews/$reviewId/reply/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add token to headers
        },
        body: json.encode({'reply_text': replyText}),
      );

      if (response.statusCode == 201) {
        print('Reply posted successfully');
      } else {
        print('Failed to post reply: ${response.body}');
      }
    } catch (e) {
      print('Error replying to review: $e');
    }
  }
Future<void> loadProductColors(int productId) async {
  try {
    List<ProductColor> colors =
        await ProductColor.fetchProductColors(productId);
    setState(() {
      _productColors = colors;
      if (colors.isNotEmpty) {
        _selectedColor = colors[0]; // default selection
        _currentImage = colors[0].imageUrl; // show first color image
        _productSizes = colors[0].availableSizes;   // <-- populate sizes for UI
        if (_productSizes.isNotEmpty) {
          _selectedSize = _productSizes[0]; // default size selection
        }
      } else {
        _selectedColor = ProductColor.defaultColor();
        _currentImage = ''; // fallback image
        _productSizes = [];
        _selectedSize = null;
      }
    });
  } catch (e) {
    print("Error loading product colors: $e");
  }
}

  // Show login prompt if the user is not logged in
  Widget _buildLoginPrompt(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("You need to be logged in to leave a review.",
            style: TextStyle(fontSize: 18)),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            // Navigate to the login screen and await result
            bool result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );

            // If login was successful, refresh login status
            if (result == true) {
              _checkLoginStatus(); // Refresh login status after successful login
            }
          },
          child: Text("Login"),
        ),
      ],
    );
  }

  // Reset the form after submission

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailScreen(product: product), // Corrected
      ),
    );
  }

  // Fetch related products based on category from a dynamic source (API call)
  void _fetchRelatedProducts() async {
    try {
      // Fetch products by category using the ProductService
      final List<Product> relatedProducts =
          await _productService.fetchProducts();
      setState(() {
        _relatedProducts = relatedProducts.where((product) {
          return product.category ==
              widget.product.category; // Filter by category
        }).toList();
      });
    } catch (e) {
      print("Error fetching related products: $e");
    }
  }

// Fetch all products and find related accessories
  void _fetchRelatedAccessories() async {
    try {
      List<Product> allProducts = await _productService.fetchProducts();
      List<Product> relatedAccessories = _findRelatedAccessories(allProducts);
      setState(() {
        _relatedAccessories = relatedAccessories;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {});
    }
  }

// Function to find related accessories based on name or model
  List<Product> _findRelatedAccessories(List<Product> allProducts) {
    // Access the device model, product name, and category of the current product
    String currentDeviceModel = widget.product.deviceModel.toLowerCase();
    String currentProductName = widget.product.name.toLowerCase();
    String currentCategory = widget.product.category.toLowerCase();
    return allProducts.where((product) {
      // Check if the product is an accessory by matching based on device model
      // Ensure the product doesn't belong to the same category and it's not the same product
      bool isAccessory =
          product.deviceModel.toLowerCase().contains(currentDeviceModel) &&
              product.category.toLowerCase() != currentCategory &&
              product.name.toLowerCase() != currentProductName &&
              product.deviceModel.toLowerCase() !=
                  currentDeviceModel; // Exclude the clicked product

      return isAccessory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
// Default value for large screens

    // Adjust viewportFraction based on screen width
    if (screenWidth < 600) {
// 45% for small screens
    } else if (screenWidth < 1024) {
// 35% for medium screens
    } else {
// 25% for large screens
    }

    return Scaffold(
      backgroundColor: Colors.blue, // background
      appBar: AppBar(
        title: Text("Product Details"),
        actions: [
          // Shopping cart icon with badge
          IconButton(
            icon: Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                int cartItemCount =
                    cartProvider.totalQuantity; // Get the cart item count
                print("Shopping Cart Icon updated, item count: $cartItemCount");

                return Stack(
                  children: [
                    Icon(Icons.shopping_cart), // Cart icon
                    if (cartItemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cartItemCount
                                .toString(), // Display item count on the icon
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            onPressed: () {
              print("Shopping Cart Icon pressed");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShoppingCartScreen()),
              );
            },
            iconSize: 30.0,
            color: Colors.black,
            tooltip: 'Shopping Cart',
          )
        ],
      ),
body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Wrap everything in Center + ConstrainedBox
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200), // max width for web
            child: constraints.maxWidth <= 800
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 0,
                            child: Column(
                              children: [
                                _buildImageCard(widget.product.image1),
                                _buildImageCard(widget.product.image2),
                                _buildImageCard(widget.product.image3),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: _buildMainProductImage(),
                          ),
                          _buildProductInfo(),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildShoppingFeatures(),
                      SizedBox(height: 20),
                      _buildProductComparisonSection(),
                      SizedBox(height: 20),
                      _isLoggedIn
                          ? _buildReviewForm()
                          : _buildLoginPrompt(context),
                      _buildReviewsList(),
                      SizedBox(height: 20),
                      _buildRelatedProductsSection(_relatedProducts, context),
                      _buildAccessoriesSection(_relatedAccessories, context),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 0,
                            child: Column(
                              children: [
                                _buildImageCard(widget.product.image1),
                                _buildImageCard(widget.product.image2),
                                _buildImageCard(widget.product.image3),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: _buildMainProductImage(),
                          ),
                          SizedBox(width: 70),
                          Expanded(flex: 1, child: _buildProductInfo()),
                          Expanded(flex: 1, child: _buildShoppingFeatures()),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildProductComparisonSection(),
                      SizedBox(height: 20),
                      _isLoggedIn
                          ? _buildReviewForm()
                          : _buildLoginPrompt(context),
                      _buildReviewsList(),
                      SizedBox(height: 20),
                      _buildRelatedProductsSection(_relatedProducts, context),
                      _buildAccessoriesSection(_relatedAccessories, context),
                    ],
                  ),
          ),
        );
      },
    ),
  ),
),

    );
  }

// Build the section for product comparison selection
  Widget _buildProductComparisonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compare Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            _buildComparisonSelector(0),
            SizedBox(width: 16),
            _buildComparisonSelector(1),
          ],
        ),
        SizedBox(height: 10),
        if (_firstProduct != null && _secondProduct != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildComparisonTable(),
            ],
          ),
      ],
    );
  }

// Function to build the comparison table
  Widget _buildComparisonTable() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Column(
        children: [
          _buildComparisonRow(
              'Image', _firstProduct!.image1, _secondProduct!.image1),
          _buildComparisonRow(
              'Name', _firstProduct!.name, _secondProduct!.name),
          _buildComparisonRow('Price', _firstProduct!.finalPrice.toString(),
              _secondProduct!.finalPrice.toString()),
          _buildComparisonRow('Rating', _firstProduct!.rating.toString(),
              _secondProduct!.rating.toString()),

          // Show more details if expanded
          if (_isExpanded) ...[
            _buildComparisonRow('Description', _firstProduct!.description,
                _secondProduct!.description),
            // Add more rows as needed
          ],

          // Toggle button to show more or show less
          TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded; // Toggle expanded state
              });
            },
            child: Text(_isExpanded ? 'Show Less' : 'Show More'),
          ),
        ],
      ),
    );
  }

// Function to build a single row for product comparison
  Widget _buildComparisonRow(
      String property, dynamic product1Value, dynamic product2Value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left column for product 1
        Expanded(
          child: property == 'Image'
              ? Image.network(product1Value,
                  width: 100, height: 100) // Show image for the first product
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$property:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(product1Value
                        .toString()), // Display value for non-image properties
                  ],
                ),
        ),
        SizedBox(width: 20),
        // Right column for product 2
        Expanded(
          child: property == 'Image'
              ? Image.network(product2Value,
                  width: 100, height: 100) // Show image for the second product
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$property:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(product2Value
                        .toString()), // Display value for non-image properties
                  ],
                ),
        ),
      ],
    );
  }

// Function to show the product selection dialog for comparison
  void _showProductSelectionDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a Product for Comparison'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _relatedProducts.map((product) {
              return ListTile(
                title: Text(product.name),
                onTap: () {
                  setState(() {
                    if (index == 0) {
                      _firstProduct = product;
                    } else {
                      _secondProduct = product;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

// Function to build comparison selector button
  Widget _buildComparisonSelector(int index) {
    return GestureDetector(
      onTap: () {
        // Handle product selection for comparison
        _showProductSelectionDialog(index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.green.shade100,
        ),
        child: Text(
          'Select Product ${index + 1}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    bool isSelected = _currentImage == imageUrl;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentImage = imageUrl;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: EdgeInsets.all(isSelected ? 2 : 1),
        width: 48, // smaller width
        height: 48, // smaller height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildMainProductImage() {
    double screenWidth = MediaQuery.of(context).size.width;

    // Responsive size
    double imageSize;
    if (screenWidth < 400) {
      imageSize = screenWidth * 0.7; // small mobile
    } else if (screenWidth < 800) {
      imageSize = screenWidth * 0.5; // tablet / medium screen
    } else {
      imageSize = screenWidth * 0.28; // desktop
    }

    return Center(
      child: _currentImage.isNotEmpty
          ? AnimatedContainer(
              width: imageSize,
              height: imageSize,
              duration: Duration(milliseconds: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12.0,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 8.0,
                    spreadRadius: -4.0,
                    offset: Offset(0, -4),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.2), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  _currentImage,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: Colors.green.shade300,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: Colors.white,
                  size: imageSize * 0.18, // scale icon size too
                ),
              ),
            ),
    );
  }

  Widget _buildProductInfo() {
    double screenWidth = MediaQuery.of(context).size.width;

    // Font sizes based on screen width
    double titleFontSize;
    double priceFontSize;
    double stockFontSize;
    double descriptionFontSize;
    double buttonFontSize;
    double containerPaddingV;
    double containerPaddingH;

    if (screenWidth < 600) {
      // Mobile
      titleFontSize = 18;
      priceFontSize = 16;
      stockFontSize = 14;
      descriptionFontSize = 12;
      buttonFontSize = 12;
      containerPaddingV = 6;
      containerPaddingH = 10;
    } else if (screenWidth < 1200) {
      // Tablet
      titleFontSize = 24;
      priceFontSize = 20;
      stockFontSize = 16;
      descriptionFontSize = 14;
      buttonFontSize = 14;
      containerPaddingV = 10;
      containerPaddingH = 16;
    } else {
      // Desktop
      titleFontSize = 32;
      priceFontSize = 28;
      stockFontSize = 20;
      descriptionFontSize = 16;
      buttonFontSize = 16;
      containerPaddingV = 14;
      containerPaddingH = 24;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.withOpacity(0.25), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          padding: EdgeInsets.symmetric(
              vertical: containerPaddingV, horizontal: containerPaddingH),
          child: Text(
            widget.product.name,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 8),

        // Product Price
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent.withOpacity(0.6), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20.0),
              bottomLeft: Radius.circular(20.0),
            ),
          ),
          padding: EdgeInsets.symmetric(
              vertical: containerPaddingV, horizontal: containerPaddingH),
          child: Text(
            "\$${widget.product.finalPrice}",
            style: TextStyle(
              fontSize: priceFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 12),

        // Stock Status
        _buildStockStatusResponsive(
            stockFontSize, containerPaddingV, containerPaddingH),

        SizedBox(height: 12),

        // Product Description
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: Text(
            widget.product.description.length > 50 && !_showDetails
                ? widget.product.description.substring(0, 20) + '...'
                : widget.product.description,
            key: ValueKey<bool>(_showDetails),
            style:
                TextStyle(fontSize: descriptionFontSize, color: Colors.black54),
          ),
        ),

        SizedBox(height: 12),

        // Show Details / Close Button
        ElevatedButton(
          onPressed: () {
            if (widget.product.description.length > 50) {
              _showDescriptionDialog(context);
            } else {
              setState(() {
                _showDetails = !_showDetails;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(
                vertical: containerPaddingV, horizontal: containerPaddingH),
            textStyle: TextStyle(
              fontSize: buttonFontSize,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            elevation: 4,
            shadowColor: Colors.blueAccent.withOpacity(0.2),
          ),
          child: Text(
            _showDetails ? 'Close' : 'Show Details',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStockStatusResponsive(
      double fontSize, double paddingV, double paddingH) {
    String statusText = '';
    IconData statusIcon = Icons.check_circle;
    Gradient statusGradient;
    Color shadowColor;

    if (widget.product.stock > 1) {
      statusText = "In Stock";
      statusIcon = Icons.check_circle;
      statusGradient = LinearGradient(
        colors: [
          const Color.fromARGB(255, 126, 248, 189).withOpacity(0.7),
          Colors.green.withOpacity(0.7)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      shadowColor = Colors.green.withOpacity(0.3);
    } else if (widget.product.stock == 1) {
      statusText = "Only 1 left!";
      statusIcon = Icons.warning;
      statusGradient = LinearGradient(
        colors: [
          const Color.fromARGB(255, 255, 201, 131).withOpacity(0.7),
          Colors.orange.withOpacity(0.7)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      shadowColor = Colors.orange.withOpacity(0.3);
    } else {
      statusText = "Out of Stock";
      statusIcon = Icons.remove_circle;
      statusGradient = LinearGradient(
        colors: [
          const Color.fromARGB(255, 253, 118, 118).withOpacity(0.7),
          Colors.red.withOpacity(0.7)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      shadowColor = Colors.red.withOpacity(0.3);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: paddingV, horizontal: paddingH),
        decoration: BoxDecoration(
          gradient: statusGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(100.0),
            bottomRight: Radius.circular(100.0),
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 6.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: Colors.white, size: fontSize + 4),
            SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Function to show the description in a scrollable dialog
  void _showDescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Product Details"),
        content: SingleChildScrollView(
          // Make the content scrollable
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.product.description),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
bool _isAddingToCart = false;
bool _isAddingToWishlist = false;

Widget _buildShoppingFeatures() {
  if (_quantity == 0) _quantity = 1;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Quantity Selector
      Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ Colors.white, Colors.blueAccent.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Quantity",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onPressed: () {
                    if (_quantity > 1) setState(() => _quantity--);
                  },
                ),
                SizedBox(width: 20),
                Text("$_quantity",
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(width: 20),
                _buildQuantityButton(
                  icon: Icons.add,
                  onPressed: () {
                    if (_quantity < 10) {
                      setState(() => _quantity++);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text("You cannot add more than 10 items")));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 25),

      // Color Selector
      if (_productColors.isNotEmpty) ...[
        Text("Choose Color",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _productColors.map((color) {
              bool isOutOfStock =
                  color.availableSizes.every((s) => s.stock == 0);
              return GestureDetector(
                onTap: isOutOfStock
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "This color is out of stock, please choose another.")));
                      }
                    : () {
                        setState(() {
                          _selectedColor = color;
                          _currentImage = color.imageUrl;
                          _productSizes = color.availableSizes;
                          _selectedSize = color.availableSizes.isNotEmpty
                              ? color.availableSizes.firstWhere(
                                  (s) => s.stock > 0,
                                  orElse: () => color.availableSizes[0],
                                )
                              : null;
                        });
                      },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getColorFromCode(color.colorCode),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _selectedColor == color
                            ? Colors.green
                            : Colors.transparent,
                        width: 4),
                    boxShadow: [
                      if (_selectedColor == color)
                        BoxShadow(
                            color: Colors.blue.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 3)
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 25),
      ],

      // Size Selector
      if (_productSizes.isNotEmpty) ...[
        Text("Choose Size",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _productSizes.map((size) {
              bool isOutOfStock = size.stock == 0;
              return GestureDetector(
                onTap: isOutOfStock
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "This size is out of stock, please choose another.")));
                      }
                    : () {
                        setState(() => _selectedSize = size);
                      },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedSize == size
                        ? Colors.green
                        : Colors.blue[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _selectedSize == size
                            ? Colors.green
                            : Colors.blue,
                        width: 2),
                  ),
                  child: Text(
                    size.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedSize == size
                          ? Colors.white
                          : (isOutOfStock ? Colors.red : Colors.black87),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 30),
      ],

      // Add to Cart Button
      _buildAddToCartButton(_isAddingToCart),

      // Add to Wishlist Button
      _buildAddToWishlistButton(_isAddingToWishlist),
    ],
  );
}


// Helper: Add to Cart Button
Widget _buildAddToCartButton(bool _isAddingToCart) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: ElevatedButton(
      onPressed: _isAddingToCart
          ? null
          : () async {
              setState(() => _isAddingToCart = true);

              if (!_isLoggedIn) {
                Navigator.pushNamed(context, '/login');
                setState(() => _isAddingToCart = false);
                return;
              }

              if (_selectedColor == null ||
                  _selectedSize == null ||
                  _selectedSize!.stock == 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Please select a color and size in stock")));
                setState(() => _isAddingToCart = false);
                return;
              }

              String? token = await _storage.read(key: 'auth_token');
              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("You must be logged in to add to cart.")));
                setState(() => _isAddingToCart = false);
                return;
              }

              CartItem cartItem = CartItem(
                  product: widget.product,
                  quantity: _quantity,
                  selectedColor: _selectedColor,
                  selectedSize: _selectedSize,
                  brand: widget.product.brand);

              try {
                context.read<CartProvider>().addToCart(cartItem, token);
                setState(() => _quantity = 1);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${widget.product.name} added!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("Failed to add to cart. Please try again.")));
              } finally {
                setState(() => _isAddingToCart = false);
              }
            },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      child: Text("Add to Cart", style: TextStyle(fontSize: 20)),
    ),
  );
}

// Helper: Add to Wishlist Button
Widget _buildAddToWishlistButton(bool _isAddingToWishlist) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: ElevatedButton(
      onPressed: _isAddingToWishlist
          ? null
          : () async {
              setState(() => _isAddingToWishlist = true);

              if (!_isLoggedIn) {
                Navigator.pushNamed(context, '/login');
                setState(() => _isAddingToWishlist = false);
                return;
              }

              String? token = await _storage.read(key: 'auth_token');
              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("You must be logged in to add to wishlist.")));
                setState(() => _isAddingToWishlist = false);
                return;
              }

              try {
                await context
                    .read<WishlistProvider>()
                    .addToWishlist(widget.product, token);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("${widget.product.name} added to wishlist!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Failed to add to wishlist. Please try again.")));
              } finally {
                setState(() => _isAddingToWishlist = false);
              }
            },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      child: Text("Add to Wishlist", style: TextStyle(fontSize: 20)),
    ),
  );
}

// Helper method for quantity button with elevated effect
  Widget _buildQuantityButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.4),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.blueAccent),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title for the review form
        Text(
          "Leave a Review",
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent),
        ),
        SizedBox(height: 20),

        // Name input field with better styling
        TextField(
          maxLength: 20, // Limit name length to 20 characters
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Your Name',
            labelStyle: TextStyle(color: Colors.deepPurpleAccent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.deepPurpleAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
            ),
            prefixIcon: Icon(Icons.person, color: Colors.deepPurpleAccent),
          ),
        ),
        SizedBox(height: 20),

        // Review input field with better styling
        TextField(
          maxLength: 255, // Limit review length to 255 characters
          controller: _reviewController,
          decoration: InputDecoration(
            labelText: 'Your Review',
            labelStyle: TextStyle(color: Colors.deepPurpleAccent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.deepPurpleAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
            ),
            prefixIcon: Icon(Icons.comment, color: Colors.deepPurpleAccent),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 20),

        // Star Rating System with better UI
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.deepPurpleAccent,
                size: 30,
              ),
              onPressed: () {
                setState(() {
                  _rating = index + 1; // Update the rating
                });
              },
            );
          }),
        ),
        SizedBox(height: 20),

        // Center the Submit Button
        Center(
          child: GestureDetector(
            onTap: _submitReview,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30), // Pill shape
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                "Submit",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        )

      ],
    );
  }

  Widget _buildReviewsList() {
    var limitedReviews = _reviews.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Customer Reviews",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ...limitedReviews.map((review) {
          TextEditingController replyController = TextEditingController();

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating section
                  Row(
                    children: [
                      Text(
                        'Rating: ',
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                      ...List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                          size: 20,
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: 5),
                  // Comment section (limit length to 50 characters)
                  Text(
                    review.comment.length > 50
                        ? review.comment.substring(0, 50) + '...'
                        : review.comment,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  // Like button and like count
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          review.hasLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_off_alt,
                          color: review.hasLiked
                              ? Colors.blue
                              : Colors.green, // Blue when liked, grey when not
                        ),
                        onPressed: () {
                          _likeReview(
                              review.id, review); // Trigger the like action
                        },
                      ),
                      Text("${review.likes} Likes",
                          style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Reply section
                  if (review.replies.isNotEmpty) ...[
                    ...review.replies.take(3).map((reply) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text(
                          reply.length > 50
                              ? reply.substring(0, 50) + '...'
                              : reply,
                          style: TextStyle(fontSize: 14, color: Colors.green),
                        ),
                      );
                    }).toList(),
                  ],
                  // Reply input section
                  TextField(
                    controller: replyController,
                    maxLength: 255,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      String reply = replyController.text.trim();
                      if (reply.isNotEmpty) {
                        _replyReview(review.id, reply).then((_) {
                          setState(() {
                            review.addReply(reply);
                          });
                          replyController.clear();
                        });
                      }
                    },
                    child: Text("Reply"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }


// Helper: Liquid Glass Card
  Widget _buildLiquidGlassCard(Product product, {VoidCallback? onTap}) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Product Image
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              product.image1,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Product Info
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            children: [
                              Text(
                                product.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "\$${product.finalPrice}",
                                style: TextStyle(
                                    color: Colors.greenAccent, fontSize: 14),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Rating: ${product.rating}",
                                style: TextStyle(
                                    color: Colors.orangeAccent, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// See More Card
  Widget _buildSeeMoreCard(BuildContext context, String title, VoidCallback onTap) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueAccent),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, color: Colors.blueAccent, size: 16)
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// Updated Related Products Section
  Widget _buildRelatedProductsSection(List<Product> relatedProducts, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double viewportFraction = screenWidth < 600
        ? 0.45
        : screenWidth < 1024
        ? 0.35
        : 0.25;
    double carouselHeight = screenWidth < 600
        ? 200
        : screenWidth < 1024
        ? 280
        : 300;

    List<Product> displayProducts =
    relatedProducts.length > 4 ? relatedProducts.sublist(0, 4) : relatedProducts;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Same Products',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 10),
          CarouselSlider(
            options: CarouselOptions(
              height: carouselHeight,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              viewportFraction: viewportFraction,
            ),
            items: [
              ...displayProducts.map((product) {
                return _buildLiquidGlassCard(product,
                    onTap: () => _navigateToProductDetail(context, product));
              }).toList(),
              if (relatedProducts.length > 4)
                _buildSeeMoreCard(
                  context,
                  "See More",
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            RelatedProductsScreen(products: relatedProducts)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

// Updated Accessories Section
  Widget _buildAccessoriesSection(List<Product> relatedAccessories, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double viewportFraction = screenWidth < 600
        ? 0.45
        : screenWidth < 1024
        ? 0.35
        : 0.25;
    double carouselHeight = screenWidth < 600
        ? 200
        : screenWidth < 1024
        ? 280
        : 300;

    List<Product> displayAccessories =
    relatedAccessories.length > 4 ? relatedAccessories.sublist(0, 4) : relatedAccessories;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Accessories',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 10),
          CarouselSlider(
            options: CarouselOptions(
              height: carouselHeight,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              viewportFraction: viewportFraction,
            ),
            items: [
              ...displayAccessories.map((product) {
                return _buildLiquidGlassCard(product,
                    onTap: () => _navigateToProductDetail(context, product));
              }).toList(),
              if (relatedAccessories.length > 4)
                _buildSeeMoreCard(
                  context,
                  "See More",
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AccessoriesScreen(products: relatedAccessories)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
// ================= Full Accessories Page =================


class AccessoriesScreen extends StatelessWidget {
  final List<Product> products;

  const AccessoriesScreen({super.key, required this.products});

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1024) return 4; // Desktop
    if (screenWidth >= 600) return 2; // Tablet
    return 1; // Mobile
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth >= 1024) return 0.65; // Desktop
    if (screenWidth >= 600) return 0.8; // Tablet
    return 1; // Mobile
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = _getCrossAxisCount(screenWidth);
    double childAspectRatio = _getChildAspectRatio(screenWidth);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Accessories"),
        backgroundColor: Colors.deepPurple,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          Product product = products[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: Image.network(
                      product.image1,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 50)),
                    ),
                  ),
                  // Frosted Glass Overlay
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Product Info
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black45,
                                offset: Offset(1, 1),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.price}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black45,
                                offset: Offset(1, 1),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rating: ${product.rating}',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black45,
                                offset: Offset(1, 1),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
class RelatedProductsScreen extends StatelessWidget {
  final List<Product> products;

  const RelatedProductsScreen({super.key, required this.products});

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1024) return 4; // Desktop
    if (screenWidth >= 600) return 2;  // Tablet
    return 2; // Mobile: 2 cards per row
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth >= 1024) return 0.65; // Desktop
    if (screenWidth >= 600) return 0.8;   // Tablet
    return 0.9; // Mobile: slightly taller cards
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = _getCrossAxisCount(screenWidth);
    double childAspectRatio = _getChildAspectRatio(screenWidth);

    return Scaffold(
      backgroundColor: Colors.blue, // background
      appBar: AppBar(
        title: const Text("All Related Products"),
        backgroundColor: Colors.deepPurple,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          Product product = products[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background image slightly blurred
                  Positioned.fill(
                    child: Image.network(
                      product.image1,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.1),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 50)),
                    ),
                  ),
                  // Glass effect overlay
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  product.image1,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.broken_image, size: 50)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\$${product.price}",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Rating: ${product.rating}",
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
