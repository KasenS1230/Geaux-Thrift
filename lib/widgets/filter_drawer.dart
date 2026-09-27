import 'package:flutter/material.dart';

import '../data/listing_repository.dart';
import '../theme/app_theme.dart';

/// "$5", "$5.50", etc. Whole dollars drop the ".00".
String formatPriceCents(int cents) => '\$${_centsToText(cents)}';

String _centsToText(int cents) => cents % 100 == 0
    ? '${cents ~/ 100}'
    : (cents / 100).toStringAsFixed(2);

/// Short label for an active price filter, e.g. "$5 – $20", "$5+", "Under $20".
String priceRangeLabel(int? minCents, int? maxCents) {
  if (minCents != null && maxCents != null) {
    return '${formatPriceCents(minCents)} – ${formatPriceCents(maxCents)}';
  }
  if (minCents != null) return '${formatPriceCents(minCents)}+';
  return 'Under ${formatPriceCents(maxCents!)}';
}

/// One-tap price ranges shown under the min/max fields.
const _presets = <(String, int?, int?)>[
  ('Under \$10', null, 1000),
  ('\$10 – \$25', 1000, 2500),
  ('\$25 – \$50', 2500, 5000),
  ('\$50+', 5000, null),
];

/// Left sidebar for Browse filters. Price range sits at the top; add more
/// filter sections (condition, size...) below it in the ListView.
class FilterDrawer extends StatefulWidget {
  const FilterDrawer({
    super.key,
    this.minPriceCents,
    this.maxPriceCents,
    required this.onApply,
  });

  /// Currently applied bounds, used to pre-fill the fields.
  final int? minPriceCents;
  final int? maxPriceCents;

  /// Called with the new bounds (null = no bound) when the user applies or clears.
  final void Function(int? minCents, int? maxCents) onApply;

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late final _min = TextEditingController(
    text: widget.minPriceCents == null
        ? ''
        : _centsToText(widget.minPriceCents!),
  );
  late final _max = TextEditingController(
    text: widget.maxPriceCents == null
        ? ''
        : _centsToText(widget.maxPriceCents!),
  );
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  static int? _parse(String text) =>
      text.trim().isEmpty ? null : parsePriceCents(text);

  String? _validateMin(String? value) =>
      value == null || value.trim().isEmpty || parsePriceCents(value) != null
          ? null
          : 'Invalid price';

  String? _validateMax(String? value) {
    final invalid = _validateMin(value);
    if (invalid != null) return invalid;
    final min = _parse(_min.text), max = _parse(value ?? '');
    if (min != null && max != null && min > max) return 'Less than min';
    return null;
  }

  void _apply() {
    if (!_form.currentState!.validate()) return;
    widget.onApply(_parse(_min.text), _parse(_max.text));
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onApply(null, null);
    Navigator.of(context).pop();
  }

  void _pickPreset(int? min, int? max) {
    setState(() {
      _min.text = min == null ? '' : _centsToText(min);
      _max.text = max == null ? '' : _centsToText(max);
    });
    _form.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentMin = _parse(_min.text), currentMax = _parse(_max.text);

    return Drawer(
      width: 300,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Purple header that matches the app bar, with a gold accent.
            Container(
              color: LsuColors.purple,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 18,
                8,
                18,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters',
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                            color: LsuColors.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Text(
                    'Price range',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PriceField(
                          controller: _min,
                          label: 'Min price',
                          validator: _validateMin,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(8, 14, 8, 0),
                        child: Text('–', style: TextStyle(color: Colors.black45)),
                      ),
                      Expanded(
                        child: _PriceField(
                          controller: _max,
                          label: 'Max price',
                          validator: _validateMax,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Quick picks',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (label, min, max) in _presets)
                        _PresetChip(
                          label: label,
                          selected: currentMin == min && currentMax == max,
                          onTap: () => _pickPreset(min, max),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer actions, pinned to the bottom.
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _clear,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                        ),
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _apply,
                          style: FilledButton.styleFrom(
                            backgroundColor: LsuColors.purple,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Show results'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.controller,
    required this.label,
    required this.validator,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '\$ ',
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF7F6FA),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(LsuColors.purple, 1.5),
        floatingLabelStyle: const TextStyle(color: LsuColors.purple),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: LsuColors.gold,
      labelStyle: TextStyle(
        color: selected ? LsuColors.purple : Colors.black87,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? LsuColors.gold : Colors.black.withValues(alpha: 0.12),
      ),
      shape: const StadiumBorder(),
    );
  }
}