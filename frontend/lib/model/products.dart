import 'package:frontend/model/brand.dart';
import 'package:frontend/model/productcolor.dart'; // Import ProductColor model
import 'package:frontend/model/productsize.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String makeBy;
  final List<ProductColor> color;
  final double rating;
  final double discount;
  final String category;
  final int stock;
  final String image1;
  final String image2;
  final String image3;
  final Brand brand;
  final String deviceModel;
  final double finalPrice;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.makeBy,
    required this.color,
    required this.rating,
    required this.discount,
    required this.stock,
    required this.image1,
    required this.image2,
    required this.image3,
    required this.category,
    required this.brand,
    required this.deviceModel,
    required this.finalPrice,
  });

  static int safeInt(dynamic value, int defaultValue) {
    return value == null
        ? defaultValue
        : (value is int
            ? value
            : int.tryParse(value.toString()) ?? defaultValue);
  }

  static String safeString(dynamic value, String defaultValue) {
    return value == null ? defaultValue : value.toString();
  }

  static double safeDouble(dynamic value, double defaultValue) {
    return value == null
        ? defaultValue
        : (value is double
            ? value
            : double.tryParse(value.toString()) ?? defaultValue);
  }

  static Future<ProductColor> fetchColorDetails(int colorId) async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2:8000/api/store/colors/$colorId/'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> colorJson = json.decode(response.body);
      return ProductColor.fromJson(colorJson);
    } else {
      throw Exception('Failed to load color details');
    }
  }

  static Future<List<Product>> fetchListByPrefix(String prefix) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/store/search/?q=$prefix'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Product> products = [];
      for (var item in data['products']) {
        products.add(await Product.fromJson(item)); // use async fromJson
      }
      return products;
    } else {
      throw Exception('Failed to fetch products starting with $prefix');
    }
  }

  static Future<Product> fetchById(int id) async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2:8000/api/store/products/$id/'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return Product.fromJson(json);
    } else {
      throw Exception('Failed to load product with id: $id');
    }
  }

  static Future<Product> fetchByName(String name) async {
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/store/products/name/$name/'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else {
        print(
            "Failed to fetch product by name: $name. Status code: ${response.statusCode}");
        throw Exception("Product not found");
      }
    } catch (e) {
      print("Error fetching product: $e");
      throw Exception("Error fetching product");
    }
  }

static const String baseUrl = 'http://10.0.2.2:8000';

