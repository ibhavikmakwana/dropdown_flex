# 📦 dropdown_flex

A customizable and flexible dropdown menu widget for Flutter with enhanced search, filtering, autofocus scroll-to-highlight, and trailing/leading icon support. Built to fix native dropdown limitations like scroll issues and gesture inconsistencies.

---

## ✨ Features

- customizable dropdown menu
- Optional leading/trailing icons
- Scroll-to-highlight support
- Optional search and filter
- Supports custom width and height
- Fixes native Flutter dropdown limitations

---

## 🚀 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dropdown_flex: ^0.0.1
```

## Usage

```dart
import 'package:dropdown_flex/dropdown_flex.dart';

final List<String> options = ['Apple', 'Banana', 'Cherry'];

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
    if (query.isEmpty) return null;
    final int index = entries.indexWhere(
      (entry) => entry.label == query,
    );
    return index != -1 ? index : null;
  },
  trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
  selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
  hintText: "Select...",
  enableFilter: true,
  enableSearch: true,
  requestFocusOnTap: true,
  onSelected: (value) {
    print("Selected: $value");
  },
)

```
