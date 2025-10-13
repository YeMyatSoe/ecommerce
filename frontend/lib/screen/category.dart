import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/screen/product_detail.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/category_service.dart';
import 'dart:ui';

class ProductCategoryScreen extends StatefulWidget {
  const ProductCategoryScreen({super.key});

  static const String apiUrl = 'http://10.0.2.2:8000/api/store';

  @override
  _ProductCategoryScreenState createState() => _ProductCategoryScreenState();
}

class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
  String selectedCategory = 'All';
  String selectedBrand = 'All';
  String selectedDeviceModel = 'All';

  int selectedCategoryId = -1;
  int selectedBrandId = -1;
  int selectedDeviceModelId = -1;

  List<dynamic> categories = [];
  List<dynamic> brands = [];
  List<dynamic> deviceModels = [];
  List<Product> products = [];
  ApiService apiService = ApiService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  Future<void> loadCategories() async {
    try {
      var response = await apiService.fetchCategories();
      setState(() {
        categories = response;
        isLoading = false;
      });
      loadProductData();
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> loadBrands(int categoryId) async {
    try {
      final response = await http.get(Uri.parse(
          '${ProductCategoryScreen.apiUrl}/brands/?category_id=$categoryId'));
      if (response.statusCode == 200) {
        List<dynamic> brandList = json.decode(response.body);
        setState(() {
          brands = brandList;
          selectedBrand = 'All';
          selectedBrandId = -1;
          deviceModels = [];
          selectedDeviceModel = 'All';
          selectedDeviceModelId = -1;
        });
      }
    } catch (e) {
      print('Error loading brands: $e');
    }
  }

  Future<void> loadDeviceModels(int brandId) async {
    try {
      final response = await http.get(Uri.parse(
          '${ProductCategoryScreen.apiUrl}/device-models/?brand_id=$brandId'));
      if (response.statusCode == 200) {
        List<dynamic> deviceModelList = json.decode(response.body);
        setState(() {
          deviceModels = deviceModelList;
          selectedDeviceModel = 'All';
          selectedDeviceModelId = -1;
        });
      }
    } catch (e) {
      print('Error loading device models: $e');
    }
  }

  Future<void> loadProductData() async {
    try {
      String url = '${ProductCategoryScreen.apiUrl}/products/';
      List<String> queryParams = [];

      if (selectedCategory != 'All' && selectedCategoryId != -1) {
        queryParams.add('category_id=$selectedCategoryId');
      }
      if (selectedBrand != 'All' && selectedBrandId != -1) {
        queryParams.add('brand_id=$selectedBrandId');
      }
      if (selectedDeviceModel != 'All' && selectedDeviceModelId != -1) {
        queryParams.add('device_model_id=$selectedDeviceModelId');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> productList = json.decode(response.body);
        List<Product> productsList = await Future.wait(
          productList
              .map((productJson) async => await Product.fromJson(productJson))
              .toList(),
        );
        setState(() {
          products = productsList;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  void resetFilters() {
    setState(() {
      selectedBrand = 'All';
      selectedBrandId = -1;
      selectedDeviceModel = 'All';
      selectedDeviceModelId = -1;
      brands = [];
      deviceModels = [];
    });
    loadProductData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // background
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text(
          "Product Categories",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildButtonSelection(
                      label: "Category",
                      selected: selectedCategory,
                      onSelected: (String newCategory) {
                        setState(() {
                          selectedCategory = newCategory;
                          if (selectedCategory == 'All') {
                            selectedCategoryId = -1;
                            resetFilters();
                          } else {
                            selectedCategoryId = categories
                                .firstWhere((cat) =>
                            cat['name'] == selectedCategory)['id'];
                            loadBrands(selectedCategoryId);
                          }
                          loadProductData();
                        });
                      },
                      items: ['All', ...categories.map((
                          c) => c['name'] as String)
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (selectedCategory != 'All')
                      _buildButtonSelection(
                        label: "Brand",
                        selected: selectedBrand,
                        onSelected: (String newBrand) {
                          setState(() {
                            selectedBrand = newBrand;
                            if (selectedBrand == 'All') {
                              selectedBrandId = -1;
                              deviceModels = [];
                              selectedDeviceModel = 'All';
                              selectedDeviceModelId = -1;
                            } else {
                              selectedBrandId = brands
                                  .firstWhere((b) =>
                              b['name'] == selectedBrand)['id'];
                              loadDeviceModels(selectedBrandId);
                            }
                          });
                          loadProductData();
                        },
                        items: [
                          'All',
                          ...brands.map((b) => b['name'] as String)
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (selectedBrand != 'All')
                      _buildButtonSelection(
                        label: "Device Model",
                        selected: selectedDeviceModel,
                        onSelected: (String newDeviceModel) {
                          setState(() {
                            selectedDeviceModel = newDeviceModel;
                            if (selectedDeviceModel == 'All') {
                              selectedDeviceModelId = -1;
                            } else {
                              selectedDeviceModelId = deviceModels
                                  .firstWhere((d) =>
                              d['name'] == selectedDeviceModel)['id'];
                            }
                          });
                          loadProductData();
                        },
                        items: ['All', ...deviceModels.map((
                            d) => d['name'] as String)
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Products Grid
                    products.isEmpty
                        ? const Center(
                      child: Text(
                        'No products available for the selected filters.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                        : GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth >= 1200
                            ? 4
                            : constraints.maxWidth >= 800
                            ? 3
                            : constraints.maxWidth >= 600
                            ? 2
                            : 2,
                        childAspectRatio: constraints.maxWidth >= 1200
                            ? 0.8
                            : constraints.maxWidth >= 800
                            ? 0.75
                            : 0.65,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(products[index]);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildButtonSelection({
    required String label,
    required String selected,
    required Function(String) onSelected,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items.map((item) {
            bool isSelected = selected == item;
            return GestureDetector(
              onTap: () => onSelected(item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [
                          Colors.green.withOpacity(0.9),
                          Colors.green.withOpacity(0.9),
                        ]
                            : [
                          Colors.blue.withOpacity(0.9),
                          Colors.blue.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: Image.network(
                      product.image1,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 50)),
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('\$${product.price}',
                      style: const TextStyle(color: Colors.green)),
                  Text('Rating: ${product.rating}',
                      style: const TextStyle(color: Colors.orange)),
                ],
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
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
          ),

          child: child,
        ),
      ),
    );
  }
}