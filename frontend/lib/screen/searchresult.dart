import 'package:flutter/material.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/screen/product_detail.dart';
class ProductSearchResultsScreen extends StatefulWidget {
  final String query;
  const ProductSearchResultsScreen({super.key, required this.query});

  @override
  _ProductSearchResultsScreenState createState() =>
      _ProductSearchResultsScreenState();
}

class _ProductSearchResultsScreenState
    extends State<ProductSearchResultsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void didUpdateWidget(covariant ProductSearchResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    if (widget.query.isEmpty) {
      setState(() {
        _products = [];
        _loading = false;
        _error = '';
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final products = await Product.fetchListByPrefix(widget.query);
      setState(() {
        _products = products;
        _loading = false;
        _error = products.isEmpty ? 'No products found' : '';
      });
    } catch (e) {
      setState(() {
        _error = 'Error fetching products';
        _loading = false;
      });
    }
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Results")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            leading: product.image1.isNotEmpty
                ? Image.network(
              product.image1,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : null,
            title: Text(product.name),
            subtitle: Text('\$${product.finalPrice.toStringAsFixed(2)}'),
            onTap: () => _navigateToProductDetail(product),
          );
        },
      ),
    );
  }
}
