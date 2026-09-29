import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/listing.dart';

/// The browse chip meaning "don't filter by category". The server has no such
/// category and rejects it, so it never leaves the app.
const anyCategory = 'All';

/// Longest category name the server will store.
const maxCategoryLength = 30;

/// Categories to show until the server's list arrives, and if it never does.
/// The server seeds exactly these, so a reachable server agrees with this list.
const fallbackCategories = ['Apparel', 'Game Day', 'Dorm', 'Tickets', 'Books'];

int? parsePriceCents(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final cents =
      int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return cents <= 100000000 ? cents : null;
}

/// Photo types the API accepts, keyed by the file extension a picker reports.
const _imageContentTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};
const maxImageBytes = 5 * 1024 * 1024;

/// The content type to upload a picked photo as, or null when the API would
/// reject it.
///
/// Pickers are inconsistent about what they report: some hand back a filename
/// with no useful extension, others a bare MIME type, so try both.
String? imageContentType({String? filename, String? mimeType}) {
  final dot = filename?.lastIndexOf('.') ?? -1;
  final byExtension = dot < 0
      ? null
      : _imageContentTypes[filename!.substring(dot + 1).toLowerCase()];
  if (byExtension != null) return byExtension;
  final declared = mimeType?.split(';').first.trim().toLowerCase();
  return _imageContentTypes.containsValue(declared) ? declared : null;
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
    Uint8List? bytes,
    String contentType = 'application/json',
    Duration timeout = const Duration(seconds: 10),
    String? failureMessage,
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
                      headers: {'Content-Type': contentType},
                      body: bytes ?? jsonEncode(body),
                    )
                  : _client.get(uri))
              .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ListingApiException(
          failureMessage ??
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

  /// The categories the server currently knows, without the [anyCategory] chip.
  Future<List<String>> fetchCategories() async {
    final data = await _request(
      'GET',
      '/categories',
      failureMessage: 'Could not load categories. Please try again.',
    );
    final categories = (data as Map<String, dynamic>)['categories'];
    if (categories is! List) {
      throw const ListingApiException('The server returned an invalid response.');
    }
    return categories.cast<String>();
  }

  /// Adds [name] to the shared category list and returns it as the server
  /// stored it.
  ///
  /// Categories are case-insensitive server-side, so asking for one that
  /// already exists succeeds and returns the existing spelling rather than
  /// creating a near-duplicate.
  Future<String> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxCategoryLength) {
      throw const ListingApiException(
        'Use a category name of 1–$maxCategoryLength characters.',
      );
    }
    if (trimmed.toLowerCase() == anyCategory.toLowerCase()) {
      throw const ListingApiException(
        '“$anyCategory” is reserved. Please choose another name.',
      );
    }
    final data = await _request(
      'POST',
      '/categories',
      body: {'name': trimmed},
      failureMessage: 'The server would not accept that category name.',
    );
    return (data as Map<String, dynamic>)['name'] as String;
  }

  Future<List<Listing>> fetch({
    String query = '',
    String category = anyCategory,
    int? minPriceCents,
    int? maxPriceCents,
    int offset = 0,
  }) async {
    final data = await _request(
      'GET',
      '/listings',
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (category != anyCategory) 'category': category,
        if (minPriceCents != null) 'minPriceCents': '$minPriceCents',
        if (maxPriceCents != null) 'maxPriceCents': '$maxPriceCents',
        'limit': '50',
        'offset': '$offset',
      },
    );
    return (data['listings'] as List)
        .map(
          (json) =>
              Listing.fromJson(json as Map<String, dynamic>, baseUrl: _base),
        )
        .toList();
  }

  /// Stores [bytes] as a photo and returns the server path to hand to [create].
  ///
  /// The path is relative (`/images/<id>.jpg`); only the server decides what a
  /// listing's photo is called.
  Future<String> uploadImage(
    Uint8List bytes, {
    required String contentType,
  }) async {
    if (!_imageContentTypes.containsValue(contentType)) {
      throw const ListingApiException('Choose a JPEG, PNG or WebP photo.');
    }
    if (bytes.length > maxImageBytes) {
      throw const ListingApiException('That photo is larger than 5 MB.');
    }
    final data = await _request(
      'POST',
      '/images',
      bytes: bytes,
      contentType: contentType,
      timeout: const Duration(seconds: 30),
      failureMessage:
          'The server would not accept that photo. Try another one.',
    );
    return (data as Map<String, dynamic>)['url'] as String;
  }

  Future<Listing> create({
    required String title,
    required int priceCents,
    required String category,
    String description = '',
    String? imageUrl,
  }) async {
    final data = await _request(
      'POST',
      '/listings',
      body: {
        'title': title.trim(),
        'priceCents': priceCents,
        'category': category,
        'description': description.trim(),
        'imageUrl': ?imageUrl,
      },
    );
    return Listing.fromJson(data as Map<String, dynamic>, baseUrl: _base);
  }
}
