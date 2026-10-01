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

  test('a new cart is empty and totals zero', () {
    final cart = Cart();
    expect(cart.itemCount, 0);
    expect(cart.items, isEmpty);
    expect(cart.totalPrice, 0);
    expect(cart.contains('Mug'), isFalse);
  });

  test('items keeps insertion order and cannot be modified from outside', () {
    final cart = Cart();
    cart.addItem(listing('Mug'));
    cart.addItem(listing('Hoodie'));
    expect(cart.items.map((item) => item.id), ['Mug', 'Hoodie']);
    expect(() => cart.items.add(listing('Tickets')), throwsUnsupportedError);
    expect(cart.itemCount, 2);
  });

  test('adding a duplicate does not notify listeners', () {
    final cart = Cart();
    cart.addItem(listing('Mug'));
    var notifications = 0;
    cart.addListener(() => notifications++);
    cart.addItem(listing('Mug'));
    expect(notifications, 0);
  });

  test('removing a listing that is not in the cart leaves the rest alone', () {
    final cart = Cart();
    cart.addItem(listing('Mug'));
    cart.removeItem('Hoodie');
    expect(cart.items.single.id, 'Mug');
  });

  test('removing one of several items keeps the others and their total', () {
    final cart = Cart();
    cart.addItem(listing('Mug', price: 8.25));
    cart.addItem(listing('Hoodie', price: 32.5));
    cart.addItem(listing('Tickets', price: 60));
    cart.removeItem('Hoodie');
    expect(cart.items.map((item) => item.id), ['Mug', 'Tickets']);
    expect(cart.totalPrice, 68.25);
  });

  test('emptying the cart returns it to its initial state', () {
    final cart = Cart();
    cart.addItem(listing('Mug'));
    cart.addItem(listing('Hoodie'));
    cart.removeItem('Mug');
    cart.removeItem('Hoodie');
    expect(cart.itemCount, 0);
    expect(cart.totalPrice, 0);
  });

  test('a free listing can be added and counts toward the item count', () {
    final cart = Cart();
    cart.addItem(listing('Flyer', price: 0));
    expect(cart.itemCount, 1);
    expect(cart.totalPrice, 0);
  });
}
