import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/listing.dart';
import '../theme/app_theme.dart';
import '../widgets/listing_photo.dart';

/// Full page for one item. This is where the "more information about the item"
/// lives — right now it shows what the model carries.
///
/// TODO(team): photo carousel (listings carry one photo today), seller profile
/// link, save/favorite button, "similar items" row, and report-listing option.
class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing, required this.cart});

  final Listing listing;
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(listing.title)),
      body: ListView(
        children: [
          SizedBox(
            height: 260,
            child: ListingPhoto(imageUrl: listing.imageUrl, iconSize: 72),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  listing.formattedPrice,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: LsuColors.purple,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: listing.category),
                    if (listing.size != null)
                      _InfoChip(label: 'Size ${listing.size}'),
                    _InfoChip(label: listing.condition),
                  ],
                ),
                const Divider(height: 32),
                Text('Description',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  listing.description.isEmpty
                      ? 'No description yet.'
                      : listing.description,
                ),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: LsuColors.purple,
                    child: Text(
                      listing.sellerName.characters.first,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(listing.sellerName),
                  subtitle: const Text('LSU student · joined 2025'),
                  // TODO(team): open the seller's profile page.
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: cart,
                  builder: (context, _) {
                    final inCart = cart.contains(listing.id);
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (inCart) {
                            cart.removeItem(listing.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from cart')),
                            );
                          } else {
                            cart.addItem(listing);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          }
                        },
                        icon: Icon(
                          inCart
                              ? Icons.remove_shopping_cart_outlined
                              : Icons.add_shopping_cart_outlined,
                        ),
                        label: Text(inCart ? 'Remove from Cart' : 'Add to Cart'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    // TODO(team): start (or open) a conversation with the
                    // seller and jump to the Messages tab.
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Messaging the seller is coming soon.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message seller'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: LsuColors.gold.withValues(alpha: 0.25),
      side: BorderSide.none,
    );
  }
}
