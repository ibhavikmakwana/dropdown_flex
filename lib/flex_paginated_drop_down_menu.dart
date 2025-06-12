// lib/custom_paginated_dropdown.dart

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class CustomPaginatedDropdown extends StatefulWidget {
  final List<String> items;
  final VoidCallback onLoadMore;
  final ValueChanged<String>? onItemSelected;
  final bool isLoading;
  final double itemHeight;
  final double maxHeight;
  final InputDecoration? inputDecoration;
  final TextStyle? highlightTextStyle;
  final Color? highlightColor;
  final Duration scrollAnimationDuration;
  final Curve scrollAnimationCurve;
  final double keyRepeatDelayMs;
  final TextStyle? textStyle;
  final String? preselectedItem;

  const CustomPaginatedDropdown({
    super.key,
    required this.items,
    required this.onLoadMore,
    this.onItemSelected,
    this.isLoading = false,
    this.itemHeight = 48.0,
    this.maxHeight = 300.0,
    this.inputDecoration,
    this.highlightTextStyle,
    this.highlightColor,
    this.scrollAnimationDuration = const Duration(milliseconds: 200),
    this.scrollAnimationCurve = Curves.easeInOut,
    this.keyRepeatDelayMs = 100,
    this.textStyle,
    this.preselectedItem,
  });

  @override
  State<CustomPaginatedDropdown> createState() => _CustomPaginatedDropdownState();
}

class _CustomPaginatedDropdownState extends State<CustomPaginatedDropdown> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  List<String> _filteredItems = [];
  int _highlightedIndex = -1;
  OverlayEntry? _overlayEntry;
  bool _userScrolling = false;
  Timer? _keyRepeatTimer;

  void _filterItems(String query) {
    final oldHighlightedValue =
        (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length)
            ? _filteredItems[_highlightedIndex]
            : null;

    final newFiltered =
        widget.items.where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();

    int newHighlightedIndex = -1;
    if (oldHighlightedValue != null) {
      newHighlightedIndex = newFiltered.indexOf(oldHighlightedValue);
    }

    setState(() {
      _filteredItems = newFiltered;
      _highlightedIndex = (_filteredItems.isNotEmpty && newHighlightedIndex >= 0)
          ? newHighlightedIndex.clamp(0, _filteredItems.length - 1)
          : -1;
    });
    _highlightOverlay();
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeOverlay();
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
      _scrollToHighlighted();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _highlightOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
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
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is UserScrollNotification) {
                    _userScrolling = notification.direction != ScrollDirection.idle;
                  }
                  if (notification is ScrollEndNotification &&
                      _scrollController.position.pixels ==
                          _scrollController.position.maxScrollExtent) {
                    widget.onLoadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _filteredItems.length + (widget.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _filteredItems.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final isHighlighted = index == _highlightedIndex;
                    return Container(
                      color: isHighlighted ? widget.highlightColor ?? Colors.blue.shade100 : null,
                      child: ListTile(
                        title: Text(
                          _filteredItems[index],
                          style: isHighlighted
                              ? widget.highlightTextStyle ??
                                  const TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                        onTap: () {
                          _controller.text = _filteredItems[index];
                          widget.onItemSelected?.call(_filteredItems[index]);
                          _removeOverlay();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_keyRepeatTimer == null) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _startKeyRepeat(() => _moveHighlight(down: true));
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _startKeyRepeat(() => _moveHighlight(down: false));
        }
      }
    } else if (event is KeyUpEvent) {
      _stopKeyRepeat();
    }
  }

  void _moveHighlight({required bool down}) {
    setState(() {
      if (down) {
        _highlightedIndex = (_highlightedIndex + 1).clamp(0, _filteredItems.length - 1);
      } else {
        _highlightedIndex = (_highlightedIndex - 1).clamp(0, _filteredItems.length - 1);
      }
    });
    _scrollToHighlighted();
    _highlightOverlay();
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
    if (_userScrolling) return;
    if (_highlightedIndex < 0 || _highlightedIndex >= _filteredItems.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemOffset = _highlightedIndex * widget.itemHeight;
      final scrollTo = itemOffset - (widget.maxHeight / 2) + (widget.itemHeight / 2);
      _scrollController.animateTo(
        scrollTo.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
        duration: widget.scrollAnimationDuration,
        curve: widget.scrollAnimationCurve,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;

    if (widget.preselectedItem != null && widget.items.contains(widget.preselectedItem)) {
      _controller.text = widget.preselectedItem!;
      _highlightedIndex = widget.items.indexOf(widget.preselectedItem!);
    }

    _controller.addListener(() => _filterItems(_controller.text));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _removeOverlay();
    });
  }

  @override
  void didUpdateWidget(covariant CustomPaginatedDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_controller.text.isEmpty) {
      double? offsetFromTop;
      if (_highlightedIndex >= 0 && _scrollController.hasClients) {
        offsetFromTop = _highlightedIndex * widget.itemHeight - _scrollController.offset;
      }
      setState(() {
        _filteredItems = widget.items;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && offsetFromTop != null) {
          final target = _highlightedIndex * widget.itemHeight - offsetFromTop;
          _scrollController.jumpTo(target.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ));
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filterItems(_controller.text);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _keyRepeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: TextField(
          controller: _controller,
          style: widget.textStyle,
          decoration: widget.inputDecoration ??
              const InputDecoration(
                suffixIcon: Icon(Icons.arrow_drop_down),
                hintText: 'Search & select...',
              ),
          onTap: _showOverlay,
        ),
      ),
    );
  }
}
