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

class _SidebarState extends State<Sidebar> {
  String? logoUrl;

  @override
  void initState() {
    super.initState();
    fetchLogo();
  }

  Future<void> fetchLogo() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/store/logo/'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Logo URL: ${data['image_url']}"); // for debugging
      setState(() {
        logoUrl = data['image_url']; // <-- use image_url here
      });
    } else {
      print('Failed to fetch logo: ${response.statusCode}');
    }
  }


  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                logoUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    logoUrl!,
                    width: 150,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.flutter_dash, color: Colors.white, size: 90),
                  ),
                )

                    : const Icon(Icons.flutter_dash, color: Colors.white, size: 40),
                const SizedBox(width: 12),
                // Text(
                //   widget.title,
                //   style: const TextStyle(
                //     color: Colors.white,
                //     fontSize: 22,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(Icons.home, 'Home', 0),
                _buildDrawerItem(Icons.category, 'Category', 1),
                _buildDrawerItem(Icons.favorite, 'WishList', 2),
                _buildDrawerItem(Icons.shopping_cart, 'Cart', 3),
                _buildDrawerItem(Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String text, int index) {
    final isSelected = widget.selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[700],
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
      hoverColor: Colors.blue.withOpacity(0.05),
      onTap: () => widget.onItemTapped(index),
    );
  }
}
