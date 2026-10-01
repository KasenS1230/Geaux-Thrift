/// A single chat bubble inside a conversation.
class Message {
  const Message({
    required this.text,
    required this.sentByMe,
    required this.sentAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    text: json['text'] as String,
    sentByMe: json['sentByMe'] as bool,
    sentAt: DateTime.parse(json['sentAt'] as String),
  );

  final String text;

  /// True when the current user wrote it, false when the other person did.
  final bool sentByMe;
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
    'text': text,
    'sentByMe': sentByMe,
    'sentAt': sentAt.toIso8601String(),
  };
}

/// A message thread between the current user and one other person.
///
/// Stored on the device by [MessageStore]; nothing is sent to the server.
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

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    otherUserName: json['otherUserName'] as String,
    listingTitle: json['listingTitle'] as String,
    unread: json['unread'] as bool? ?? false,
    messages: (json['messages'] as List<dynamic>)
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

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

  Conversation copyWith({List<Message>? messages, bool? unread}) =>
      Conversation(
        id: id,
        otherUserName: otherUserName,
        listingTitle: listingTitle,
        messages: messages ?? this.messages,
        unread: unread ?? this.unread,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'otherUserName': otherUserName,
    'listingTitle': listingTitle,
    'unread': unread,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
}
