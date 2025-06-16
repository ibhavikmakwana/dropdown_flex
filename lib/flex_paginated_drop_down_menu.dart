import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class CustomPaginatedDropdown extends StatefulWidget {
  final List<String> items;
  final VoidCallback onLoadMore;
  final ValueChanged<String>? onItemSelected;
  final bool isLoading;
  final double itemHeight;
  final double maxHeight;
  final double width;
  final double maxWidth;
  final InputDecoration? inputDecoration;
  final TextStyle? highlightTextStyle;
  final Color? highlightColor;
  final Duration scrollAnimationDuration;
  final Curve scrollAnimationCurve;
  final double keyRepeatDelayMs;
  final TextStyle? textStyle;
  final String? preselectedItem;
  final bool enabled;
  final bool caseSensitive;

  const CustomPaginatedDropdown({
    super.key,
    required this.items,
    required this.onLoadMore,
    this.onItemSelected,
    this.isLoading = false,
    this.itemHeight = 48.0,
    this.maxHeight = 300.0,
    this.width = 300.0,
    this.maxWidth = 500.0,
    this.inputDecoration,
    this.highlightTextStyle,
    this.highlightColor,
    this.scrollAnimationDuration = const Duration(milliseconds: 100),
    this.scrollAnimationCurve = Curves.easeInOut,
    this.keyRepeatDelayMs = 200,
    this.textStyle,
    this.preselectedItem,
    this.enabled = true,
    this.caseSensitive = false,
  });

  @override
  State<CustomPaginatedDropdown> createState() => _CustomPaginatedDropdownState();
}

