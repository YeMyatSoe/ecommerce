import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/screen/editprofile.dart';
import 'package:frontend/screen/orderhistory.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final _storage = FlutterSecureStorage();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = '';
  String email = '';
  String phoneNumber = '';
  String address = '';
  String city = '';
  String postalCode = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    String? token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      _redirectToLogin();
    } else {
      try {
        Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
        int expiryTime = decodedToken['exp'];
        DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTime * 1000);
        if (expiryDate.isBefore(DateTime.now())) {
          await _storage.delete(key: 'auth_token');
          _redirectToLogin();
        } else {
          _getUserProfile();
        }
      } catch (e) {
        await _storage.delete(key: 'auth_token');
        _redirectToLogin();
      }
    }
  }

  Future<void> _getUserProfile() async {
    String? token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/store/profile/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'] ?? 'No Username';
          email = data['email']?.isNotEmpty == true ? data['email'] : 'No Email';
          phoneNumber = data['phone_number'] ?? 'No Phone Number';
          address = data['address'] ?? 'No Address';
          city = data['city'] ?? 'No City';
          postalCode = data['postal_code'] ?? 'No Postal Code';
        });
      } catch (e) {
        print('Error parsing profile data: $e');
      }
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _OrderHistory(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryScreen()));
  }

  void _goToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          address: address,
          city: city,
          postalCode: postalCode,
        ),
      ),
    );
  }
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  // Define max width for web/desktop
  double maxContentWidth = 800; // Adjust as needed

  return Scaffold(
    backgroundColor: Colors.blue, // background
    body: Center( // Center the content horizontally
      child: Container(
        width: screenWidth < maxContentWidth ? screenWidth : maxContentWidth, // Limit max width
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: screenWidth < 600 ? 50 : 70,
                        backgroundImage: NetworkImage('https://www.example.com/profile_pic.jpg'),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username.isEmpty ? 'Loading...' : username,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              email.isEmpty ? 'Loading...' : email,
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Info Section (Phone, Address, City, Postal)
              _infoCard("Phone Number", phoneNumber),
              _infoCard("Address", address),
              _infoCard("City", city),
              _infoCard("Postal Code", postalCode),
              SizedBox(height: 20),

              // Action Buttons (Edit, Orders, Logout)
              _actionButton("Edit Profile", Colors.white, _goToEditProfile, screenWidth),
              _actionButton("Order History", Colors.blue, () => _OrderHistory(context), screenWidth),
              _actionButton("Log Out", Colors.red, () async {
                await _storage.delete(key: 'auth_token');
                _redirectToLogin();
              }, screenWidth),
              SizedBox(height: 20),

              // Loyalty Points, Payment Methods, Notifications, Support...
              _sectionTitle("Loyalty Points"),
              _infoCard("Points", "You have 500 points. Redeem for discounts!"),

              _sectionTitle("Payment Methods"),
              _infoCard("Card", "Visa - **** 1234"),
              _actionButton("Add Payment Method", Colors.white, () {}, screenWidth),

              _sectionTitle("Notifications"),
              _switchTile("Email Notifications", true),
              _switchTile("SMS Notifications", false),

              _sectionTitle("Customer Support"),
              _actionButton("Contact Support", Colors.green, () {}, screenWidth),
              _actionButton("Visit Help Center", Colors.green, () {}, screenWidth),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _infoCard(String title, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isEmpty ? "Loading..." : value),
        trailing: Icon(Icons.edit, color: Colors.grey[700]),
      ),
    );
  }
Widget _actionButton(String title, Color color, VoidCallback onPressed, double screenWidth) {
  double buttonWidth = screenWidth < 600 ? double.infinity : 200; // 200px max width on web
  double buttonHeight = 45;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: onPressed,
        child: Text(title, style: TextStyle(fontSize: 16)),
      ),
    ),
  );
}

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _switchTile(String title, bool value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Switch(value: value, onChanged: (v) {}),
      ),
    );
  }
}
