import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/theme.dart';
import '../services/message_service.dart';
import '../widgets/widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _messageService = MessageService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    final conversations = await _messageService.getConversations();

    if (mounted) {
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _messageService.deleteConversation(conversation.oderId);
      if (success && mounted) {
        _loadConversations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: LoadingIndicator())
            : _conversations.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _ConversationTile(
                        conversation: conversation,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: conversation,
                          );
                          _loadConversations();
                        },
                        onDelete: () => _deleteConversation(conversation),
                      ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1, end: 0);
                    },
                  ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return Dismissible(
      key: Key(conversation.oderId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Iconsax.trash,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false;
      },
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: conversation.participant?.profilePicture != null
                  ? ClipOval(
                      child: Image.network(
                        conversation.participant!.profilePicture!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      conversation.participant?.initials ?? 'U',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    conversation.unreadCount > 9
                        ? '9+'
                        : conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.participant?.name ?? 'Unknown',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              timeago.format(conversation.updatedAt, locale: 'en_short'),
              style: AppTextStyles.bodySmall.copyWith(
                color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessage?.content ?? 'No messages yet',
                style: AppTextStyles.bodySmall.copyWith(
                  color: hasUnread
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.isBlocked)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Blocked',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with a driver or passenger',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}