import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lsupop/data/listing_repository.dart';

void main() {
  test(
    'real server persists a Flutter-created listing across restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('lsupop-client-');
      Process? server;
      ListingRepository? repo;
      Future<void> start() async {
        server = await Process.start(
          'node',
          [
            '--input-type=module',
            '-e',
            '''
import { openDatabase } from './server/src/database.js';
import { createApp } from './server/src/app.js';
const db = openDatabase(process.env.DB_PATH);
const server = createApp(db, { imageDir: process.env.IMAGE_DIR });
server.listen(0, '127.0.0.1', () => console.log(server.address().port));
''',
          ],
          environment: {
            'DB_PATH': '${directory.path}/listings.sqlite',
            'IMAGE_DIR': '${directory.path}/images',
          },
        );
        server!.stderr.drain<void>();
        final port = await server!.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .first
            .timeout(const Duration(seconds: 10));
        repo = ListingRepository(baseUrl: 'http://127.0.0.1:$port');
      }

      Future<void> stop() async {
        repo?.close();
        if (server != null) {
          server!.kill();
          await server!.exitCode.timeout(const Duration(seconds: 10));
          server = null;
        }
      }

      try {
        await start();
        final photo = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGNgAAAAAg'
          'ABf/+3TAAAAABJRU5ErkJggg==',
        );
        final imageUrl = await repo!.uploadImage(
          photo,
          contentType: 'image/png',
        );
        final saved = await repo!.create(
          title: 'Integration Mug',
          priceCents: 825,
          category: 'Dorm',
          imageUrl: imageUrl,
        );
        await stop();
        await start();
        final items = await repo!.fetch(
          query: 'Integration',
          category: 'Dorm',
          minPriceCents: 825,
          maxPriceCents: 825,
        );
        expect(items.single.id, saved.id);
        expect(items.single.price, 8.25);
        // The model hands screens a URL that really serves the photo back.
        expect(items.single.imageUrl, endsWith(imageUrl));
        final client = HttpClient();
        final response = await (await client.getUrl(
          Uri.parse(items.single.imageUrl!),
        )).close();
        expect(response.statusCode, 200);
        expect(
          await response.fold<List<int>>(
            [],
            (bytes, chunk) => bytes..addAll(chunk),
          ),
          photo,
        );
        client.close();
      } finally {
        await stop();
        await directory.delete(recursive: true);
      }
    },
    skip: !const bool.fromEnvironment('RUN_SERVER_INTEGRATION'),
  );
}
