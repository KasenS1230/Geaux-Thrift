import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lsupop/main.dart';
import 'package:lsupop/data/listing_repository.dart';

Map<String, dynamic> listing(String title) => {
  'id': title,
  'title': title,
  'priceCents': 825,
  'sellerName': 'Demo Seller',
  'category': 'Dorm',
  'condition': 'Good',
  'description': '',
};
http.Response page(List<Map<String, dynamic>> items) =>
    http.Response(jsonEncode({'listings': items}), 200);
ListingRepository repository(
  Future<http.Response> Function(http.Request) handler,
) => ListingRepository(
  client: MockClient(handler),
  baseUrl: 'http://localhost:3000',
);

void main() {
  test('money is parsed exactly and invalid prices are rejected', () {
    expect(parsePriceCents('8.25'), 825);
    expect(parsePriceCents('0.01'), 1);
    expect(parsePriceCents(' 8.2 '), 820);
    expect(parsePriceCents('1000000'), 100000000);
    for (final text in [
      '-1',
      'NaN',
      'Infinity',
      '1e3',
      '2.345',
      '',
      '1000000.01',
    ]) {
      expect(parsePriceCents(text), isNull, reason: text);
    }
  });
  test('repository sends encoded filters and converts API cents', () async {
    final repo = repository((request) async {
      expect(request.url.queryParameters, {
        'q': 'mug & cup',
        'category': 'Dorm',
        'minPriceCents': '100',
        'maxPriceCents': '1000',
        'limit': '50',
        'offset': '50',
      });
      return page([listing('Mug')]);
    });
    final items = await repo.fetch(
      query: 'mug & cup',
      category: 'Dorm',
      minPriceCents: 100,
      maxPriceCents: 1000,
      offset: 50,
    );
    expect(items.single.price, 8.25);
    repo.close();
  });
  test(
    'create sends integer cents and no client-controlled identity',
    () async {
      final repo = repository((request) async {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'title': 'Mug',
          'priceCents': 825,
          'category': 'Dorm',
          'description': '',
        });
        return http.Response(jsonEncode(listing('Mug')), 201);
      });
      expect(
        (await repo.create(
          title: ' Mug ',
          priceCents: 825,
          category: 'Dorm',
        )).id,
        'Mug',
      );
      repo.close();
    },
  );
  testWidgets('home shows server listings, tabs and sell button', (
    tester,
  ) async {
    final repo = repository((_) async => page([listing('Server Mug')]));
    addTearDown(repo.close);
    await tester.pumpWidget(LsuPopApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Server Mug'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
  testWidgets('failed browse can retry successfully', (tester) async {
    var failed = true;
    final repo = repository(
      (_) async => failed ? http.Response('{}', 500) : page([]),
    );
    addTearDown(repo.close);
    await tester.pumpWidget(LsuPopApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    failed = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No listings found'), findsOneWidget);
  });
  testWidgets('search and price controls send server filters', (tester) async {
    Uri? last;
    final repo = repository((request) async {
      last = request.url;
      return page([]);
    });
    addTearDown(repo.close);
    await tester.pumpWidget(LsuPopApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search LSU merch',
      ),
      'mug',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(last!.queryParameters['q'], 'mug');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Min price'),
      '5.25',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Max price'),
      '10',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(last!.queryParameters['minPriceCents'], '525');
    expect(last!.queryParameters['maxPriceCents'], '1000');
  });
  testWidgets('late search responses cannot overwrite newer results', (
    tester,
  ) async {
    final old = Completer<http.Response>();
    final repo = repository((request) async {
      if (request.url.queryParameters['q'] == 'old') return old.future;
      return page([listing(request.url.queryParameters['q'] ?? 'Initial')]);
    });
    addTearDown(repo.close);
    await tester.pumpWidget(LsuPopApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search LSU merch',
      ),
      'old',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search LSU merch',
      ),
      'new',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    old.complete(page([listing('Old response')]));
    await tester.pumpAndSettle();
    expect(find.text('new'), findsWidgets);
    expect(find.text('Old response'), findsNothing);
  });
  testWidgets(
    'posting waits for success, prevents duplicate submits and refreshes browse',
    (tester) async {
      final pending = Completer<http.Response>();
      var posts = 0;
      var saved = false;
      final repo = repository((request) async {
        if (request.method == 'POST') {
          posts++;
          return pending.future;
        }
        return page(saved ? [listing('New Mug')] : []);
      });
      addTearDown(repo.close);
      await tester.pumpWidget(LsuPopApp(repository: repo));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'What are you selling?'),
        'New Mug',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '8.25',
      );
      await tester.scrollUntilVisible(
        find.text('Post listing'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Post listing'));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      saved = true;
      pending.complete(http.Response(jsonEncode(listing('New Mug')), 201));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(posts, 1);
      expect(find.text('New Mug'), findsOneWidget);
      expect(find.text('Listing saved'), findsOneWidget);
    },
  );
  testWidgets('failed post preserves input and allows retry', (tester) async {
    final repo = repository(
      (request) async =>
          request.method == 'POST' ? http.Response('{}', 500) : page([]),
    );
    addTearDown(repo.close);
    await tester.pumpWidget(LsuPopApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What are you selling?'),
      'Keep my draft',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '8');
    await tester.scrollUntilVisible(
      find.text('Post listing'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Post listing'));
    await tester.pumpAndSettle();
    expect(find.text('Keep my draft'), findsOneWidget);
    expect(find.textContaining('server could not complete'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
