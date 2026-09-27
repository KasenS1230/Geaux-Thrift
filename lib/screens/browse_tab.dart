import 'dart:async';

import 'package:flutter/material.dart';

import '../data/listing_repository.dart';
import '../models/listing.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class BrowseTab extends StatefulWidget {
  const BrowseTab({
    super.key,
    required this.query,
    required this.repository,
    this.revision = 0,
  });
  final String query;
  final ListingRepository repository;
  final int revision;
  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _form = GlobalKey<FormState>();
  String _category = 'All';
  int? _minCents, _maxCents;
  List<Listing> _items = [];
  bool _loading = true, _more = false;
  String? _error;
  int _generation = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BrowseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.revision != widget.revision) {
      _debounce?.cancel();
      // Invalidate requests immediately, before the new search starts.
      _generation++;
      _loading = true;
      _error = null;
      _debounce = Timer(const Duration(milliseconds: 300), () => _load());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    _debounce?.cancel();
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (!append) _items = [];
    });
    try {
      final page = await widget.repository.fetch(
        query: widget.query,
        category: _category,
        minPriceCents: _minCents,
        maxPriceCents: _maxCents,
        offset: append ? _items.length : 0,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = [..._items, ...page];
        _more = page.length == 50;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = error is ListingApiException
            ? error.message
            : 'Could not load listings. Please try again.';
      });
    }
  }

  String? _validatePrice(String? value) =>
      value == null || value.trim().isEmpty || parsePriceCents(value) != null
      ? null
      : 'Enter a valid price';

  void _applyPrices() {
    if (!_form.currentState!.validate()) return;
    final min = parsePriceCents(_min.text), max = parsePriceCents(_max.text);
    if (min != null && max != null && min > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum price must not exceed maximum price'),
        ),
      );
      return;
    }
    _minCents = min;
    _maxCents = max;
    _load();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final category in listingCategories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) {
                    _category = category;
                    _load();
                  },
                ),
              ),
          ],
        ),
      ),
      Form(
        key: _form,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _min,
                  validator: _validatePrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Min price',
                    prefixText: '\$ ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _max,
                  validator: _validatePrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Max price',
                    prefixText: '\$ ',
                  ),
                ),
              ),
              TextButton(onPressed: _applyPrices, child: const Text('Apply')),
            ],
          ),
        ),
      ),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: () => _load(append: _items.isNotEmpty),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (!_loading && _error == null)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No listings found. Try another search or post an item.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                )
              : GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) => ListingCard(
                    listing: _items[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ListingDetailScreen(listing: _items[index]),
                      ),
                    ),
                  ),
                ),
        ),
      ),
      if (_more && !_loading && _error == null)
        TextButton(
          onPressed: () => _load(append: true),
          child: const Text('Load more'),
        ),
    ],
  );
}
