import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/compoment/bottombar.dart';
import 'package:frontend/compoment/sidebar.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/model/products.dart';
import 'package:frontend/provider/auth_provider.dart';
import 'package:frontend/provider/cart_provider.dart';
import 'package:frontend/provider/wishlist_provider.dart';
import 'package:frontend/screen/about.dart';
import 'package:frontend/screen/category.dart';
import 'package:frontend/screen/checkout.dart';
import 'package:frontend/screen/contact.dart';
import 'package:frontend/screen/homescreen.dart';
import 'package:frontend/screen/login.dart';
import 'package:frontend/screen/orderhistory.dart';
import 'package:frontend/screen/popular.dart';
import 'package:frontend/screen/profilescreen.dart';
import 'package:frontend/screen/register.dart';
import 'package:frontend/screen/searchresult.dart';
import 'package:frontend/screen/shoppingcart.dart';
import 'package:frontend/screen/wishlistscreen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:frontend/compoment/footer.dart';
// --- THEME PROVIDER ---
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;
  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }
}

// --- MAIN ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  String savedLanguage = prefs.getString('language') ?? 'en';
  final cartProvider = CartProvider();
  await cartProvider.loadCartFromBackend(); // Load cart at app start
  final authProvider = AuthProvider();
  await authProvider.checkLoginStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDarkMode)),
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MyApp(savedLanguage: savedLanguage),
    ),
  );
}

// --- MY APP ---
class MyApp extends StatefulWidget {
  final String savedLanguage;
  const MyApp({super.key, required this.savedLanguage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String currentLanguage;

  @override
  void initState() {
    super.initState();
      final cartProvider = context.read<CartProvider>();
  cartProvider.loadCartFromBackend(); // Always fetch cart

    currentLanguage = widget.savedLanguage;
  }

  void changeLanguage(String languageCode) {
    setState(() {
      currentLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      locale: Locale(currentLanguage),
      supportedLocales: const [Locale('en', 'US'), Locale('my', 'MM')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(
              savedLanguage: currentLanguage,
              onLanguageChanged: changeLanguage,
            ),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterPage(),
        '/checkout': (context) => CheckoutPage(),
        '/products': (context) => const ProductCategoryScreen(),
        '/category': (context) => const ProductCategoryScreen(),
        '/about': (context) => const AboutPage(),
        // '/terms': (context) => const TermsPage(),
        // '/privacy': (context) => const PrivacyPage(),
        '/contact': (context) => const ContactUsPage(),
      },
    );
  }
}

// --- HOME PAGE ---
class HomePage extends StatefulWidget {
  final String savedLanguage;
  final Function(String) onLanguageChanged;

  const HomePage({
    super.key,
    required this.savedLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isSearchBoxVisible = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ProductCategoryScreen(),
    WishlistScreen(),
    const ShoppingCartScreen(),
    const ProfileScreen(),
    OrderHistoryScreen(),
    const AboutPage(),
    const ContactUsPage()
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onSearchChanged(String query) {
    // Debounce to prevent too many API calls
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        // Trigger rebuild so ProductSearchResultsScreen refreshes
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appTitle = AppLocalizations.of(context)!.appTitle;
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(

      appBar: AppBar(
        title: _isSearchBoxVisible
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        )
            : Text(appTitle),
        actions: [
          Builder(
            builder: (context) {
              bool isMobile = MediaQuery.of(context).size.width < 600;

              // Only show search icon on mobile
              if (isMobile) {
                return IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: () {
                    setState(() {
                      _isSearchBoxVisible = !_isSearchBoxVisible;
                      if (!_isSearchBoxVisible) _searchController.clear();
                    });
                  },
                );
              }

              // Full menu for tablet/desktop
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearchBoxVisible = !_isSearchBoxVisible;
                        if (!_isSearchBoxVisible) _searchController.clear();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.home),
                    tooltip: 'Home',
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0;
                        _isSearchBoxVisible = false;
                        _searchController.clear();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.category),
                    tooltip: 'Categories',
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                        _isSearchBoxVisible = false;
                        _searchController.clear();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite),
                    tooltip: 'Wishlist',
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2;
                        _isSearchBoxVisible = false;
                        _searchController.clear();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.question_mark),
                    tooltip: 'About',
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 6;
                        _isSearchBoxVisible = false;
                        _searchController.clear();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.contact_page),
                    tooltip: 'Contact_Us',
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 7;
                        _isSearchBoxVisible = false;
                        _searchController.clear();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: 'Cart',
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                        _isSearchBoxVisible = false;
                        _searchController.clear();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    tooltip: 'Profile',
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                  ),
                ],
              );
            },
          )
        ],
      ),

      drawer: MediaQuery.of(context).size.width < 600
          ? Sidebar(
        title: appTitle,
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
            _isSearchBoxVisible = false;
            _searchController.clear();
          });
        },
      )
          : null,
      body: CustomScrollView( // Use CustomScrollView for advanced scrolling
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
                [
                  // Main Content Area: Wrap the currently selected page
                  SizedBox(
                    // Use the view port height as the minimum height
                    // This ensures the footer is pushed off-screen if content is short
                    height: MediaQuery.of(context).size.height -
                        (AppBar().preferredSize.height) -
                        (isMobile ? kBottomNavigationBarHeight : 0),
                    width: double.infinity,
                    child: _isSearchBoxVisible && _searchController.text.isNotEmpty
                        ? ProductSearchResultsScreen(
                      key: ValueKey(_searchController.text),
                      query: _searchController.text,
                    )
                        : _pages[_selectedIndex], // Your main screen content
                  ),
                ]
            ),
          ),

          // The Footer, placed as a separate sliver at the end
          if (kIsWeb)
            SliverToBoxAdapter(
              child: const CustomFooter(),
            ),
        ],
      ),
      bottomNavigationBar: !kIsWeb
          ? SizedBox(
        height: MyBottomBar.barHeight , // ✅ include curve
        child: Align(
          alignment: Alignment.bottomCenter,
          child: MyBottomBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            cartItemCount: Provider.of<CartProvider>(context).totalQuantity,
          ),
        ),
      )
          : null,
    );
  }
}


// --- SETTINGS PAGE (without dark mode toggle) ---
class SettingsScreen extends StatefulWidget {
  final String savedLanguage;
  final Function(String) onLanguageChanged;

  const SettingsScreen(
      {super.key, required this.savedLanguage, required this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'en';
  bool _isNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _language = widget.savedLanguage;
  }

  void _toggleLanguage() {
    setState(() {
      _language = (_language == 'en') ? 'my' : 'en';
    });
    widget.onLanguageChanged(_language);
  }

  void _toggleLoginStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      await authProvider.logout(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Logged out successfully')));
    } else {
      bool result = await Navigator.push(
            context, MaterialPageRoute(builder: (_) => LoginScreen()),
          ) ??
          false;
      if (result) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Logged in successfully')));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_language == 'en' ? 'English' : 'Myanmar'),
            onTap: _toggleLanguage,
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _isNotificationsEnabled,
            onChanged: (value) {
              setState(() => _isNotificationsEnabled = value);
            },
          ),
          const ListTile(
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return ListTile(
                title: Text(authProvider.isLoggedIn ? 'Logout' : 'Login'),
                onTap: _toggleLoginStatus,
              );
            },
          ),
        ],
      ),
    );
  }
}
