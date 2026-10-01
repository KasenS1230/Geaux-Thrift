import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsupop/data/mock_data.dart';
import 'package:lsupop/models/conversation.dart';
import 'package:lsupop/screens/chat_screen.dart';
import 'package:lsupop/screens/messages_tab.dart';
import 'package:lsupop/theme/app_theme.dart';

Widget host(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('messages tab lists every conversation with its last message', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MessagesTab(query: '')));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(mockConversations.length));
    for (final thread in mockConversations) {
      expect(find.text(thread.otherUserName), findsOneWidget);
      expect(find.text('Re: ${thread.listingTitle}'), findsOneWidget);
      expect(find.text(thread.lastMessage.text), findsOneWidget);
    }
  });
  testWidgets('the search query narrows the conversation list', (tester) async {
    await tester.pumpWidget(host(const MessagesTab(query: 'priya')));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Priya R.'), findsOneWidget);
    expect(find.text('Kasen S.'), findsNothing);
  });
  testWidgets('a query matching nothing shows the empty message', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MessagesTab(query: 'nobody at all')));
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
  testWidgets('only unread conversations show the gold dot', (tester) async {
    await tester.pumpWidget(host(const MessagesTab(query: '')));
    await tester.pumpAndSettle();
    final unread = mockConversations.where((thread) => thread.unread).length;
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CircleAvatar &&
            widget.radius == 5 &&
            widget.backgroundColor == LsuColors.gold,
      ),
      findsNWidgets(unread),
    );
  });
  testWidgets('tapping a conversation opens its thread', (tester) async {
    await tester.pumpWidget(host(const MessagesTab(query: '')));
    await tester.pumpAndSettle();
    final thread = mockConversations.first;
    await tester.tap(find.text(thread.otherUserName));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    // The app bar repeats the name and the item being discussed.
    expect(find.text(thread.otherUserName), findsOneWidget);
    expect(find.text(thread.listingTitle), findsOneWidget);
    for (final message in thread.messages) {
      expect(find.text(message.text), findsOneWidget);
    }
  });
  testWidgets('sending a message appends it and clears the field', (
    tester,
  ) async {
    final thread = mockConversations.first;
    await tester.pumpWidget(host(ChatScreen(conversation: thread)));
    await tester.enterText(find.byType(TextField), 'Meet at the Union?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Meet at the Union?'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
  testWidgets('submitting from the keyboard sends the message too', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(ChatScreen(conversation: mockConversations.first)),
    );
    await tester.enterText(find.byType(TextField), 'On my way');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('On my way'), findsOneWidget);
  });
  testWidgets('blank and whitespace-only messages are not sent', (
    tester,
  ) async {
    final thread = mockConversations.first;
    await tester.pumpWidget(host(ChatScreen(conversation: thread)));
    final before = thread.messages.length;
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '    ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate
          .estimatedChildCount,
      before,
    );
  });
  testWidgets('sending a message does not mutate the shared demo data', (
    tester,
  ) async {
    final thread = mockConversations.first;
    final before = thread.messages.length;
    await tester.pumpWidget(host(ChatScreen(conversation: thread)));
    await tester.enterText(find.byType(TextField), 'Local only');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(thread.messages.length, before);
  });
  testWidgets('my bubbles sit right in purple, theirs left in white', (
    tester,
  ) async {
    final thread = Conversation(
      id: 'c9',
      otherUserName: 'Alyssa B.',
      listingTitle: 'LSU Mike the Tiger Mug',
      messages: [
        Message(text: 'Mine', sentByMe: true, sentAt: DateTime(2026, 1, 1)),
        Message(text: 'Theirs', sentByMe: false, sentAt: DateTime(2026, 1, 2)),
      ],
    );
    await tester.pumpWidget(host(ChatScreen(conversation: thread)));
    await tester.pumpAndSettle();
    Align bubble(String text) => tester.widget<Align>(
      find.ancestor(of: find.text(text), matching: find.byType(Align)).first,
    );
    expect(bubble('Mine').alignment, Alignment.centerRight);
    expect(bubble('Theirs').alignment, Alignment.centerLeft);
    Color? color(String text) => (tester
            .widget<Container>(
              find
                  .ancestor(
                    of: find.text(text),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration as BoxDecoration)
        .color;
    expect(color('Mine'), LsuColors.purple);
    expect(color('Theirs'), Colors.white);
  });
}
