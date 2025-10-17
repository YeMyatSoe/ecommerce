import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int cartItemCount;

  const MyBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.cartItemCount = 0,
  });

  // --- Design constants (POLISHED UI) ---
  static const double barHeight = 45; // Optimal bar height for mobile
  static const double curveHeight  = 10; // Moderate, noticeable notch height
  static const Color activeColor = Color(0xFF1E88E5); // Clean, professional blue
  static const Color inactiveColor = Colors.white70;
  static const Color barBackgroundColor = Colors.black;
  static const double iconLift = 8; // Lifted icon centered in the notch
  static const double activeIconSize = 24; // Slightly larger active icon
  static const double inactiveIconSize = 24;
  // -----------------------------------------

  @override
  Widget build(BuildContext context) {
    final double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double segmentWidth = screenWidth / 5.0; // The fixed width slice for each item

    return SizedBox(
      height: barHeight + safeAreaBottom,
      child: Stack(
        children: [
          // Bar background with upward curve (The Notch)
          CustomPaint(
            size: Size(double.infinity, barHeight),
            painter: _NavBarPainter(
              selectedIndex: selectedIndex,
              curveHeight : curveHeight,
              itemCount: 5,
              barColor: barBackgroundColor,
              activeColor: activeColor,
            ),
          ),

          // Navigation icons (Aligned perfectly using segment widths)
          Padding(
            padding: EdgeInsets.only(bottom: safeAreaBottom),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: screenWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildItem(0, Icons.home_rounded),
                    _buildItem(1, Icons.category_rounded),
                    _buildItem(2, Icons.favorite_rounded),
                    _buildCartItem(3, Icons.shopping_cart_rounded),
                    _buildItem(4, Icons.person_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Icon Builders (Smooth lift and correct sizing) ---
  Widget _buildItem(int index, IconData icon) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: SizedBox(
        width: 60, // Fixed width for consistent spacing regardless of screen width
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, isActive ? -iconLift : 0, 0),
          curve: Curves.easeOutCubic, // Sharp, professional animation curve
          child: Icon(
            icon,
            color: isActive ? activeColor : inactiveColor,
            size: isActive ? activeIconSize : inactiveIconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(int index, IconData icon) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: SizedBox(
        width: 60, // Fixed width for consistent spacing
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Icon (aligned to center of SizedBox)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.translationValues(0, isActive ? -iconLift : 0, 0),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: isActive ? activeIconSize : inactiveIconSize,
              ),
            ),
            if (cartItemCount > 0)
              Positioned(
                right: 8, // Positioned relative to the 60px container
                top: isActive ? (-iconLift + 5) : 5, // Lifts with the icon
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  alignment: Alignment.center,
                  child: Text(
                    cartItemCount > 9 ? '9+' : '$cartItemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Painter (Cubic curve for visual smoothness and exact alignment) ---
class _NavBarPainter extends CustomPainter {
  final int selectedIndex;
  final double curveHeight;
  final int itemCount;
  final Color barColor;
  final Color activeColor;

  _NavBarPainter({
    required this.selectedIndex,
    required this.curveHeight,
    required this.itemCount,
    required this.barColor,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // The key to exact alignment: Center of the curve must match the center of the segment.
    final double segmentWidth = width / itemCount;
    final double centerX = (selectedIndex + 0.5) * segmentWidth;

    // Curve width slightly larger than a single icon's segment for cushion
    final double bumpWidth = segmentWidth * 1.0;
    final double halfBump = bumpWidth/2 ;

    final Paint barPaint = Paint()..color = barColor;
    final Path barPath = Path();

    // 1. Draw bar from bottom-left to top-left
    barPath.moveTo(0, height);
    barPath.lineTo(0, 0);

    // 2. Line to the start of the notch
    barPath.lineTo(centerX - halfBump, 0);

    // 3. Smooth Cubic Curve UP
    barPath.cubicTo(
      centerX - halfBump * 0.5, 0,
      centerX - halfBump * 0.4, -curveHeight * 0.9,
      centerX, -curveHeight * 1.1, // Peak slightly above curveHeight
    );
    barPath.cubicTo(
      centerX + halfBump * 0.4, -curveHeight * 0.9,
      centerX + halfBump * 0.5, 0,
      centerX + halfBump, 0,
    );

    // 4. Complete the path
    barPath.lineTo(width, 0);
    barPath.lineTo(width, height);
    barPath.close();

    canvas.drawPath(barPath, barPaint);

    // Optional: Draw a subtle highlight/glow over active curve
    final Paint highlightPaint = Paint()
      ..color = activeColor.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Path highlightPath = Path()
      ..moveTo(centerX - halfBump, 0)
      ..cubicTo(
        centerX - halfBump * 0.5, 0,
        centerX - halfBump * 0.4, -curveHeight * 0.9,
        centerX, -curveHeight * 1.1,
      )
      ..cubicTo(
        centerX + halfBump * 0.4, -curveHeight * 0.9,
        centerX + halfBump * 0.5, 0,
        centerX + halfBump, 0,
      );

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
          oldDelegate.curveHeight != curveHeight ||
          oldDelegate.barColor != barColor ||
          oldDelegate.activeColor != activeColor;
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
