import 'package:flutter/foundation.dart';

import 'listing.dart';

/// The listings a user has added to their cart.
///
/// In-memory only — the cart resets whenever the app restarts. Each listing
/// is a unique secondhand item, so [addItem] is a one-time toggle per
/// listing (no quantity).
class Cart extends ChangeNotifier {
  final List<Listing> _items = [];

  /// Unmodifiable snapshot of the items currently in the cart.
  List<Listing> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.price);

  bool contains(String listingId) =>
      _items.any((item) => item.id == listingId);

  void addItem(Listing listing) {
    if (contains(listing.id)) return;
    _items.add(listing);
    notifyListeners();
  }

  void removeItem(String listingId) {
    _items.removeWhere((item) => item.id == listingId);
    notifyListeners();
  }
}