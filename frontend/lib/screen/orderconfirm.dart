// import 'package:flutter/material.dart';

// class OrderConfirmationPage extends StatelessWidget {
//   final Map<String, dynamic> orderData;

//   OrderConfirmationPage({required this.orderData});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Order Confirmation'),
//         backgroundColor: Colors.green,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Order Successfully Placed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             SizedBox(height: 20),
//             Text('Order Details:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             ...orderData['cart_items'].map<Widget>((item) {
//               return Text('${item['product_name']} x ${item['quantity']} - \$${item['total_price']}');
//             }).toList(),
//             SizedBox(height: 20),
//             Text('Total: \$${orderData['total_price']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context); // Go back to cart or home
//               },
//               child: Text('Back to Shopping'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
