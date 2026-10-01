import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsupop/models/cart.dart';
import 'package:lsupop/models/listing.dart';
import 'package:lsupop/screens/cart_screen.dart';
import 'package:lsupop/screens/listing_detail_screen.dart';
import 'package:lsupop/theme/app_theme.dart';

Listing listing(String id, {double price = 8.25, String? size}) => Listing(
  id: id,
  title: id,
  price: price,
  sellerName: 'Demo Seller',
  category: 'Dorm',
  size: size,
);

Widget host(Widget child) => MaterialApp(theme: buildAppTheme(), home: child);

void main() {
  testWidgets('an empty cart explains itself instead of showing a total', (
    tester,
  ) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    await tester.pumpWidget(host(CartScreen(cart: cart)));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty.'), findsOneWidget);
    expect(find.text('Total'), findsNothing);
    expect(find.byType(ListTile), findsNothing);
  });
  testWidgets('every cart item is listed with the running total', (
    tester,
  ) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    cart.addItem(listing('Mug', price: 8.25));
    cart.addItem(listing('Hoodie', price: 32.5));
    await tester.pumpWidget(host(CartScreen(cart: cart)));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('Mug'), findsOneWidget);
    expect(find.text('Hoodie'), findsOneWidget);
    expect(find.text('\$8.25'), findsOneWidget);
    expect(find.text('\$32.50'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('\$40.75'), findsOneWidget);
  });
  testWidgets('removing an item updates the list and the total live', (
    tester,
  ) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    cart.addItem(listing('Mug', price: 8.25));
    cart.addItem(listing('Hoodie', price: 32.5));
    await tester.pumpWidget(host(CartScreen(cart: cart)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove from cart').first);
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Mug'), findsNothing);
    expect(find.text('\$32.50'), findsNWidgets(2)); // item price and total
    expect(cart.contains('Mug'), isFalse);
  });
  testWidgets('removing the last item falls back to the empty state', (
    tester,
  ) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    cart.addItem(listing('Mug'));
    await tester.pumpWidget(host(CartScreen(cart: cart)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove from cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty.'), findsOneWidget);
    expect(cart.itemCount, 0);
  });
  testWidgets('an item added while the cart screen is open appears on it', (
    tester,
  ) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    await tester.pumpWidget(host(CartScreen(cart: cart)));
    await tester.pumpAndSettle();
    cart.addItem(listing('Mug'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty.'), findsNothing);
    expect(find.text('Mug'), findsOneWidget);
  });
  testWidgets('the detail screen shows everything the listing carries', (
    tester,
  ) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    await tester.pumpWidget(
      host(
        ListingDetailScreen(
          listing: const Listing(
            id: 'l1',
            title: 'Vintage LSU Crewneck',
            price: 30,
            sellerName: 'Kasen S.',
            category: 'Apparel',
            size: 'M',
            condition: 'Like new',
            description: 'Barely worn',
          ),
          cart: cart,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vintage LSU Crewneck'), findsNWidgets(2)); // app bar + body
    expect(find.text('\$30.00'), findsOneWidget);
    expect(find.text('Apparel'), findsOneWidget);
    expect(find.text('Size M'), findsOneWidget);
    expect(find.text('Like new'), findsOneWidget);
    expect(find.text('Barely worn'), findsOneWidget);
    expect(find.text('Kasen S.'), findsOneWidget);
  });
  testWidgets('a listing with no size or description says so', (tester) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    await tester.pumpWidget(
      host(ListingDetailScreen(listing: listing('Mug'), cart: cart)),
    );
    await tester.pumpAndSettle();
    expect(find.text('No description yet.'), findsOneWidget);
    expect(find.textContaining('Size'), findsNothing);
  });
  testWidgets('the detail button toggles the listing in and out of the cart', (
    tester,
  ) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    await tester.pumpWidget(
      host(ListingDetailScreen(listing: listing('Mug'), cart: cart)),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    expect(cart.contains('Mug'), isTrue);
    expect(find.text('Added to cart'), findsOneWidget);
    expect(find.text('Remove from Cart'), findsOneWidget);
    // Let the first snack bar finish appearing and then time out, so the
    // second one is unambiguous.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from Cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(cart.contains('Mug'), isFalse);
    expect(find.text('Removed from cart'), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);
  });
  testWidgets('a listing already in the cart opens showing Remove', (
    tester,
  ) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    cart.addItem(listing('Mug'));
    await tester.pumpWidget(
      host(ListingDetailScreen(listing: listing('Mug'), cart: cart)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Remove from Cart'), findsOneWidget);
    expect(find.text('Add to Cart'), findsNothing);
  });
  testWidgets('messaging the seller is still only a promise', (tester) async {
    final cart = Cart();
    addTearDown(cart.dispose);
    await tester.pumpWidget(
      host(ListingDetailScreen(listing: listing('Mug'), cart: cart)),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message seller'));
    await tester.pump();
    expect(
      find.text('Messaging the seller is coming soon.'),
      findsOneWidget,
    );
  });
}
