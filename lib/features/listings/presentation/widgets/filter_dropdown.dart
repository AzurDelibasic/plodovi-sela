import 'package:flutter/material.dart';

/// A styled, typeable dropdown filter (category, city, ...). Built on
/// Flutter's [DropdownMenu], which already supports typing to filter the
/// options — this just wires it up with an "All" entry and matches the
/// app's rounded, filled field style.
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.allLabel,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T value;
  final String allLabel;
  final List<({T value, String label})> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownMenu<T>(
      initialSelection: value,
      label: Text(label),
      leadingIcon: Icon(icon, size: 20),
      enableFilter: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 320,
      textStyle: const TextStyle(fontSize: 14),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      onSelected: (selected) => onChanged(selected as T),
      dropdownMenuEntries: [
        DropdownMenuEntry(value: null as T, label: allLabel),
        for (final item in items)
          DropdownMenuEntry(value: item.value, label: item.label),
      ],
    );
  }
}
