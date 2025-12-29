import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/project_providers.dart';
import '../../models/project_models.dart';

class ProjectChatSection extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectChatSection({super.key, required this.projectId});

  @override
  ConsumerState<ProjectChatSection> createState() => _ProjectChatSectionState();
}

class _ProjectChatSectionState extends ConsumerState<ProjectChatSection> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(projectRepositoryProvider).sendMessage(widget.projectId, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(projectChatProvider(widget.projectId));

    // Colors
    const primaryColor = Color(0xFFD97706); // Amber-600

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat del Proyecto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: chatAsync.when(
              data: (messages) {
                // Reverse for chat
                final reversed = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: reversed.length,
                  itemBuilder: (context, index) {
                    final msg = reversed[index];
                    // TODO: Replace with real ID check
                    // For demo purposes, let's alternate based on message content length is even/odd?
                    // Or just default to "Others" for now, as Supabase Auth ID check needed.
                    // Assuming repo sendMessage uses authenticated user.
                    // Ideally we pass currentUserId to widget.
                    final isMe = false; // Placeholder

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _ChatBubble(
                        message: msg,
                        isMe: isMe,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F4), // Stone-100
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: primaryColor,
                    style: IconButton.styleFrom(
                      hoverColor: primaryColor.withValues(alpha: 0.1),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ProjectChatModel message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Styles
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowMainAlign = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bubbleColor = isMe
        ? const Color(0xFFD97706)
        : const Color(0xFFF5F5F4); // Amber vs Stone
    final textColor =
        isMe ? Colors.white : const Color(0xFF1F2937); // White vs Gray-800
    final timeColor =
        isMe ? Colors.white70 : const Color(0xFF9CA3AF); // White70 vs Gray-400

    final avatarColor = isMe ? Colors.green[200] : Colors.amber[200];
    final avatarText = isMe ? Colors.green[800] : Colors.amber[800];
    final initials = isMe
        ? 'ME'
        : (message.nombreDesnormalizado?.substring(0, 2).toUpperCase() ?? 'MJ');

    return Row(
      mainAxisAlignment: rowMainAlign,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            backgroundColor: avatarColor,
            foregroundColor: avatarText,
            child: Text(initials,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: align,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: rowMainAlign,
                children: [
                  Flexible(
                    child: Text(
                      isMe
                          ? 'You'
                          : (message.nombreDesnormalizado ?? 'Unknown'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1F2937)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('hh:mm a').format(message.createdAt),
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.mensaje,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              )
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: avatarColor,
            foregroundColor: avatarText,
            child: Text(initials,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ],
    );
  }
}
