import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsupop/models/listing.dart';
import 'package:lsupop/theme/app_theme.dart';
import 'package:lsupop/widgets/listing_card.dart';
import 'package:lsupop/widgets/listing_photo.dart';

Listing listing({String? size, String? imageUrl}) => Listing(
  id: 'l1',
  title: 'Vintage LSU Crewneck',
  price: 30,
  sellerName: 'Kasen S.',
  category: 'Apparel',
  size: size,
  imageUrl: imageUrl,
);

Widget host(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(body: Center(child: SizedBox(width: 180, height: 260, child: child))),
);

void main() {
  testWidgets('a card shows the title, price and seller', (tester) async {
    await tester.pumpWidget(
      host(ListingCard(listing: listing(), onTap: () {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vintage LSU Crewneck'), findsOneWidget);
    expect(find.text('\$30.00'), findsOneWidget);
    expect(find.text('Kasen S.'), findsOneWidget);
  });
  testWidgets('a sized listing shows the size next to the seller', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(ListingCard(listing: listing(size: 'M'), onTap: () {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kasen S. · Size M'), findsOneWidget);
    expect(find.text('Kasen S.'), findsNothing);
  });
  testWidgets('tapping a card reports the tap once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(ListingCard(listing: listing(), onTap: () => taps++)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListingCard));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
  testWidgets('a photoless listing falls back to the placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(host(const ListingPhoto(imageUrl: null)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
  testWidgets('a listing with a photo tries to load it', (tester) async {
    await tester.pumpWidget(
      host(const ListingPhoto(imageUrl: 'http://127.0.0.1:3000/images/a.jpg')),
    );
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url,
        'http://127.0.0.1:3000/images/a.jpg');
    expect(image.fit, BoxFit.cover);
  });
  testWidgets('a photo that cannot be fetched shows the placeholder', (
    tester,
  ) async {
    // The test HTTP client fails every request, which is the same thing the
    // app sees when the server is gone or the file was deleted.
    await tester.pumpWidget(
      host(const ListingPhoto(imageUrl: 'http://127.0.0.1:3000/images/a.jpg')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
  });
  testWidgets('the placeholder icon honours the requested size', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const ListingPhoto(imageUrl: null, iconSize: 72)),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Icon>(find.byIcon(Icons.photo_outlined)).size, 72);
  });
}
