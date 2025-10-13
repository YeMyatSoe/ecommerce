import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screen/profilescreen.dart';
import 'package:frontend/screen/register.dart';
import 'package:frontend/screen/shoppingcart.dart';



class CustomMenuBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final TextEditingController searchController;
  final bool isSearchVisible;
  final Function(bool) onSearchToggle;
  final Function(String) onSearchChanged;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  const CustomMenuBar({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.searchController,
    required this.isSearchVisible,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: isSearchVisible
          ? TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
              autofocus: true,
              onChanged: onSearchChanged,
              style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black),
            )
          : Text(title),
      actions: [
        // Main menu shortcuts
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Home',
          onPressed: () => onItemTapped(0),
        ),
        IconButton(
          icon: const Icon(Icons.category),
          tooltip: 'Categories',
          onPressed: () => onItemTapped(1),
        ),
        IconButton(
          icon: const Icon(Icons.favorite),
          tooltip: 'Wishlist',
          onPressed: () => onItemTapped(2),
        ),
        const SizedBox(width: 8),

        // Sub-menu
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => onSearchToggle(!isSearchVisible),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => ShoppingCartScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.app_registration),
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage())),
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
        ),
        IconButton(
          icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => onThemeToggle(!isDarkMode),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                        savedLanguage: 'en', // pass your savedLanguage
                        onLanguageChanged: (_) {},
                      ))),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
