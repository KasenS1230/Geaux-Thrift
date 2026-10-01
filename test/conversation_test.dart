import 'package:flutter_test/flutter_test.dart';
import 'package:lsupop/data/mock_data.dart';
import 'package:lsupop/models/conversation.dart';

Conversation conversation({
  String otherUserName = 'Kasen S.',
  String listingTitle = 'Vintage LSU Crewneck',
  bool unread = false,
}) => Conversation(
  id: 'c1',
  otherUserName: otherUserName,
  listingTitle: listingTitle,
  unread: unread,
  messages: [
    Message(text: 'First', sentByMe: true, sentAt: DateTime(2026, 1, 1)),
    Message(text: 'Last', sentByMe: false, sentAt: DateTime(2026, 1, 2)),
  ],
);

void main() {
  test('lastMessage is the most recently appended message', () {
    expect(conversation().lastMessage.text, 'Last');
    expect(conversation().lastMessage.sentByMe, isFalse);
  });
  test('matches searches the other person and the listing, ignoring case', () {
    final thread = conversation();
    for (final query in ['kasen', 'KASEN', 'crewneck', ' lsu ']) {
      expect(thread.matches(query), isTrue, reason: query);
    }
  });
  test('an empty query matches every conversation', () {
    expect(conversation().matches(''), isTrue);
    expect(conversation().matches('   '), isTrue);
  });
  test('matches ignores the message text itself', () {
    expect(conversation().matches('Last'), isFalse);
    expect(conversation().matches('kayak'), isFalse);
  });
  test('unread defaults to false', () {
    expect(conversation().unread, isFalse);
    expect(conversation(unread: true).unread, isTrue);
  });
  test('every demo conversation is usable by the messages list', () {
    expect(mockConversations, isNotEmpty);
    for (final thread in mockConversations) {
      expect(thread.id, isNotEmpty);
      expect(thread.otherUserName, isNotEmpty);
      expect(thread.listingTitle, isNotEmpty);
      // The list tile renders lastMessage and the first initial of the name.
      expect(thread.messages, isNotEmpty);
      expect(thread.lastMessage.text, isNotEmpty);
    }
    expect(
      mockConversations.map((thread) => thread.id).toSet().length,
      mockConversations.length,
    );
  });
}
