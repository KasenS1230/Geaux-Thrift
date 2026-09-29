import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../theme/app_theme.dart';
import '../widgets/listing_photo.dart';

/// Shows the items saved in the cart, with a way to remove them and a
/// running total.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          final items = cart.items;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Your cart is empty.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final listing = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: ListingPhoto(imageUrl: listing.imageUrl),
                      ),
                      title: Text(listing.title, maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(listing.formattedPrice),
                      trailing: IconButton(
                        tooltip: 'Remove from cart',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => cart.removeItem(listing.id),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${cart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: LsuColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
