import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lsupop/data/message_store.dart';
import 'package:lsupop/data/mock_data.dart';
import 'package:lsupop/models/conversation.dart';

Conversation thread({String id = 'c1', List<Message>? messages}) => Conversation(
  id: id,
  otherUserName: 'Kasen S.',
  listingTitle: 'Vintage LSU Crewneck',
  messages:
      messages ??
      [Message(text: 'First', sentByMe: true, sentAt: DateTime(2026, 1, 1))],
);

void main() {
  group('round-tripping through JSON', () {
    test('a message keeps its text, side and timestamp', () {
      final before = Message(
        text: 'Meet at the Union?',
        sentByMe: true,
        sentAt: DateTime(2026, 1, 1, 14, 30),
      );
      final after = Message.fromJson(jsonDecode(jsonEncode(before.toJson())));
      expect(after.text, before.text);
      expect(after.sentByMe, before.sentByMe);
      expect(after.sentAt, before.sentAt);
    });
    test('a conversation keeps its fields and every message', () {
      final before = mockConversations.first;
      final after = Conversation.fromJson(
        jsonDecode(jsonEncode(before.toJson())),
      );
      expect(after.id, before.id);
      expect(after.otherUserName, before.otherUserName);
      expect(after.listingTitle, before.listingTitle);
      expect(after.unread, before.unread);
      expect(
        after.messages.map((m) => m.text),
        before.messages.map((m) => m.text),
      );
    });
  });

  group('loading', () {
    test('a first run starts from the demo threads', () async {
      final store = MessageStore(storage: InMemoryMessageStorage());
      await store.load();
      expect(store.isLoaded, isTrue);
      expect(
        store.conversations.map((c) => c.id),
        mockConversations.map((c) => c.id),
      );
    });
    test('isLoaded is false until load finishes', () {
      expect(MessageStore(storage: InMemoryMessageStorage()).isLoaded, isFalse);
      expect(MessageStore(storage: InMemoryMessageStorage()).conversations,
          isEmpty);
    });
    test('stored threads win over the demo threads', () async {
      final stored = jsonEncode([
        thread(id: 'stored').toJson(),
      ]);
      final store = MessageStore(storage: InMemoryMessageStorage(stored));
      await store.load();
      expect(store.conversations.single.id, 'stored');
    });
    test('unreadable stored JSON falls back to the demo threads', () async {
      for (final junk in ['not json at all', '{"not":"a list"}', '[{"id":1}]']) {
        final store = MessageStore(storage: InMemoryMessageStorage(junk));
        await store.load();
        expect(
          store.conversations.map((c) => c.id),
          mockConversations.map((c) => c.id),
          reason: junk,
        );
      }
    });
  });

  group('sending', () {
    test('appends the message as mine and persists it', () async {
      final storage = InMemoryMessageStorage();
      final store = MessageStore(storage: storage, seed: [thread()]);
      await store.load();
      await store.send('c1', 'Meet at the Union?');

      final sent = store.byId('c1')!.messages.last;
      expect(sent.text, 'Meet at the Union?');
      expect(sent.sentByMe, isTrue);

      // The whole point: a fresh store reading the same storage sees it.
      final reopened = MessageStore(storage: storage);
      await reopened.load();
      expect(reopened.byId('c1')!.messages.last.text, 'Meet at the Union?');
    });
    test('surrounding whitespace is trimmed off', () async {
      final store = MessageStore(
        storage: InMemoryMessageStorage(),
        seed: [thread()],
      );
      await store.load();
      await store.send('c1', '  hello  ');
      expect(store.byId('c1')!.messages.last.text, 'hello');
    });
    test('blank and whitespace-only text is ignored', () async {
      final store = MessageStore(
        storage: InMemoryMessageStorage(),
        seed: [thread()],
      );
      await store.load();
      final before = store.byId('c1')!.messages.length;
      await store.send('c1', '');
      await store.send('c1', '    ');
      expect(store.byId('c1')!.messages.length, before);
    });
    test('an unknown conversation id is ignored', () async {
      final store = MessageStore(
        storage: InMemoryMessageStorage(),
        seed: [thread()],
      );
      await store.load();
      await store.send('nope', 'into the void');
      expect(store.byId('c1')!.messages.length, 1);
      expect(store.byId('nope'), isNull);
    });
    test('listeners are notified so the UI rebuilds', () async {
      final store = MessageStore(
        storage: InMemoryMessageStorage(),
        seed: [thread()],
      );
      await store.load();
      var notified = 0;
      store.addListener(() => notified++);
      await store.send('c1', 'ping');
      expect(notified, 1);
      // Ignored sends must not churn the UI.
      await store.send('c1', '   ');
      await store.send('nope', 'ping');
      expect(notified, 1);
    });
    test('seeding never mutates the shared demo list', () async {
      final before = mockConversations.first.messages.length;
      final store = MessageStore(storage: InMemoryMessageStorage());
      await store.load();
      await store.send(mockConversations.first.id, 'local only');
      expect(mockConversations.first.messages.length, before);
    });
  });

  test('conversations is an unmodifiable snapshot', () async {
    final store = MessageStore(
      storage: InMemoryMessageStorage(),
      seed: [thread()],
    );
    await store.load();
    expect(
      () => store.conversations.add(thread(id: 'c2')),
      throwsUnsupportedError,
    );
  });
}
