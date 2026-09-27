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
const server = createApp(db);
server.listen(0, '127.0.0.1', () => console.log(server.address().port));
''',
          ],
          environment: {'DB_PATH': '${directory.path}/listings.sqlite'},
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
        final saved = await repo!.create(
          title: 'Integration Mug',
          priceCents: 825,
          category: 'Dorm',
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
      } finally {
        await stop();
        await directory.delete(recursive: true);
      }
    },
    skip: !const bool.fromEnvironment('RUN_SERVER_INTEGRATION'),
  );
}