static Future<Product> fromJson(Map<String, dynamic> json) async {
  List<ProductColor> colors = [];

  Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);

  // Handle color list
  if (safeJson['color'] != null && safeJson['color'] is List) {
    List<dynamic> colorListJson = safeJson['color'];
    colors = colorListJson.map((c) => ProductColor.fromJson(c)).toList();
  }

  final brandJson = safeJson['brand'] ?? {};
  final deviceModelJson = safeJson['device_model'] ?? {};

  // Fix image URLs
  String fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url; // Already full URL
    return '$baseUrl$url'; // Prepend base URL
  }

  return Product(
    id: safeInt(safeJson['id'], 0),
    name: safeString(safeJson['name'], 'Unknown'),
    description: safeString(safeJson['description'], 'No description available'),
    price: safeDouble(safeJson['price'], 0.0),
    makeBy: safeString(safeJson['make_by'], 'Unknown'),
    color: colors,
    rating: safeDouble(safeJson['rating'], 0.0),
    discount: safeDouble(safeJson['discount'], 0.0),
    stock: safeInt(safeJson['stock'], 0),
    image1: fixUrl(safeJson['image1']),
    image2: fixUrl(safeJson['image2']),
    image3: fixUrl(safeJson['image3']),
    finalPrice: safeDouble(safeJson['final_price'], 0.0),
    category: safeString(
      safeJson['category'] is Map ? safeJson['category']['name'] : safeJson['category'],
      'Unknown',
    ),
    brand: Brand.fromJson(brandJson),
    deviceModel: deviceModelJson['name'] ?? 'Unknown Device',
  );
}


  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, rating: $rating)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'make_by': makeBy,
      'color': color.map((color) => color.toJson()).toList(),
      'rating': rating,
      'discount': discount,
      'stock': stock,
      'image1': image1,
      'image2': image2,
      'image3': image3,
      'category': category,
      'brand': brand.toJson(),
      'device_model': deviceModel,
      'final_price': finalPrice,
    };
  }
}
class CartItem {
  final Product product;
  int quantity;
  ProductColor? selectedColor; // Optional
  ProductSize? selectedSize;    // Optional
  final Brand brand;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedColor,
    this.selectedSize,
    required this.brand,
  });

  // Calculate total price
  double get totalPrice => product.finalPrice * quantity;

  // Convert to JSON for backend API (POST requests)
  Map<String, dynamic> toApiJson() {
    return {
      'product_id': product.id,
      'color_name': selectedColor?.colorName ?? '',
      'size_name': selectedSize?.name ?? '',
      'quantity': quantity,
    };
  }

  // Convert CartItem to JSON (full object, e.g., for local storage)
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'selected_color': selectedColor?.toJson(),
      'selected_size': selectedSize?.toJson(),
      'brand': brand.toJson(),
    };
  }

  // Parse CartItem from backend JSON
  static Future<CartItem> fromJson(Map<String, dynamic> json) async {
    try {
      // --- Product ---
      late Product product;
      if (json['product'] is int) {
        product = await Product.fetchById(json['product']);
      } else if (json['product'] is Map<String, dynamic>) {
        product = await Product.fromJson(json['product']);
      } else if (json['product'] is String) {
        product = await Product.fetchByName(json['product']);
      } else {
        throw Exception("Invalid product data: ${json['product']}");
      }

      // --- Brand ---
      Brand brand = json['brand'] != null
          ? await Brand.fromJson(json['brand'])
          : Brand(name: "Unknown");

      // --- Color ---
      ProductColor? selectedColor;
      final colorJson = json['color'] ?? json['selected_color'];
      if (colorJson != null) {
        if (colorJson is int) {
          selectedColor = await ProductColor.fromId(colorJson);
        } else if (colorJson is String) {
          selectedColor = await ProductColor.fromName(colorJson);
        } else if (colorJson is Map<String, dynamic>) {
          selectedColor = ProductColor.fromJson(colorJson);
        }
      }

      // --- Size ---
      ProductSize? selectedSize;
      final sizeJson = json['size'] ?? json['selected_size'] ?? json['size_name'];
      if (sizeJson != null) {
        if (sizeJson is int) {
          selectedSize = ProductSize(id: sizeJson, name: "Unknown", stock: 0);
        } else if (sizeJson is String) {
          selectedSize = ProductSize(id: 0, name: sizeJson, stock: 0);
        } else if (sizeJson is Map<String, dynamic>) {
          selectedSize = ProductSize.fromJson(sizeJson);
        }
      }

      // --- Quantity ---
      int quantity = (json['quantity'] is int)
          ? json['quantity']
          : int.tryParse(json['quantity'].toString()) ?? 1;

      return CartItem(
        product: product,
        quantity: quantity,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        brand: brand,
      );
    } catch (e) {
      print("Error parsing CartItem from JSON: $e");
      rethrow;
    }
  }
}

class BestSellingProduct {
  final int id;
  final String category;
  final String productName;
  final String description;
  final double price;
  final String makeBy;
  List<ProductColor>
      colorDetails; // List to store the actual color details (not just names)
  final double rating;
  final double discount;
  final int stock;
  final int totalQuantitySold;
  final String image1;
  final String image2;
  final String image3;
  final double finalPrice;
  final Brand brand;
  final String deviceModel;
  BestSellingProduct(
      {required this.id,
      required this.category,
      required this.brand,
      required this.deviceModel,
      required this.productName,
      required this.description,
      required this.price,
      required this.makeBy,
      required this.colorDetails, // Now we pass the list of ProductColor
      required this.rating,
      required this.discount,
      required this.stock,
      required this.totalQuantitySold,
      required this.image1,
      required this.image2,
      required this.image3,
      required this.finalPrice});

  // Safe parsing methods for ensuring type safety
  static int safeInt(dynamic value, int defaultValue) {
    return value == null
        ? defaultValue
        : (value is int
            ? value
            : int.tryParse(value.toString()) ?? defaultValue);
  }

