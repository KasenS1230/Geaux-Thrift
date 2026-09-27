import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/listing.dart';

const listingCategories = [
  'All',
  'Apparel',
  'Game Day',
  'Dorm',
  'Tickets',
  'Books',
];

int? parsePriceCents(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final cents =
      int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return cents <= 100000000 ? cents : null;
}

class ListingApiException implements Exception {
  const ListingApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ListingRepository {
  ListingRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _base = Uri.parse(
        baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: '',
            ).replaceFirst(
              RegExp(r'^$'),
              !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                  ? 'http://10.0.2.2:3000'
                  : 'http://127.0.0.1:3000',
            ),
      );
  final http.Client _client;
  final Uri _base;
  void close() => _client.close();

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = _base.replace(
        path: '${_base.path.replaceFirst(RegExp(r'/$'), '')}$path',
        queryParameters: query,
      );
      final response =
          await (method == 'POST'
                  ? _client.post(
                      uri,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(body),
                    )
                  : _client.get(uri))
              .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ListingApiException(
          'The server could not complete the request. Please try again.',
        );
      }
      return jsonDecode(response.body);
    } on TimeoutException {
      throw const ListingApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ListingApiException(
        'Cannot reach the server. Check your connection and try again.',
      );
    } on FormatException {
      throw const ListingApiException(
        'The server returned an invalid response.',
      );
    }
  }

  Future<List<Listing>> fetch({
    String query = '',
    String category = 'All',
    int? minPriceCents,
    int? maxPriceCents,
    int offset = 0,
  }) async {
    final data = await _request(
      'GET',
      '/listings',
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (category != 'All') 'category': category,
        if (minPriceCents != null) 'minPriceCents': '$minPriceCents',
        if (maxPriceCents != null) 'maxPriceCents': '$maxPriceCents',
        'limit': '50',
        'offset': '$offset',
      },
    );
    return (data['listings'] as List)
        .map((json) => Listing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> create({
    required String title,
    required int priceCents,
    required String category,
    String description = '',
  }) async {
    final data = await _request(
      'POST',
      '/listings',
      body: {
        'title': title.trim(),
        'priceCents': priceCents,
        'category': category,
        'description': description.trim(),
      },
    );
    return Listing.fromJson(data as Map<String, dynamic>);
  }
}
