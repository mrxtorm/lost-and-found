import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String>? onChanged;

  /// Current query held by the provider, so the box stays in sync when
  /// filters are cleared from elsewhere.
  final String? query;

  const SearchBarWidget({super.key, this.onChanged, this.query});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller =
  TextEditingController(text: widget.query ?? '');

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.query;
    if (query != null && query != _controller.text) {
      _controller.text = query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 15.5, color: AppColors.ink),
      onChanged: (value) {
        setState(() {});
        widget.onChanged?.call(value);
      },
      decoration: InputDecoration(
        hintText: 'Search lost or found items',
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.muted),
          onPressed: () {
            _controller.clear();
            setState(() {});
            widget.onChanged?.call('');
          },
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: _border(AppColors.line),
        enabledBorder: _border(AppColors.line),
        focusedBorder: _border(AppColors.primary, 1.5),
      ),
    );
  }
}