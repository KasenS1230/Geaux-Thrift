import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The photo for a listing, falling back to the purple placeholder box
/// whenever a listing has no photo or the image cannot be loaded.
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({super.key, required this.imageUrl, this.iconSize = 40});

  final String? imageUrl;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: double.infinity,
      height: double.infinity,
      color: LsuColors.purple.withValues(alpha: 0.08),
      child: Icon(
        Icons.photo_outlined,
        size: iconSize,
        color: LsuColors.purple,
      ),
    );
    final url = imageUrl;
    if (url == null) return placeholder;
    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
