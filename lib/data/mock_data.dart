import '../models/conversation.dart';

// Messaging remains demo-only until the messaging API is implemented.
final List<Conversation> mockConversations = [
  Conversation(
    id: 'c1',
    otherUserName: 'Kasen S.',
    listingTitle: 'Vintage LSU Crewneck',
    unread: true,
    messages: [
      Message(
        text: 'Hey! Is the crewneck still available?',
        sentByMe: true,
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Message(
        text: 'Yes it is! I can meet at the Union tomorrow.',
        sentByMe: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
    ],
  ),
  Conversation(
    id: 'c2',
    otherUserName: 'Priya R.',
    listingTitle: 'Student Ticket — LSU vs Ole Miss',
    messages: [
      Message(
        text: 'Would you take \$50 for the ticket?',
        sentByMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Message(
        text: 'Sorry, holding at 60 for now.',
        sentByMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 22)),
      ),
    ],
  ),
  Conversation(
    id: 'c3',
    otherUserName: 'Alyssa B.',
    listingTitle: 'LSU Mike the Tiger Mug',
    messages: [
      Message(
        text: 'Thanks for the mug, it looks great on my desk!',
        sentByMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ],
  ),
];
