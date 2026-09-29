import 'dart:async';

import 'package:flutter/material.dart';

import '../data/listing_repository.dart';
import '../models/listing.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class BrowseTab extends StatefulWidget {
  const BrowseTab({
    super.key,
    required this.query,
    required this.repository,
    this.revision = 0,
    this.minPriceCents,
    this.maxPriceCents,
    this.onClearPrice,
  });
  final String query;
  final ListingRepository repository;
  final int revision;

  /// Price bounds chosen in the filter sidebar (null = no bound).
  final int? minPriceCents;
  final int? maxPriceCents;

  /// Removes the price filter; shown as the chip's delete button.
  final VoidCallback? onClearPrice;
  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  String _category = anyCategory;

  /// Chips to show. Starts with the built-ins so the row is never empty, then
  /// becomes whatever the server reports.
  List<String> _categories = fallbackCategories;
  List<Listing> _items = [];
  bool _loading = true, _more = false;
  String? _error;
  int _generation = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCategories();
  }

  /// Refreshes the chip row.
  ///
  /// A failure here is silent: the built-in chips still work, and the listing
  /// request alongside it reports the same outage more usefully.
  Future<void> _loadCategories() async {
    try {
      final categories = await widget.repository.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        // A category can only be added, never removed, so the selection stays
        // valid; guard anyway rather than leave a chip selected that is gone.
        if (_category != anyCategory && !categories.contains(_category)) {
          _category = anyCategory;
          _load();
        }
      });
    } on ListingApiException {
      // Keep whatever chips are already showing.
    }
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
      if (oldWidget.revision != widget.revision) _loadCategories();
      _debounce = Timer(const Duration(milliseconds: 300), () => _load());
    } else if (oldWidget.minPriceCents != widget.minPriceCents ||
        oldWidget.maxPriceCents != widget.maxPriceCents) {
      // Price changes come from a button press, so load right away.
      _debounce?.cancel();
      _generation++;
      _loading = true;
      _error = null;
      _debounce = Timer(Duration.zero, () => _load());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
        minPriceCents: widget.minPriceCents,
        maxPriceCents: widget.maxPriceCents,
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

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            // The price filter lives in the sidebar, so show it here too.
            if (widget.minPriceCents != null || widget.maxPriceCents != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InputChip(
                  avatar: const Icon(Icons.sell_outlined, size: 16),
                  label: Text(
                    priceRangeLabel(widget.minPriceCents, widget.maxPriceCents),
                  ),
                  onDeleted: widget.onClearPrice,
                  deleteButtonTooltipMessage: 'Clear price filter',
                ),
              ),
            for (final category in [anyCategory, ..._categories])
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
          onRefresh: () async {
            await Future.wait([_load(), _loadCategories()]);
          },
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