  static String safeString(dynamic value, String defaultValue) {
    return value == null ? defaultValue : value.toString();
  }

  static double safeDouble(dynamic value, double defaultValue) {
    return value == null
        ? defaultValue
        : (value is double
            ? value
            : double.tryParse(value.toString()) ?? defaultValue);
  }

  // Convert BestSellingProduct to Product
  Product toProduct() {
    return Product(
      id: this.id,
      name: this.productName,
      description: this.description,
      price: this.price,
      makeBy: this.makeBy,
      color: this.colorDetails, // Convert colorDetails to a list of color JSONs
      rating: this.rating,
      discount: this.discount,
      stock: this.stock,
      image1: this.image1,
      image2: this.image2,
      image3: this.image3,
      category: this.category, // Assuming 'Best Selling' category for now
      brand: this.brand, // Placeholder for brand
      deviceModel: this.deviceModel,
      finalPrice: this.finalPrice, // Placeholder for device model
    );
  }

  // Method to fetch all colors dynamically
  static Future<Map<String, int>> fetchAllColors() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/api/store/colors/'));

    if (response.statusCode == 200) {
      List<dynamic> colorsJson = json.decode(response.body);
      Map<String, int> colorNameToId = {};

      // Print out the colors from the API response
      print('Fetched color data: $colorsJson');

      for (var color in colorsJson) {
        colorNameToId[color['color_name']] =
            color['id']; // Map color name to its ID
      }

      // Log the color name to ID mapping to ensure it's correct
      print('Color Name to ID Mapping: $colorNameToId');

      return colorNameToId;
    } else {
      throw Exception('Failed to fetch color list');
    }
  }

  // Update the fromJson method to correctly map the product_id field
  static Future<BestSellingProduct> fromJson(Map<String, dynamic> json) async {
    List<ProductColor> colorDetails = [];

    if (json['color'] != null && json['color'] is List) {
      try {
        // Loop over each color name and fetch details via color_byname API endpoint
        for (var colorName in json['color']) {
          // Fetch color details by name
          ProductColor color = await ProductColor.fromName(
              colorName); // Make an API call to fetch color by name

          colorDetails.add(color);
        }
      } catch (e) {
        print('Error fetching colors: $e');
      }
    }
    final brandJson = json['brand'] ?? {};
    final deviceModelJson = json['device_model'] ?? {};
    return BestSellingProduct(
      id: safeInt(json['product_id'], 0), // Update this line to use product_id
      productName: safeString(json['product_name'], 'Unknown'),
      description: safeString(json['description'], 'No description available'),
      price: safeDouble(json['price'], 0.0),
      makeBy: safeString(json['make_by'], 'Unknown'),
      colorDetails: colorDetails, // Add the full color details
      rating: safeDouble(json['rating'], 0.0),
      discount: safeDouble(json['discount'], 0.0),
      stock: safeInt(json['stock'], 0),
      totalQuantitySold: safeInt(json['total_quantity_sold'], 0),
      image1: safeString(json['image1'], ''),
      image2: safeString(json['image2'], ''),
      image3: safeString(json['image3'], ''),
      finalPrice: double.parse(
          json['final_price'].toString()), // Parse final_price here
               category: safeString(
        json['category'] is Map
            ? json['category']['name']
            : json['category'],
        'Unknown',
      ),
      brand: Brand.fromJson(brandJson), // Pass the brand JSON object directly
      deviceModel: deviceModelJson['name'] ??
          'Unknown Device', // Access the device model name
    );
  }

  // Convert BestSellingProduct to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'description': description,
      'price': price,
      'make_by': makeBy,
      'color': colorDetails
          .map((color) => color.toJson())
          .toList(), // Convert colorDetails to a list of color JSONs
      'rating': rating,
      'discount': discount,
      'stock': stock,
      'total_quantity_sold': totalQuantitySold,
      'image1': image1,
      'image2': image2,
      'image3': image3,
      'finalPrice': finalPrice,
      'category': category,
      'brand': brand.toJson(),
      'device_model': deviceModel,
    };
  }
}
