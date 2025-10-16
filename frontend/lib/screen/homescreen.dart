import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:frontend/model/category.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/model/banners.dart' as custom_banner;
import 'package:frontend/screen/product_detail.dart';
import 'package:frontend/screen/bestselling.dart';
import 'package:frontend/screen/popular.dart';
import 'package:frontend/screen/discount.dart';
import 'package:frontend/services/prodct_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  late ScrollController _scrollController;

  List<Product> products = [];
  List<custom_banner.Banner> banners = [];
  List<BestSellingProduct> bestSellingProducts = [];
  List<Category> categories = [];

  bool isLoading = false;
  final _storage = const FlutterSecureStorage();

  int _activeIndex = 0; // Active carousel index

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _scrollController = ScrollController();
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    String? accessToken = await _storage.read(key: 'access_token');
    print("Access Token from storage home: $accessToken");
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      final productService = ProductService();
      final results = await Future.wait([
        productService.fetchProducts(),
        productService.fetchBanners(),
        productService.fetchCategories(),
        productService.fetchBestSellingProducts(),
      ]);

      setState(() {
        products = results[0] as List<Product>? ?? [];
        banners = results[1] as List<custom_banner.Banner>? ?? [];
        categories = results[2] as List<Category>? ?? [];
        bestSellingProducts = results[3] as List<BestSellingProduct>? ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching data: $e');
    }
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxContentWidth = 1200;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A11CB),
                Color(0xFF2575FC),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: screenWidth > maxContentWidth ? maxContentWidth : screenWidth,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBannerCarousel(),
                    const SizedBox(height: 12),
                    _buildSectionTitle(
                      "Best Selling",
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BestSellingPage(bestSellingProducts: bestSellingProducts),
                        ),
                      ),
                      bestSellingProducts.length > 4,
                    ),
                    _buildBestSellingSection(bestSellingProducts),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      "Popular Items",
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PopularPage(
                            popularProducts: products.where((p) => p.rating > 3.0).toList(),
                          ),
                        ),
                      ),
                      products.where((p) => p.rating > 3.0).length > 4,
                    ),
                    _buildCategorySection(products.where((p) => p.rating > 3.0).toList()),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      "Discounts",
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiscountPage(
                            discountedProducts: products.where((p) => p.discount > 0).toList(),
                          ),
                        ),
                      ),
                      products.where((p) => p.discount > 0).length > 4,
                    ),
                    _buildCategorySection(products.where((p) => p.discount > 0).toList()),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    double screenWidth = MediaQuery.of(context).size.width;
    double carouselHeight = screenWidth * 0.4;

    final bannerImages = banners.isEmpty
        ? []
        : banners.expand((banner) => banner.images.take(4)).toList();

    if (bannerImages.isEmpty) {
      return SizedBox(
        height: carouselHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: carouselHeight,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        enlargeCenterPage: true,
        viewportFraction: screenWidth < 600 ? 0.8 : 0.6,
        enableInfiniteScroll: true,
        scrollPhysics: const BouncingScrollPhysics(),
      ),
      items: bannerImages.map((img) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(img.image),
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onPressed, bool hasMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Divider(
              thickness: 1,
              indent: 12,
              color: Colors.white54,
            ),
          ),
          if (hasMore)
            TextButton.icon(
              onPressed: onPressed,
              icon: const Text(
                "See More",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              label: const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------ BEST SELLING ------------------
  Widget _buildBestSellingSection(List<BestSellingProduct> bestSelling) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (bestSelling.isEmpty) return const Center(child: Text("No best selling products available."));

    var items = bestSelling.take(8).toList();
    bool useCarousel = screenWidth < 600;

    if (useCarousel) {
      return CarouselSlider.builder(
        itemCount: items.length,
        itemBuilder: (context, index, realIndex) {
          bool isActive = _activeIndex == index;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isActive ? 1.0 : 0.5,
            child: AnimatedScale(
              scale: isActive ? 1.05 : 0.9,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: _buildLiquidGlassCard(items[index].toProduct()),
            ),
          );
        },
        options: CarouselOptions(
          height: 260,
          viewportFraction: 0.6,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
          onPageChanged: (index, reason) {
            setState(() => _activeIndex = index);
          },
        ),
      );
    } else {
      double maxWidth = 1200;
      double totalWidth = screenWidth > maxWidth ? maxWidth : screenWidth - 32;
      double cardWidth = (totalWidth - 16 * (2 - 1)) / 2;
      double cardHeight = 240;
      double childAspectRatio = cardWidth / cardHeight;

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildLiquidGlassCard(items[index].toProduct()),
          ),
        ),
      );
    }
  }

  // ------------------ CATEGORY SECTION ------------------
  Widget _buildCategorySection(List<Product> items) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (items.isEmpty) return const Center(child: Text("No products available."));

    int maxItems = 6;
    var visibleItems = items.take(maxItems).toList();
    bool useCarousel = screenWidth < 600;

    if (useCarousel) {
      return CarouselSlider.builder(
        itemCount: items.length,
        itemBuilder: (context, index, realIndex) {
          double diff = (index - _activeIndex).toDouble();

          // Use a curve for smooth vertical movement
          double verticalOffset = 20 * diff.abs(); // cards rise/fall slightly
          double scale = 1.0 - (0.1 * diff.abs());
          double opacity = 1.0 - (0.5 * diff.abs());

          // Clamp values
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
    } else {
      double maxWidth = 1200;
      double totalWidth = screenWidth > maxWidth ? maxWidth : screenWidth - 32;
      double cardWidth = (totalWidth - 16 * (2 - 1)) / 2;
      double cardHeight = 260;
      double childAspectRatio = cardWidth / cardHeight;

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: visibleItems.length,
            itemBuilder: (context, index) => _buildLiquidGlassCard(visibleItems[index]),
          ),
        ),
      );
    }
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
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
              ],
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      product.image1,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
                  child: Text(
                    "\$${product.finalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.0),
                  child: Text(
                    "Rating: ${product.rating}",
                    style: const TextStyle(fontSize: 14, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
