import 'package:flutter_test/flutter_test.dart';
import 'package:lsupop/models/cart.dart';
import 'package:lsupop/models/listing.dart';

Listing listing(String id, {double price = 8.25}) => Listing(
  id: id,
  title: id,
  price: price,
  sellerName: 'Demo Seller',
  category: 'Dorm',
);

void main() {
  test('addItem adds a listing to the cart', () {
    final cart = Cart();
    cart.addItem(listing('Mug'));
    expect(cart.itemCount, 1);
    expect(cart.contains('Mug'), isTrue);
  });

  test('adding the same listing twice does not duplicate it', () {
    final cart = Cart();
    cart.addItem(listing('Mug'));
    cart.addItem(listing('Mug'));
    expect(cart.itemCount, 1);
  });

  test('removeItem removes a listing from the cart', () {
    final cart = Cart();
    cart.addItem(listing('Mug'));
    cart.removeItem('Mug');
    expect(cart.itemCount, 0);
    expect(cart.contains('Mug'), isFalse);
  });

  test('totalPrice sums the price of every item in the cart', () {
    final cart = Cart();
    cart.addItem(listing('Mug', price: 8.25));
    cart.addItem(listing('Hoodie', price: 32.5));
    expect(cart.totalPrice, 40.75);
  });

  test('addItem and removeItem notify listeners', () {
    final cart = Cart();
    var notifications = 0;
    cart.addListener(() => notifications++);
    cart.addItem(listing('Mug'));
    cart.removeItem('Mug');
    expect(notifications, 2);
  });
}
