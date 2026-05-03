import 'package:flutter/material.dart';

import '../constants/spanish_cities.dart';

class SpanishCityField extends StatefulWidget {
  const SpanishCityField({
    required this.controller,
    required this.label,
    this.helperText,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  State<SpanishCityField> createState() => _SpanishCityFieldState();
}

class _SpanishCityFieldState extends State<SpanishCityField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.enabled
        ? suggestSpanishCities(widget.controller.text)
        : const <String>[];
    final canonicalCity = canonicalizeSpanishCity(widget.controller.text);
    final showSuggestions =
        _focusNode.hasFocus &&
        suggestions.isNotEmpty &&
        canonicalCity != widget.controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: (value) {
            setState(() {});
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.helperText,
            prefixIcon: const Icon(Icons.location_city_outlined),
          ),
        ),
        if (showSuggestions) ...[
          const SizedBox(height: 8),
          _CitySuggestionsCard(
            suggestions: suggestions,
            onSelected: (city) {
              widget.controller.text = city;
              widget.controller.selection = TextSelection.collapsed(
                offset: city.length,
              );
              setState(() {});
              widget.onChanged?.call(city);
              _focusNode.unfocus();
            },
          ),
        ],
      ],
    );
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _CitySuggestionsCard extends StatelessWidget {
  const _CitySuggestionsCard({
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: suggestions.map((city) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(city),
            onTap: () => onSelected(city),
          );
        }).toList(),
      ),
    );
  }
}
