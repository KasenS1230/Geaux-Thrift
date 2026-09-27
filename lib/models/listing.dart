/// One item somebody is selling.
///
/// API prices are integer cents; the display model exposes dollars.
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

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: json['id'] as String,
    title: json['title'] as String,
    price: (json['priceCents'] as int) / 100,
    sellerName: json['sellerName'] as String,
    category: json['category'] as String,
    size: json['size'] as String?,
    condition: json['condition'] as String? ?? 'Good',
    description: json['description'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
  );

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
