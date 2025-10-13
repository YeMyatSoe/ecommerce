import 'package:flutter/material.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/screen/product_detail.dart';

class BestSellingPage extends StatelessWidget {
  final List<BestSellingProduct> bestSellingProducts;

  const BestSellingPage({super.key, required this.bestSellingProducts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Text("BestSellingProducts",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              bestSellingProducts.isEmpty
                  ? Center(child: Text('No Best Selling Products'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount;
                        double itemAspectRatio;

                        if (constraints.maxWidth >= 1200) {
                          crossAxisCount = 4;
                          itemAspectRatio = 1.20;
                        } else if (constraints.maxWidth >= 800) {
                          crossAxisCount = 3;
                          itemAspectRatio = 0.8;
                        } else {
                          crossAxisCount = 1;
                          itemAspectRatio = 1.20;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: itemAspectRatio,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: bestSellingProducts.length,
                          itemBuilder: (context, index) {
                            var product = bestSellingProducts[index];
                            return _buildProductCard(context, product);
                          },
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, BestSellingProduct product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(context, product.toProduct()),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: Colors.black45,
        color: Colors.white,
        child: Stack(
          children: [
            // Main content of the product card
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    product.image1.isNotEmpty
                        ? product.image1
                        : 'fallback_image_url',
                    height: 100,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/placeholder_image.png');
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, top: 12, bottom: 12),
                  child: Row(
                    children: [
                      if (product.discount > 0) ...[
                        Text(
                          "\$${product.price.toStringAsFixed(2)}", // Original Price
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "\$${product.finalPrice.toStringAsFixed(2)}", // Final Price
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          "\$${product.price.toStringAsFixed(2)}", // Regular Price
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Rating: ${product.rating}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                      elevation: 5,
                    ),
                    onPressed: () {
                      _navigateToProductDetail(context, product.toProduct());
                    },
                    child: Text(
                      'View',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
            // Stock status in top-right corner
            Positioned(
              top: 8,
              right: 8,
              child: _buildStockStatus(product),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  Widget _buildStockStatus(BestSellingProduct product) {
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

  String _getStockStatusText(BestSellingProduct product) {
    if (product.stock > 1) {
      return "In Stock";
    } else if (product.stock == 1) {
      return "Only 1 Left!";
    } else {
      return "Out of Stock";
    }
  }

  Color _getStockStatusColor(BestSellingProduct product) {
    if (product.stock > 1) {
      return Colors.green;
    } else if (product.stock == 1) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
