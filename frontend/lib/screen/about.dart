import 'dart:ui';
import 'package:flutter/material.dart';
import '../model/about_model.dart';
import '../services/aboutservice.dart';
import '../compoment/footer.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late ScrollController _scrollController;
  int _currentBlogPage = 0;
  AboutPageModel? about;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await AboutService.fetchAboutData();
      setState(() {
        about = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error || about == null) return const Center(child: Text("Failed to load data"));

    final totalBlogs = about!.blogs.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bannerSection(context),
            _sectionAltLayout(
              title: about!.title,
              description: about!.description,
              imageUrl: about!.customersMapImage,
              reverse: false,
            ),
            _sectionAltLayout(
              title: about!.historyTitle,
              description: about!.historyDescription,
              imageUrl: about!.blogs.isNotEmpty ? about!.blogs[0].imageUrl : about!.customersMapImage,
              reverse: true,
            ),
            _blogsSection(totalBlogs),
            _customersSection(),
            _partnersSection(),

          ],
        ),
      ),
    );
  }

  // 🔹 Banner Section
  Widget _bannerSection(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double height = screenWidth >= 1200
        ? 500
        : screenWidth >= 800
        ? 400
        : screenWidth >= 600
        ? 300
        : 220;

    bool isMobile = screenWidth < 600;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(about!.image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: height,
          color: Colors.black.withOpacity(0.4),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: isMobile
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bannerButton(context, "Shop Now", Colors.white, Colors.deepPurple, '/home'),
              const SizedBox(height: 12),
              _bannerButton(context, "Contact Us", Colors.deepPurpleAccent, Colors.white, '/contact'),
            ],
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bannerButton(context, "Shop Now", Colors.white, Colors.deepPurple, '/'),
              const SizedBox(width: 16),
              _bannerButton(context, "Contact Us", Colors.deepPurpleAccent, Colors.white, '/contact'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerButton(BuildContext context, String text, Color bgColor, Color fgColor, String route) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _sectionAltLayout({
    required String title,
    required String description,
    required String imageUrl,
    required bool reverse,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;
        final isTablet = width >= 700 && width < 1200;

        final double imageHeight = isMobile
            ? 220
            : isTablet
            ? 320
            : 420;

        final double titleSize = isMobile
            ? 24
            : isTablet
            ? 28
            : 36;

        final double descSize = isMobile
            ? 16
            : isTablet
            ? 17
            : 18;

        return Container(
          color: reverse ? const Color(0xFFF4F0FF) : Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 40 : 80,
            horizontal: isMobile ? 16 : 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: isMobile
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      height: imageHeight,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: descSize,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
                  : Row(
                textDirection: reverse ? TextDirection.rtl : TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          height: imageHeight,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: descSize,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔹 Blogs Section
  Widget _blogsSection(int totalBlogs) {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text("Our Blogs",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 30),
              LayoutBuilder(builder: (context, constraints) {
                int itemsPerRow = 1;
                if (constraints.maxWidth >= 1200) {
                  itemsPerRow = 6;
                } else if (constraints.maxWidth >= 800) {
                  itemsPerRow = 3;
                }
                final blogsPerPage = itemsPerRow;
                final totalPages = (totalBlogs / blogsPerPage).ceil();
                final start = _currentBlogPage * blogsPerPage;
                final end = (start + blogsPerPage > totalBlogs) ? totalBlogs : start + blogsPerPage;
                final currentBlogs = about!.blogs.sublist(start, end);

                return Column(
                  children: [
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: currentBlogs.map((blog) {
                        double cardWidth = (constraints.maxWidth - ((itemsPerRow - 1) * 20)) / itemsPerRow;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: cardWidth,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(blog.imageUrl),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                            ],
                          ),
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black.withOpacity(0.4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(blog.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(totalPages, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _currentBlogPage = index),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: _currentBlogPage == index ? Colors.deepPurple : Colors.grey[300],
                            child: Text("${index + 1}",
                                style: TextStyle(
                                    color: _currentBlogPage == index ? Colors.white : Colors.black87)),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Customers Section
  Widget _customersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                about!.customersTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  about!.customersMapImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Partners Section
  Widget _partnersSection() {
    return Container(
      color: const Color(0xFFF0ECFF),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text("Our Partners",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 30),
              Wrap(
                spacing: 40,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: about!.partners.map((p) {
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundImage: NetworkImage(p.logoUrl),
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(p.name,
                          style: const TextStyle(
                              color: Colors.black87, fontWeight: FontWeight.w600)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
