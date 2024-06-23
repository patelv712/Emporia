import "package:flutter/material.dart";

class SearchBarWidget extends StatefulWidget{
  const SearchBarWidget({super.key});


  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {

  final TextEditingController _searchController = TextEditingController();
  final List<String> _allItems = [
    'computer',
    'pencil',
    'shirt',
    'desk',
    'headphone',
    'backpack',
    'book'
        'bag'
  ];

  List<String> _searchResults = [];

  // Search functionality
  void _runFilter(String enteredKeyword) {
    List<String> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allItems;
    } else {
      results = _allItems
          .where((item) =>
              item.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _searchResults = results;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchResults = _allItems;
    _searchController.addListener(() {
      _runFilter(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search',
              suffixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_searchResults[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}