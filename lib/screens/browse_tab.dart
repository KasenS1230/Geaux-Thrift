import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/listing.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

/// Tab 1: the grid of everything for sale.
class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key, required this.query});

  /// Text typed into the search bar up in the app bar.
  final String query;

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  String _category = kCategories.first;

  List<Listing> get _visibleListings {
    // TODO(team): move this filtering into a repository once the data is real,
    // and add sorting (newest / price) plus pagination.
    return mockListings
        .where((listing) => listing.matches(widget.query))
        .where((listing) => _category == 'All' || listing.category == _category)
        .toList();
  }

  void _openListing(Listing listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingDetailScreen(listing: listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listings = _visibleListings;

    return Column(
      children: [
        _CategoryBar(
          selected: _category,
          onSelected: (value) => setState(() => _category = value),
        ),
        Expanded(
          child: listings.isEmpty
              ? const _EmptyState(
                  icon: Icons.search_off,
                  message: 'Nothing matches that search yet.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return ListingCard(
                      listing: listing,
                      onTap: () => _openListing(listing),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Horizontal row of category filter chips.
class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: kCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = kCategories[index];
          return ChoiceChip(
            label: Text(category),
            selected: category == selected,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}

/// Shared "nothing here" placeholder.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
