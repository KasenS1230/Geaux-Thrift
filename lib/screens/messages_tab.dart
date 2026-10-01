import 'package:flutter/material.dart';

import '../data/message_store.dart';
import '../models/conversation.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

/// Tab 2: every conversation the user has with a buyer or seller.
///
/// Threads come from [MessageStore], which keeps them on the device.
class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key, required this.query, required this.store});

  final String query;
  final MessageStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final conversations =
            store.conversations.where((c) => c.matches(query)).toList();

        if (conversations.isEmpty) {
          return const Center(child: Text('No conversations yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: conversations.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _ConversationTile(conversation: conversation, store: store);
          },
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.store});

  final Conversation conversation;
  final MessageStore store;

  @override
  Widget build(BuildContext context) {
    final last = conversation.lastMessage;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: LsuColors.purple,
        child: Text(
          conversation.otherUserName.characters.first,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      title: Text(
        conversation.otherUserName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Re: ${conversation.listingTitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: LsuColors.purple),
          ),
          Text(
            last.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: conversation.unread
          ? const CircleAvatar(radius: 5, backgroundColor: LsuColors.gold)
          : null,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ChatScreen(store: store, conversationId: conversation.id),
          ),
        );
      },
    );
  }
}
