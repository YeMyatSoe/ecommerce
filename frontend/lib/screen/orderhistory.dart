import 'package:flutter/material.dart';
import 'package:frontend/screen/trakorder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  final _storage = FlutterSecureStorage();

  Future<void> fetchOrders() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        print('No token found');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/store/checkorder/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          orders = data.map((order) {
            return {
              'orderNumber': order['id'].toString(),
              'status': order['status'],
              'date': order['order_date'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders: ${response.body}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  void _TrackOrder(BuildContext context, String orderNumber, String orderStatus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackOrderScreen(
          orderNumber: orderNumber,
          orderStatus: orderStatus,
          deliveryLocation: LatLng(16.871311, 96.199379),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final cardWidth = isWeb ? screenWidth * 0.6 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    return Center(
                      child: Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: cardWidth,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: const Icon(
                              Icons.shopping_cart,
                              size: 36,
                              color: Colors.orange,
                            ),
                            title: Text(
                              'Order #${order['orderNumber']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text('Ordered on: ${order['date']}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  order['status']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: order['status'] == 'Delivered'
                                        ? Colors.green
                                        : order['status'] == 'In Progress'
                                            ? Colors.blue
                                            : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailScreen(
                                    orderNumber: order['orderNumber']!,
                                    orderDate: order['date']!,
                                    orderStatus: order['status']!,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderNumber;
  final String orderDate;
  final String orderStatus;

  const OrderDetailScreen({
    super.key,
    required this.orderNumber,
    required this.orderDate,
    required this.orderStatus,
  });

  void _TrackOrder(BuildContext context, String orderNumber, String orderStatus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackOrderScreen(
          orderNumber: orderNumber,
          orderStatus: orderStatus,
          deliveryLocation: LatLng(16.871311, 96.199379),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final contentWidth = isWeb ? screenWidth * 0.5 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderNumber'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Container(
          width: contentWidth,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Order Number: $orderNumber',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Order Date: $orderDate'),
              const SizedBox(height: 16),
              Text(
                'Order Status: $orderStatus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: orderStatus == 'Delivered'
                      ? Colors.green
                      : orderStatus == 'In Progress'
                          ? Colors.blue
                          : Colors.orange,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: isWeb ? 150 : double.infinity,
                child: ElevatedButton(
                  onPressed: () => _TrackOrder(context, orderNumber, orderStatus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Track Order',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
