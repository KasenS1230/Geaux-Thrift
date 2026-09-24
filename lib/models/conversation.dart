/// A single chat bubble inside a conversation.
class Message {
  const Message({
    required this.text,
    required this.sentByMe,
    required this.sentAt,
  });

  final String text;

  /// True when the current user wrote it, false when the other person did.
  final bool sentByMe;
  final DateTime sentAt;
}

/// A message thread between the current user and one other person.
///
/// TODO(team): back this with real accounts + a messages collection, and tie
/// each conversation to the listing it started from.
class Conversation {
  const Conversation({
    required this.id,
    required this.otherUserName,
    required this.listingTitle,
    required this.messages,
    this.unread = false,
  });

  final String id;
  final String otherUserName;

  /// Which item the two people are talking about.
  final String listingTitle;
  final List<Message> messages;
  final bool unread;

  Message get lastMessage => messages.last;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return otherUserName.toLowerCase().contains(q) ||
        listingTitle.toLowerCase().contains(q);
  }
}