class _CustomPaginatedDropdownState extends State<CustomPaginatedDropdown> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  late final FocusNode _textFieldFocusNode;
  final LayerLink _layerLink = LayerLink();

  List<String> _filteredItems = [];
  int _highlightedIndex = -1;
  OverlayEntry? _overlayEntry;
  Timer? _keyRepeatTimer;
  Timer? _scrollDebounceTimer;
  final Map<int, GlobalKey> _itemKeys = {};
  bool _isOverlayVisible = false;
  String? _selectedItem; // Track the actually selected item

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.preselectedItem ?? '');
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _textFieldFocusNode = FocusNode();

    _initializeItems();
    _setupListeners();
  }

  void _initializeItems() {
    _filteredItems = List.from(widget.items);

    if (widget.preselectedItem != null && widget.items.contains(widget.preselectedItem)) {
      _selectedItem = widget.preselectedItem;
      _highlightedIndex = widget.items.indexOf(widget.preselectedItem!);
    }
  }

  void _setupListeners() {
    _controller.addListener(_onTextChanged);

    _textFieldFocusNode.addListener(() {
      if (_textFieldFocusNode.hasFocus && !_isOverlayVisible) {
        _showOverlay();
      }
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isOverlayVisible) {
        // Delay to allow tap events to register
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_focusNode.hasFocus && _isOverlayVisible) {
            _removeOverlay();
          }
        });
      }
    });
  }

  void _onTextChanged() {
    final query = _controller.text;

    // Clear selected item if user is typing something different
    if (_selectedItem != null && _selectedItem != query.trim()) {
      _selectedItem = null;
    }

    _filterItems(query);

    if (!_isOverlayVisible && _textFieldFocusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _filterItems(String query) {
    final normalizedQuery = widget.caseSensitive ? query : query.toLowerCase();
    _filteredItems = List.from(widget.items);
    setState(() {
      if (query.isEmpty) {
        // _filteredItems = List.from(widget.items);
        // If there's a selected item, highlight it
        if (_selectedItem != null) {
          _highlightedIndex = _filteredItems.indexOf(_selectedItem!);
        } else {
          _highlightedIndex = -1;
        }
      } else {
        // _filteredItems = widget.items.where((item) {
        //   final normalizedItem = widget.caseSensitive ? item : item.toLowerCase();
        //   return normalizedItem.contains(normalizedQuery);
        // }).toList();

        // Find exact match or set to first item
        final exactMatchIndex = _filteredItems.indexWhere((item) {
          final normalizedItem = widget.caseSensitive ? item : item.toLowerCase();
          return normalizedItem == normalizedQuery;
        });

        _highlightedIndex =
            exactMatchIndex != -1 ? exactMatchIndex : (_filteredItems.isNotEmpty ? 0 : -1);
      }
    });

    _cleanupItemKeys();
    _scheduleScrollToHighlighted();
    _refreshOverlay();
  }

  void _cleanupItemKeys() {
    final validIndices = Set<int>.from(List.generate(_filteredItems.length, (index) => index));
    _itemKeys.removeWhere((key, value) => !validIndices.contains(key));
  }

  void _showOverlay() {
    if (_isOverlayVisible) return;

    _isOverlayVisible = true;
    _focusNode.requestFocus();

    // Set highlight to currently selected item when reopening
    if (_selectedItem != null && _controller.text.trim() == _selectedItem) {
      final selectedIndex = widget.items.indexOf(_selectedItem!);
      if (selectedIndex != -1) {
        _highlightedIndex = selectedIndex;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);

      // Wait for the ListView to be built and rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _highlightedIndex >= 0) {
          _scrollToHighlightedImmediate();
        }
      });
    });
  }

  void _removeOverlay() {
    if (!_isOverlayVisible) return;

    _isOverlayVisible = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _itemKeys.clear();
  }

  void _refreshOverlay() {
    if (_isOverlayVisible && _overlayEntry != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
  }

  void _scheduleScrollToHighlighted() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) _scrollToHighlighted();
    });
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox.shrink());
    }

    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxHeight),
              child: _buildDropdownList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownList() {
    if (_filteredItems.isEmpty && !widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No items found'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _filteredItems.length + (widget.isLoading ? 1 : 0),
        itemExtent: widget.itemHeight, // Add explicit item height
        itemBuilder: _buildListItem,
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      const threshold = 100.0;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - threshold) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          widget.onLoadMore();
        });
      }
    }
    return false;
  }

  Widget _buildListItem(BuildContext context, int index) {
    if (index == _filteredItems.length) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final isHighlighted = index == _highlightedIndex;
    final key = _itemKeys.putIfAbsent(index, () => GlobalKey());
    final item = _filteredItems[index];

    return Container(
      key: key,
      height: widget.itemHeight,
      color: isHighlighted ? (widget.highlightColor ?? Theme.of(context).highlightColor) : null,
      child: ListTile(
        title: Text(
          item,
          style: isHighlighted
              ? (widget.highlightTextStyle ??
                  TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))
              : widget.textStyle,
        ),
        onTap: () => _selectItem(item),
      ),
    );
  }

  void _selectItem(String item) {
    _selectedItem = item; // Track the selected item
    _controller.text = item;
    widget.onItemSelected?.call(item);
    _removeOverlay();
  }

  void _onKeyEvent(KeyEvent event) {
    if (!_isOverlayVisible || _filteredItems.isEmpty) return;

    if (event is KeyDownEvent && _keyRepeatTimer == null) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowDown:
          _startKeyRepeat(() => _moveHighlight(down: true));
          break;
        case LogicalKeyboardKey.arrowUp:
          _startKeyRepeat(() => _moveHighlight(down: false));
          break;
        case LogicalKeyboardKey.enter:
          if (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length) {
            _selectItem(_filteredItems[_highlightedIndex]);
          }
          break;
        case LogicalKeyboardKey.escape:
          _removeOverlay();
          break;
      }
    } else if (event is KeyUpEvent) {
      _stopKeyRepeat();
    }
  }

  void _moveHighlight({required bool down}) {
    if (_filteredItems.isEmpty) return;

    setState(() {
      if (down) {
        _highlightedIndex = _highlightedIndex < _filteredItems.length - 1
            ? _highlightedIndex + 1
            : 0; // Wrap to top
      } else {
        _highlightedIndex = _highlightedIndex > 0
            ? _highlightedIndex - 1
            : _filteredItems.length - 1; // Wrap to bottom
      }
    });

    _scheduleScrollToHighlighted();
    _refreshOverlay();
  }

  void _startKeyRepeat(VoidCallback action) {
    action();
    _keyRepeatTimer = Timer.periodic(
      Duration(milliseconds: widget.keyRepeatDelayMs.toInt()),
      (_) => action(),
    );
  }

  void _stopKeyRepeat() {
    _keyRepeatTimer?.cancel();
    _keyRepeatTimer = null;
  }

  void _scrollToHighlighted() {
    if (_highlightedIndex < 0 || _highlightedIndex >= _filteredItems.length) return;

    final key = _itemKeys[_highlightedIndex];
    if (key?.currentContext == null) return;

    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: widget.scrollAnimationDuration,
      curve: widget.scrollAnimationCurve,
      alignment: 0.5,
    );
  }

  void _scrollToHighlightedImmediate() {
    if (_highlightedIndex < 0 || _highlightedIndex >= _filteredItems.length) return;

    // For immediate scrolling when overlay opens, use direct scroll position calculation
    final targetOffset = _highlightedIndex * widget.itemHeight;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final viewportHeight = widget.maxHeight;

    // Calculate optimal scroll position to center the highlighted item
    final centeredOffset = targetOffset - (viewportHeight / 2) + (widget.itemHeight / 2);
    final clampedOffset = centeredOffset.clamp(0.0, maxScrollExtent);

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(clampedOffset);

      // Also try ensureVisible as a fallback for better accuracy
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _itemKeys[_highlightedIndex];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 200),
            curve: widget.scrollAnimationCurve,
            alignment: 0.5,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant CustomPaginatedDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items != oldWidget.items) {
      final currentText = _controller.text;
      // Preserve highlighted item during load more
      final itemToPreserve = (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length)
          ? _filteredItems[_highlightedIndex]
          : null;

      // Update items and refilter
      _filteredItems = List.from(widget.items);
      _filterItemsPreservingHighlight(currentText, itemToPreserve);
    }
  }

  void _filterItemsPreservingHighlight(String query, String? preserveItem) {
    setState(() {
      // Simply assign all items without filtering
      _filteredItems = List.from(widget.items);

      // Try to restore previous highlight
      if (preserveItem != null) {
        _highlightedIndex = _filteredItems.indexOf(preserveItem);
      } else {
        _highlightedIndex = -1;
      }
    });

    _cleanupItemKeys();
    _scheduleScrollToHighlighted();
    _refreshOverlay();
  }

  @override
  void dispose() {
    _keyRepeatTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _removeOverlay();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.width,
            maxWidth: widget.maxWidth,
          ),
          child: TextField(
            focusNode: _textFieldFocusNode,
            controller: _controller,
            style: widget.textStyle,
            decoration: widget.inputDecoration ??
                const InputDecoration(
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
            enabled: widget.enabled,
            onTap: _showOverlay,
          ),
        ),
      ),
    );
  }
}
