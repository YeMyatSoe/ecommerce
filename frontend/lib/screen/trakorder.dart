import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For map functionality
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For reading the token
import 'package:http/http.dart' as http;
import 'dart:convert';

class TrackOrderScreen extends StatefulWidget {
  final String orderNumber;
  final String orderStatus;
  final LatLng? deliveryLocation;

  const TrackOrderScreen({
    super.key, 
    required this.orderNumber,
    required this.orderStatus,
    this.deliveryLocation,
  });

  @override
  _TrackOrderScreenState createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  GoogleMapController? mapController;

  final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // Default to San Francisco
    zoom: 12,
  );

  bool isLoading = true;
  List<Map<String, String>> orderItems = [];

  final _storage = FlutterSecureStorage();  // Secure storage instance for token

  Future<void> fetchOrderDetails() async {
    try {
      final token = await _storage.read(key: 'auth_token');  // Ensure this is available
      if (token == null) {
        print('No token found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please log in to view order details")),
        );
        return;
      }

      if (widget.orderNumber.isEmpty) {
        print('Order number is invalid');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid order number")),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/store/checkorder/${widget.orderNumber}/'),  // Correct URL with order number
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check if the response status code is successful (200)
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data');  // Log the API response to see its structure

        // Ensure the response contains the expected 'order_items' field
        if (data != null && data['order_items'] != null) {
          List items = data['order_items'];
          setState(() {
            // Process each item only if it's valid
            orderItems = items.map((item) {
              return {
                'productName': item['product_name']?.toString() ?? 'Unknown',
                'colorName': item['color_name']?.toString() ?? 'Unknown',
                'quantity': item['quantity']?.toString() ?? '0',
              };
            }).toList();

            isLoading = false;
          });
        } else {
          print('No items found in order');
          setState(() {
            isLoading = false;
            orderItems = [];  // Empty list if no items found
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No items found in the order")),
          );
        }
      } else {
        print('Failed to load order details: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load order details")),
        );
      }
    } catch (e) {
      print('Error fetching order details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching order details")),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveCameraToOrder();
  }

  void _moveCameraToOrder() {
    if (mapController != null && widget.deliveryLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(widget.deliveryLocation!),
      );
    }
  }

double _getProgressValue() {
  switch (widget.orderStatus) {
    case 'DELIVERED':
      return 1.0; // Fully delivered, progress complete
    case 'SHIPPED':
      return 0.75; // Shipped but not yet delivered, about 75% of the way
    case 'PENDING':
      return 0.0; // Pending, no progress
    case 'CANCELED':
      return 0.0; // Canceled, no progress
    case 'RETURNED':
      return 0.0; // Returned, no progress
    default:
      return 0.0; // Default to no progress if the status is unknown
  }
}

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();  // Fetch order details when the screen is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order #${widget.orderNumber}'),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())  // Show loading indicator while data is loading
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Order Number: ${widget.orderNumber}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Status: ${widget.orderStatus}'),
                    SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _getProgressValue(),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(Colors.orange),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.orderStatus == 'Delivered'
                          ? 'Your package has been delivered!'
                          : widget.orderStatus == 'In Progress'
                              ? 'Your order is on the way!'
                              : 'Your order is pending.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Divider(color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Items in this order:', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 150,  // Fixed height for ListView
                      child: ListView.builder(
                        itemCount: orderItems.length,
                        itemBuilder: (context, index) {
                          var item = orderItems[index];
                          return _buildOrderItem(item['productName']!, item['quantity']!, item['colorName']!);
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 300,  // Fixed height for mobile map
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: _initialCameraPosition,
                        markers: {
                          if (widget.deliveryLocation != null)
                            Marker(
                              markerId: MarkerId('order_location'),
                              position: widget.deliveryLocation!,
                              infoWindow: InfoWindow(title: 'Order Location'),
                            ),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderItem(String itemName, String quantity, String color) {
    return ListTile(
      title: Text(itemName),
      subtitle: Text('Quantity: $quantity\nColor: $color'),
    );
  }
}
