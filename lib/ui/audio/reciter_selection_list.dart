import 'package:flutter/material.dart';

import '../../data/services/ayah_reciter_catalog_service.dart';
import '../../l10n/app_strings.dart';

class ReciterSelectionList extends StatefulWidget {
  const ReciterSelectionList({
    super.key,
    required this.strings,
    required this.options,
    required this.selectedEdition,
    required this.onSelected,
    this.enabled = true,
    this.searchFieldKey,
    this.listKey,
  });

  final AppStrings strings;
  final List<AyahReciterOption> options;
  final String selectedEdition;
  final ValueChanged<AyahReciterOption> onSelected;
  final bool enabled;
  final Key? searchFieldKey;
  final Key? listKey;

  @override
  State<ReciterSelectionList> createState() => _ReciterSelectionListState();
}

class _ReciterSelectionListState extends State<ReciterSelectionList> {
  String _searchQuery = '';

  List<AyahReciterOption> get _filteredOptions {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.options;
    }
    return widget.options.where((option) {
      final english = option.englishName.toLowerCase();
      final native = option.nativeName.toLowerCase();
      final edition = option.edition.toLowerCase();
      return english.contains(query) ||
          native.contains(query) ||
          edition.contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = _filteredOptions;
    return Column(
      children: [
        TextField(
          key: widget.searchFieldKey,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.strings.searchReciter,
            isDense: true,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            key: widget.listKey,
            itemCount: filteredOptions.length,
            itemBuilder: (context, index) {
              final option = filteredOptions[index];
              final selected = option.edition == widget.selectedEdition;
              return ListTile(
                key: ValueKey('reciter_option_${option.edition}'),
                selected: selected,
                title: Text(option.englishName),
                subtitle: option.nativeName == option.englishName
                    ? null
                    : Text(option.nativeName),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: widget.enabled ? () => widget.onSelected(option) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<AyahReciterOption?> showReciterPickerBottomSheet({
  required BuildContext context,
  required AppStrings strings,
  required List<AyahReciterOption> options,
  required String selectedEdition,
}) {
  return showModalBottomSheet<AyahReciterOption>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SizedBox(
          height: 520,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.selectReciter,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ReciterSelectionList(
                    strings: strings,
                    options: options,
                    selectedEdition: selectedEdition,
                    onSelected: (option) {
                      Navigator.of(sheetContext).pop(option);
                    },
                    searchFieldKey: const ValueKey('reciters_search_field'),
                    listKey: const ValueKey('reciters_list'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
