import 'package:flutter/material.dart';
import 'package:frontend/screen/searchresult.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isDarkMode = false;
  List<String> _suggestions = []; // Store live suggestions
  bool _loadingSuggestions = false;

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductSearchResultsScreen(query: query),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a product name")),
      );
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _loadingSuggestions = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://stswm.com/store/api/search/?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<String> names = [];
        for (var item in data['products']) {
          names.add(item['name']);
        }
        setState(() {
          _suggestions = names;
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
      });
    } finally {
      setState(() {
        _loadingSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            if (value.isNotEmpty) {
              _fetchSuggestions(value);
            } else {
              setState(() {
                _suggestions = [];
              });
            }
          },
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loadingSuggestions) const LinearProgressIndicator(),
          Expanded(
            child: _suggestions.isEmpty
                ? Center(
                    child: Text(
                      'Type a product name and press Enter',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        title: Text(suggestion),
                        onTap: () => _performSearch(suggestion),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
