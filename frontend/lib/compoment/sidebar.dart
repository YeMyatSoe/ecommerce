import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Sidebar extends StatefulWidget {
  final String title;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const Sidebar({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  _SidebarState createState() => _SidebarState();
}
int _hoveredIndex = -1;

class _SidebarState extends State<Sidebar> {
  String? logoUrl;

  @override
  void initState() {
    super.initState();
    fetchLogo();
  }

  Future<void> fetchLogo() async {
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/store/logo/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          logoUrl = data['image_url'];
        });
      } else {
        debugPrint('Failed to fetch logo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching logo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery
        .of(context)
        .size
        .width > 600;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                logoUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    logoUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.storefront, color: Colors.white, size: 70),
                  ),
                )
                    : const Icon(
                    Icons.storefront, color: Colors.white, size: 70),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(Icons.home, 'Home', 0),
                _buildDrawerItem(Icons.category, 'Category', 1),
                _buildDrawerItem(Icons.favorite, 'WishList', 2),
                _buildDrawerItem(Icons.shopping_cart, 'Cart', 3),
                _buildDrawerItem(Icons.person, 'Profile', 4),
                _buildDrawerItem(Icons.person, 'About', 6),
                _buildDrawerItem(Icons.person, 'Contact_Us', 7),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String text, int index) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(0.2)
                : (_hoveredIndex == index
                ? Colors.blue.withOpacity(0.08)
                : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isSelected
                  ? Colors.blue
                  : (_hoveredIndex == index ? Colors.blueGrey : Colors
                  .grey[700]),
            ),
            title: Text(
              text,
              style: TextStyle(
                color: isSelected
                    ? Colors.blue
                    : (_hoveredIndex == index ? Colors.blueGrey : Colors
                    .grey[800]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () => widget.onItemTapped(index),
          ),
        ),
      ),
    );
  }
}