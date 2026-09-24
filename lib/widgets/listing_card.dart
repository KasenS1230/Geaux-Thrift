import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../theme/app_theme.dart';

/// One item tile in the browse grid.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO(team): swap for the real photo once listings carry images.
            Expanded(
              child: Container(
                width: double.infinity,
                color: LsuColors.purple.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.photo_outlined,
                  size: 40,
                  color: LsuColors.purple,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.formattedPrice,
                    style: const TextStyle(
                      color: LsuColors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.size == null
                        ? listing.sellerName
                        : '${listing.sellerName} · Size ${listing.size}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
