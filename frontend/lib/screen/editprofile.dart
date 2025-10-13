import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final _storage = FlutterSecureStorage();

class EditProfileScreen extends StatefulWidget {
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String city;
  final String postalCode;

  const EditProfileScreen({
    Key? key,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.postalCode,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;

  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
    _phoneNumberController = TextEditingController(text: widget.phoneNumber);
    _addressController = TextEditingController(text: widget.address);
    _cityController = TextEditingController(text: widget.city);
    _postalCodeController = TextEditingController(text: widget.postalCode);

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  Future<void> _updateProfile() async {
    String? token = await _storage.read(key: 'auth_token');

    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill out all fields'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final response = await http.put(
      Uri.parse('http://10.0.2.2:8000/api/store/editprofile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'username': _usernameController.text,
        'email': _emailController.text,
        'phone_number': _phoneNumberController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'postal_code': _postalCodeController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update profile'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String? token = await _storage.read(key: 'auth_token');
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8000/api/store/editprofile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'current_password': _currentPasswordController.text,
        'new_password': _newPasswordController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Password updated successfully'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to change password'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget _buildButton(String title, Color color, VoidCallback onPressed, double screenWidth) {
    double buttonWidth = screenWidth < 600 ? double.infinity : 250; // smaller width on web
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

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(

      appBar: AppBar(title: Text("Edit Profile")),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600), // Limit width for web
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: _usernameController, decoration: InputDecoration(labelText: 'Username')),
                TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
                TextField(controller: _phoneNumberController, decoration: InputDecoration(labelText: 'Phone Number')),
                TextField(controller: _addressController, decoration: InputDecoration(labelText: 'Address')),
                TextField(controller: _cityController, decoration: InputDecoration(labelText: 'City')),
                TextField(controller: _postalCodeController, decoration: InputDecoration(labelText: 'Postal Code')),
                SizedBox(height: 20),
                TextField(controller: _currentPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'Current Password')),
                TextField(controller: _newPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'New Password')),
                TextField(controller: _confirmPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'Confirm New Password')),
                SizedBox(height: 20),
                _buildButton('Update Profile', Colors.green, _updateProfile, screenWidth),
                _buildButton('Change Password', Colors.blue, _changePassword, screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
