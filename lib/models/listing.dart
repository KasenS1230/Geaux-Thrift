/// One item somebody is selling.
///
/// TODO(team): this is a plain in-memory object. When we add a backend
/// (Firebase or our own API) give it `fromJson` / `toJson` and a real id.
class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.sellerName,
    required this.category,
    this.size,
    this.condition = 'Good',
    this.description = '',
    this.imageUrl,
  });

  final String id;
  final String title;
  final double price;
  final String sellerName;
  final String category;

  /// Clothing size, null for things that do not have one (mugs, tickets...).
  final String? size;
  final String condition;
  final String description;

  /// TODO(team): real photos. For now cards draw a placeholder box.
  final String? imageUrl;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Used by the search bar on the browse tab.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        sellerName.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q);
  }
}
