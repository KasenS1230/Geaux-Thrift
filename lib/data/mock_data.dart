import '../models/conversation.dart';
import '../models/listing.dart';

/// Fake data so the UI has something to show.
///
/// TODO(team): delete this file once listings and messages come from a real
/// data source. Everything that reads it should go through a repository class
/// so swapping the source only touches one place.
const List<String> kCategories = [
  'All',
  'Apparel',
  'Game Day',
  'Dorm',
  'Tickets',
  'Books',
];

final List<Listing> mockListings = [
  const Listing(
    id: '1',
    title: 'Vintage LSU Crewneck',
    price: 35,
    sellerName: 'Kasen S.',
    category: 'Apparel',
    size: 'L',
    condition: 'Great',
    description:
        'Faded purple crewneck from the 90s. Barely worn, no stains or holes.',
  ),
  const Listing(
    id: '2',
    title: 'Game Day Dress — purple & gold',
    price: 48,
    sellerName: 'Nhi T.',
    category: 'Game Day',
    size: 'S',
    condition: 'Like new',
    description: 'Worn once to the Bama game. Smoke free dorm.',
  ),
  const Listing(
    id: '3',
    title: 'Tiger Stadium Poster (framed)',
    price: 20,
    sellerName: 'Marcus L.',
    category: 'Dorm',
    condition: 'Good',
    description: 'Framed print, about 18x24. Pickup near the Quad.',
  ),
  const Listing(
    id: '4',
    title: 'Student Ticket — LSU vs Ole Miss',
    price: 60,
    sellerName: 'Priya R.',
    category: 'Tickets',
    condition: 'New',
    description: 'Selling at face value, can transfer through the app.',
  ),
  const Listing(
    id: '5',
    title: 'CSC 4330 Textbook',
    price: 25,
    sellerName: 'Devon W.',
    category: 'Books',
    condition: 'Good',
    description: 'Some highlighting in the first few chapters.',
  ),
  const Listing(
    id: '6',
    title: 'LSU Mike the Tiger Mug',
    price: 8,
    sellerName: 'Alyssa B.',
    category: 'Dorm',
    condition: 'Like new',
    description: 'Ceramic, dishwasher safe. Never actually used it.',
  ),
  const Listing(
    id: '7',
    title: 'Purple Jersey #7',
    price: 55,
    sellerName: 'Kasen S.',
    category: 'Apparel',
    size: 'M',
    condition: 'Great',
    description: 'Authentic stitched jersey, fits true to size.',
  ),
  const Listing(
    id: '8',
    title: 'Tailgate Folding Chairs (pair)',
    price: 30,
    sellerName: 'Jordan M.',
    category: 'Game Day',
    condition: 'Good',
    description: 'Two matching chairs with LSU logo. Cup holders work.',
  ),
];

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
