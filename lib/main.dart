import 'package:flutter/material.dart';

import 'data/listing_repository.dart';
import 'data/message_store.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LsuPopApp());
}

/// LSU Pop — buy and sell LSU merch, like Depop but for LSU.
class LsuPopApp extends StatelessWidget {
  const LsuPopApp({super.key, this.repository, this.messageStore});
  final ListingRepository? repository;
  final MessageStore? messageStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LSU Pop',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // TODO(team): add a sign-in screen in front of this once we have accounts.
      home: HomeScreen(repository: repository, messageStore: messageStore),
    );
  }
}
