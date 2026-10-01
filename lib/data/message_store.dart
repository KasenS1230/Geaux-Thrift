import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation.dart';
import 'mock_data.dart';

/// Where [MessageStore] keeps its JSON.
///
/// Abstracted so widget tests can run without the platform channel that
/// shared_preferences needs — pass an [InMemoryMessageStorage] instead.
abstract class MessageStorage {
  Future<String?> read();
  Future<void> write(String value);
}

/// Device storage, backed by shared_preferences.
class PreferencesMessageStorage implements MessageStorage {
  static const String key = 'lsupop.conversations.v1';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
}

/// Non-persistent storage for tests.
class InMemoryMessageStorage implements MessageStorage {
  InMemoryMessageStorage([this._value]);

  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;
}

/// Every conversation the user has, kept on this device only.
///
/// Nothing here touches the server: the API has no messages table, so threads
/// live in [MessageStorage] and never leave the phone. The demo threads in
/// [mockConversations] are the starting point the first time the app runs;
/// after that the stored copy wins, and [mockConversations] is left untouched.
class MessageStore extends ChangeNotifier {
  MessageStore({MessageStorage? storage, List<Conversation>? seed})
    : _storage = storage ?? PreferencesMessageStorage(),
      _seed = seed ?? mockConversations;

  final MessageStorage _storage;
  final List<Conversation> _seed;

  List<Conversation> _conversations = [];
  bool _loaded = false;

  /// Unmodifiable snapshot of every thread, newest message last.
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  /// False until [load] finishes, so the UI can wait instead of flashing empty.
  bool get isLoaded => _loaded;

  Conversation? byId(String id) {
    for (final thread in _conversations) {
      if (thread.id == id) return thread;
    }
    return null;
  }

  /// Reads stored threads, falling back to the demo threads on a first run, if
  /// what was stored can no longer be parsed, or if storage is unavailable.
  ///
  /// Never throws: messaging is demo-grade, and a device that cannot hand back
  /// its saved threads should still show the app rather than an error.
  Future<void> load() async {
    String? raw;
    try {
      raw = await _storage.read();
    } on Object {
      raw = null;
    }
    _conversations = _decode(raw) ?? _copyOfSeed();
    _loaded = true;
    notifyListeners();
  }

  /// Appends [text] to a thread as a message from the current user and saves.
  ///
  /// Blank and whitespace-only text is ignored, as is an unknown [id].
  Future<void> send(String id, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final index = _conversations.indexWhere((thread) => thread.id == id);
    if (index == -1) return;

    final thread = _conversations[index];
    _conversations[index] = thread.copyWith(
      messages: [
        ...thread.messages,
        Message(text: trimmed, sentByMe: true, sentAt: DateTime.now()),
      ],
    );
    notifyListeners();
    await _save();
  }

  /// Writes the whole list back. Failing to save must not take down the send
  /// the user just made — it is already in memory and on screen.
  Future<void> _save() async {
    try {
      await _storage.write(
        jsonEncode(_conversations.map((thread) => thread.toJson()).toList()),
      );
    } on Object catch (error) {
      debugPrint('Could not save conversations: $error');
    }
  }

  /// Deep copy, so seeding never mutates [mockConversations].
  List<Conversation> _copyOfSeed() => _seed
      .map((thread) => thread.copyWith(messages: [...thread.messages]))
      .toList();

  /// Null when there is nothing stored or the stored JSON is unusable.
  List<Conversation>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      // A stored thread we can no longer read is not worth crashing over;
      // start the user over from the demo threads.
      return null;
    }
  }
}
