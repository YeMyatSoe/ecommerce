import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/cart_provider.dart';

class MyBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int cartItemCount;

  const MyBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.cartItemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildItem(context, 0, Icons.home, 'Home'),
                _buildItem(context, 1, Icons.category, 'Category'),
                _buildItem(context, 2, Icons.favorite, 'WishList'),
                _buildCartItem(context),
                _buildItem(context, 4, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index, IconData icon, String label) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.blueGrey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context) {
    bool isSelected = selectedIndex == 3;
    return GestureDetector(
      onTap: () => onItemTapped(3),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart, color: isSelected ? Colors.deepPurple : Colors.blueGrey),
              const SizedBox(height: 4),
              Text(
                'Cart',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.deepPurple : Colors.blueGrey,
                ),
              ),
            ],
          ),
          if (cartItemCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  cartItemCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<Setting> {
  int _selectedIndex = 0;
  int _cartItemCount = 0;

  final List<Widget> _pages = [
    Center(child: Text('Home Screen')),
    Center(child: Text('Category Screen')),
    Center(child: Text('WishList Screen')),
    Center(child: Text('Cart Screen')),
    Center(child: Text('Profile Screen')),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _addItemToCart() {
    setState(() => _cartItemCount++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          "My Shop",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          CupertinoSearchTextField(
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemColor: Colors.blueAccent,
            onChanged: (value) => print("Search: $value"),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: Icon(CupertinoIcons.settings, color: Colors.black87, size: 28),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _addItemToCart,
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add),
        tooltip: "Add Item",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MyBottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        cartItemCount: _cartItemCount,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Setting(),
  ));
}
