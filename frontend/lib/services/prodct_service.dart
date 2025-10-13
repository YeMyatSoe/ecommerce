import 'dart:convert';
import 'package:frontend/model/category.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/model/products.dart';
import 'package:frontend/model/banners.dart';

class ProductService {
  static const String apiUrl = 'http://10.0.2.2:8000/api/store';  // Base URL, no trailing slash

  // This function will fetch products from the API and return a list of Product objects
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/products/'));

      if (response.statusCode == 200) {
        print('Raw response body: ${response.body}');  // Debugging the raw response

        // Directly decoding the response body as a List<dynamic> since the response is a list
        List<dynamic> data = json.decode(response.body);

        // Map through each item and return a list of Product objects
        return Future.wait(data.map((item) async {
          // Ensure that the color field is handled correctly (either a list of color IDs or a list of maps)
          var product = await Product.fromJson(item);
          return product;
        }).toList());
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Fetch all banners
  Future<List<Banner>> fetchBanners() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/banners/'));

      if (response.statusCode == 200) {
        print('Raw response body: ${response.body}');  // Debugging the raw response
        
        // Directly decoding the response body as a List<dynamic> since the response is a list
        List<dynamic> data = json.decode(response.body);

        // If it's a list of banners, we can map through and parse each item
        return data.map((item) => Banner.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      throw Exception('Error fetching banners: $e');
    }
  }
Future<List<Category>> fetchCategories() async {
  try {
    final response = await http.get(Uri.parse('$apiUrl/categories/'));  // Endpoint for categories

    if (response.statusCode == 200) {
      List<dynamic> categoryList = json.decode(response.body);

      // Map the dynamic list to a List<Category> by using Category.fromJson
      return categoryList.map((categoryJson) => Category.fromJson(categoryJson)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  } catch (e) {
    throw Exception('Error fetching categories: $e');
  }
}

  // Fetch products by category
  Future<List<dynamic>> fetchProductsByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/products/?category=$category'));

      if (response.statusCode == 200) {
        // Decode the response body as a List of products
        List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }
// Add item to the cart
 Future<void> addToCart(int productId, String colorName, String sizeName, int quantity, String token) async {
  final response = await http.post(
    Uri.parse('$apiUrl/getcart/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'product_id': productId,
      'color_size_quantities': [
        {
          'color_name': colorName,
          'size_name': sizeName,
          'quantity': quantity,
        }
      ]
    }),
  );

  if (response.statusCode == 201) {
    print("Item added to cart successfully!");
  } else {
    throw Exception('Failed to add item to cart: ${response.statusCode} ${response.body}');
  }
}

  Future<List<BestSellingProduct>> fetchBestSellingProducts() async {
  final response = await http.get(Uri.parse('$apiUrl/best_selling_products/'));

  if (response.statusCode == 200) {
    // Debug print: Show the response body
    print('Fetched Data: ${response.body}');

    List<dynamic> data = json.decode(response.body);

    List<BestSellingProduct> products = [];
    for (var item in data) {
      print('Processing Product: $item');  // Debug print: Show each item being processed

      // Fetch product details and print
      BestSellingProduct product = await BestSellingProduct.fromJson(item);
      print('Fetched bestselling Product: ${product.productName}');  // Debug print: Show fetched product name

      products.add(product);
    }

    // Debug print: Show the final list of products
    print('Fetched ${products.length} products.');

    return products;
  } else {
    throw Exception("Failed to load best-selling products");
  }
}
}

 

