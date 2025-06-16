import 'package:flutter/material.dart';
import 'package:dropdown_flex/dropdown_flex.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                final int index = entries.indexWhere(
                    (FlexDropdownMenuEntry<String> entry) =>
                        entry.label == query);
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
            const SizedBox(height: 20),
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
                final int index = entries.indexWhere(
                    (FlexDropdownMenuEntry<String> entry) =>
                        entry.label == query);
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
      ),
    );
  }
}
