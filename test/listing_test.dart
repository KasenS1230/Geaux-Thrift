import 'package:flutter_test/flutter_test.dart';
import 'package:lsupop/models/listing.dart';

Map<String, dynamic> json({
  int priceCents = 825,
  Object? size,
  Object? condition,
  Object? description,
  Object? imageUrl,
}) => {
  'id': 'l1',
  'title': 'Vintage LSU Crewneck',
  'priceCents': priceCents,
  'sellerName': 'Demo Seller',
  'category': 'Apparel',
  'size': size,
  'condition': condition,
  'description': description,
  'imageUrl': imageUrl,
};

void main() {
  test('fromJson turns integer cents into dollars', () {
    expect(Listing.fromJson(json(priceCents: 825)).price, 8.25);
    expect(Listing.fromJson(json(priceCents: 1)).price, 0.01);
    expect(Listing.fromJson(json(priceCents: 0)).price, 0);
    expect(Listing.fromJson(json(priceCents: 100000000)).price, 1000000);
  });
  test('fromJson fills in the defaults the API may omit', () {
    final listing = Listing.fromJson(json());
    expect(listing.size, isNull);
    expect(listing.condition, 'Good');
    expect(listing.description, '');
    expect(listing.imageUrl, isNull);
  });
  test('fromJson keeps the optional fields the API does send', () {
    final listing = Listing.fromJson(
      json(size: 'M', condition: 'Like new', description: 'Barely worn'),
    );
    expect(listing.size, 'M');
    expect(listing.condition, 'Like new');
    expect(listing.description, 'Barely worn');
  });
  test('a server-relative photo path is resolved against the base URL', () {
    expect(
      Listing.fromJson(
        json(imageUrl: '/images/abc.jpg'),
        baseUrl: Uri.parse('http://10.0.2.2:3000'),
      ).imageUrl,
      'http://10.0.2.2:3000/images/abc.jpg',
    );
  });
  test('without a base URL the photo path is left exactly as sent', () {
    expect(Listing.fromJson(json(imageUrl: '/images/abc.jpg')).imageUrl,
        '/images/abc.jpg');
  });
  test('a missing photo stays null instead of resolving to the base URL', () {
    expect(
      Listing.fromJson(json(), baseUrl: Uri.parse('http://127.0.0.1:3000'))
          .imageUrl,
      isNull,
    );
  });
  test('formattedPrice always shows two decimal places', () {
    expect(Listing.fromJson(json(priceCents: 825)).formattedPrice, '\$8.25');
    expect(Listing.fromJson(json(priceCents: 3000)).formattedPrice, '\$30.00');
    expect(Listing.fromJson(json(priceCents: 5)).formattedPrice, '\$0.05');
  });
  test('matches searches title, category, seller and description', () {
    final listing = Listing.fromJson(json(description: 'Barely worn'));
    for (final query in [
      'crewneck',
      'CREWNECK',
      'apparel',
      'demo seller',
      'barely',
      '  crewneck  ',
    ]) {
      expect(listing.matches(query), isTrue, reason: query);
    }
  });
  test('an empty query matches everything and an unrelated one matches none', () {
    final listing = Listing.fromJson(json());
    expect(listing.matches(''), isTrue);
    expect(listing.matches('   '), isTrue);
    expect(listing.matches('kayak'), isFalse);
  });
}
