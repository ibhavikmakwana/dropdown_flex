import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dropdown_flex/dropdown_flex.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final options = List.generate(100, (index) => 'Option $index');

  List<String> _items = [];
  static const int _limit = 10;
  int _offset = 0; // not _currentPage
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMoreItems(); // Initial fetch
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('https://api.escuelajs.co/api/v1/products?offset=$_offset&limit=$_limit'),
    );
    print("Fetching items from API: offset=$_offset, limit=$_limit, status=${response.statusCode}");
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final newItems = data.map((item) => item['title'] as String).toList();

      setState(() {
        _items = [..._items, ...newItems];
        _offset += _limit;
        _hasMore = newItems.length == _limit;
      });
    } else {
      throw Exception('Failed to load items');
    }
    setState(() {
      _isLoading = false;
    });
  }

  final FocusNode focusNodeOne = FocusNode();
  final FocusNode focusNodeTwo = FocusNode();

  String? preselectedItemOne;
  String? preselectedItemTwo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Dropdown Flex Example", style: Theme.of(context).textTheme.headlineMedium),
          Row(
            children: [
              CustomDropdownMenu<String>(
                menuHeight: 300.0,
                width: 200,
                focusNode: FocusNode(),
                dropdownMenuEntries: [
                  for (var item in options)
                    FlexDropdownMenuEntry<String>(
                      value: item,
                      label: item,
                    ),
                ],
                searchCallback: (entries, query) {
                  if (query.isEmpty) {
                    return null;
                  }
                  final int index = entries
                      .indexWhere((FlexDropdownMenuEntry<String> entry) => entry.label == query);
                  return index != -1 ? index : null;
                },
                trailingIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                ),
                selectedTrailingIcon: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 24,
                ),
                hintText: "Select...",
                enableFilter: true,
                enableSearch: true,
                requestFocusOnTap: true,
                onSelected: (value) {},
              ),
              const SizedBox(width: 20),
              CustomDropdownMenu<String>(
                menuHeight: 300.0,
                width: 200,
                focusNode: FocusNode(),
                dropdownMenuEntries: [
                  for (var item in options)
                    FlexDropdownMenuEntry<String>(
                      value: item,
                      label: item,
                    ),
                ],
                searchCallback: (entries, query) {
                  if (query.isEmpty) {
                    return null;
                  }
                  final int index = entries
                      .indexWhere((FlexDropdownMenuEntry<String> entry) => entry.label == query);
                  return index != -1 ? index : null;
                },
                trailingIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                ),
                selectedTrailingIcon: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 24,
                ),
                hintText: "Select...",
                enableFilter: true,
                enableSearch: true,
                requestFocusOnTap: true,
                onSelected: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text("Paginated Dropdown Flex Example",
              style: Theme.of(context).textTheme.headlineMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaginatedDropdown(
                items: _items,
                width: 300,
                onLoadMore: _loadMoreItems,
                isLoading: _isLoading,
                preselectedItem: preselectedItemTwo,
                inputDecoration: InputDecoration(
                  hintText: "Search. . .",
                  label: Text("Select an item"),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                textStyle: TextStyle(color: Colors.black),
                highlightColor: Colors.orange.shade100,
                highlightTextStyle:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                onItemSelected: (val) {
                  preselectedItemOne = val;
                },
              ),
              const SizedBox(width: 20),
              CustomPaginatedDropdown(
                items: _items,
                width: 300,
                onLoadMore: _loadMoreItems,
                isLoading: _isLoading,
                preselectedItem: preselectedItemTwo,
                inputDecoration: InputDecoration(
                  hintText: "Search. . .",
                  label: Text("Select an item"),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                textStyle: TextStyle(color: Colors.black),
                highlightColor: Colors.orange.shade100,
                highlightTextStyle:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                onItemSelected: (val) {
                  preselectedItemTwo = val;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
