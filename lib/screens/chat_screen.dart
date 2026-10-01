import 'package:flutter/material.dart';

import '../data/message_store.dart';
import '../models/conversation.dart';
import '../theme/app_theme.dart';

/// One message thread.
///
/// Reads and writes through [MessageStore], so a sent message survives leaving
/// the screen and restarting the app. It stays on this device — see
/// [MessageStore] for why there is no server call here.
///
/// TODO(team): add read receipts, images, and an offer flow.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.store,
    required this.conversationId,
  });

  final MessageStore store;
  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    widget.store.send(widget.conversationId, text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final conversation = widget.store.byId(widget.conversationId);
        if (conversation == null) {
          // The thread was removed out from under us; nothing to show.
          return const Scaffold(
            body: Center(child: Text('This conversation is no longer here.')),
          );
        }
        final messages = conversation.messages;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conversation.otherUserName),
                Text(
                  conversation.listingTitle,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _MessageBubble(message: messages[index]),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Message',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send, color: LsuColors.purple),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final mine = message.sentByMe;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? LsuColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: mine ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
