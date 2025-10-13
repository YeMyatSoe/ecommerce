import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _isLoading = false;
  String _message = '';

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final url = Uri.parse('http://10.0.2.2:8000/api/store/register/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'confirm_password': _confirmPasswordController.text,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'postal_code': _postalCodeController.text,
      }),
    );

    setState(() {
      _isLoading = false;
      if (response.statusCode == 201) {
        _message = 'User registered successfully!';
      } else {
        _message = 'Registration failed: ${response.statusCode} - ${response.body}';
      }
    });
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
            borderRadius: BorderRadius.circular(30),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1.5),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.deepPurple),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
          borderRadius: BorderRadius.circular(30),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1.5),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3E8BFD), Color(0xFF3E8BFD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 700),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Create Your Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 30),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: isSmallScreen
                              ? [
                                  _buildTextField(_usernameController, 'Username', Icons.person),
                                  _buildTextField(_emailController, 'Email', Icons.email),
                                  _buildPasswordField(_passwordController, 'Password', Icons.lock),
                                  _buildPasswordField(_confirmPasswordController, 'Confirm Password', Icons.lock),
                                  _buildTextField(_phoneController, 'Phone Number', Icons.phone),
                                  _buildTextField(_addressController, 'Address', Icons.home),
                                  _buildTextField(_cityController, 'City', Icons.location_city),
                                  _buildTextField(_postalCodeController, 'Postal Code', Icons.code),
                                ]
                              : [
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField(_usernameController, 'Username', Icons.person)),
                                      SizedBox(width: 16),
                                      Expanded(child: _buildTextField(_emailController, 'Email', Icons.email)),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(child: _buildPasswordField(_passwordController, 'Password', Icons.lock)),
                                      SizedBox(width: 16),
                                      Expanded(child: _buildPasswordField(_confirmPasswordController, 'Confirm Password', Icons.lock)),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField(_phoneController, 'Phone Number', Icons.phone)),
                                      SizedBox(width: 16),
                                      Expanded(child: _buildTextField(_addressController, 'Address', Icons.home)),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField(_cityController, 'City', Icons.location_city)),
                                      SizedBox(width: 16),
                                      Expanded(child: _buildTextField(_postalCodeController, 'Postal Code', Icons.code)),
                                    ],
                                  ),
                                ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: isSmallScreen ? double.infinity : 250,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Register',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_message.isNotEmpty)
                      Text(
                        _message,
                        style: TextStyle(
                          color: _message.startsWith('User') ? Colors.green : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
