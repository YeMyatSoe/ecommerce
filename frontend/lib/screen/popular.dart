import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/screen/product_detail.dart';

class PopularPage extends StatelessWidget {
  final List<Product> popularProducts;

  const PopularPage({super.key, required this.popularProducts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // background
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text(
          "Popular Products",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            double childAspectRatio = 0.7;

            if (constraints.maxWidth >= 1400) {
              crossAxisCount = 5;
              childAspectRatio = 0.7;
            } else if (constraints.maxWidth >= 1200) {
              crossAxisCount = 6;
              childAspectRatio = 0.7;
            } else if (constraints.maxWidth >= 900) {
              crossAxisCount = 4;
              childAspectRatio = 0.65;
            } else if (constraints.maxWidth >= 600) {
              crossAxisCount = 2;
              childAspectRatio = 0.75;
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: popularProducts.isEmpty
                    ? const Center(child: Text('No Popular Products Available'))
                    : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: popularProducts.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(context, popularProducts[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(context, product),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25), // frosted glass
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          product.image1.isNotEmpty
                              ? product.image1
                              : 'fallback_image_url',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Image.asset('assets/placeholder_image.png',
                                  fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(top: 8, right: 8, child: _buildStockStatus(product)),
                    ],
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            if (product.discount > 0) ...[
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "\$${product.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "\$${product.finalPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                              ),
                            ] else ...[
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "\$${product.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rating: ${product.rating}',
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                      const SizedBox(height: 6),

                      // Liquid glass button
                      SizedBox(
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.green.withOpacity(0.9), // semi glass
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _navigateToProductDetail(context, product),
                              child: const Text(
                                'View',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockStatus(Product product) {
    Color color;
    String text;
    if (product.stock > 1) {
      color = Colors.green;
      text = "In Stock";
    } else if (product.stock == 1) {
      color = Colors.orange;
      text = "Only 1 Left!";
    } else {
      color = Colors.red;
      text = "Out of Stock";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
}
