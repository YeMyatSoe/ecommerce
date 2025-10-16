import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  final Function(int)? onItemTapped; // optional callback for navigation

  const CustomFooter({super.key, this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: const Color(0xFF1B1B1B),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Wrap(
                spacing: 40,
                runSpacing: 30,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _footerColumn(context, "About", [
                    _footerLink(context, "About Us", 6),
                    _footerLink(context, "Terms & Conditions", -1),
                    _footerLink(context, "Privacy Policy", -1),
                  ]),
                  _footerColumn(context, "Support", [
                    _footerLink(context, "Contact", 4),
                    _footerLink(context, "FAQ", -1),
                  ]),
                  _footerColumn(context, "Follow Us", [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.facebook, color: Colors.white),
                        // SizedBox(width: 10),
                        // Icon(Icons.instagram, color: Colors.white),
                        // SizedBox(width: 10),
                        // Icon(Icons.twitter, color: Colors.white),
                      ],
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 30),
              const Divider(color: Colors.white24, thickness: 0.5),
              const SizedBox(height: 15),
              const Text(
                "© 2025 Sweet Shop — All Rights Reserved",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerColumn(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _footerLink(BuildContext context, String text, int pageIndex) {
    return InkWell(
      onTap: () {
        if (pageIndex >= 0 && onItemTapped != null) {
          onItemTapped!(pageIndex); // navigate within scaffold
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$text page not implemented yet")),
          );
        }
      },
      hoverColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ),
    );
  }
}
