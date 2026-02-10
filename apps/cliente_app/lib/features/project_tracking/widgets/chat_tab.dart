import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/project_providers.dart';
import '../models/project_models.dart';

class ChatTab extends ConsumerStatefulWidget {
  final String projectId;
  const ChatTab({super.key, required this.projectId});

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      await ref.read(projectRepositoryProvider).sendMessage(
            widget.projectId,
            text,
          );
      // Auto-scroll handled by list build usually or stream update
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(projectChatProvider(widget.projectId));

    return Column(
      children: [
        // Chat List
        Expanded(
          child: chatAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay mensajes aún. ¡Inicia la conversación!',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              // Reverse list for chat bubbling (newest at bottom visually, so list needs to be reversed or ListView.reverse)
              // API returns oldest first (ascending).
              // So for ListView(reverse: true), we need Newest First.
              // Let's reverse data locally or change query. Query was asc usually for chat logs.
              // Standard Chat UI: ListView reverse=true, data[0] is newest.
              // If API returns Oldest -> Newest (1, 2, 3), we need (3, 2, 1).
              final reversedMessages = messages.reversed.toList();

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: reversedMessages.length,
                itemBuilder: (context, index) {
                  final msg = reversedMessages[index];
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;
                  final isMe = msg.usuarioRef == currentUserId;

                  return _ChatMessageBubble(message: msg, isMe: isMe);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading chat: $e')),
          ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ProjectChatModel message;
  final bool isMe;
  const _ChatMessageBubble({required this.message, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundImage: message.photoDesnormalizado != null
                  ? NetworkImage(message.photoDesnormalizado!)
                  : null,
              child: message.photoDesnormalizado == null
                  ? Text(message.nombreDesnormalizado != null &&
                          message.nombreDesnormalizado!.isNotEmpty
                      ? message.nombreDesnormalizado![0].toUpperCase()
                      : '?')
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.nombreDesnormalizado != null && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.nombreDesnormalizado!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFD97706) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          isMe ? const Radius.circular(16) : Radius.zero,
                      bottomRight:
                          isMe ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(message.mensaje,
                          style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : Colors.black87)),
                      const SizedBox(height: 4),
                      Text(time,
                          style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.grey[400])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: message.photoDesnormalizado != null
                  ? NetworkImage(message.photoDesnormalizado!)
                  : null,
              child:
                  message.photoDesnormalizado == null ? const Text('YO') : null,
            ),
          ] else ...[
            const SizedBox(width: 32), // Spacer for width limit
          ],
        ],
      ),
    );
  }
}
