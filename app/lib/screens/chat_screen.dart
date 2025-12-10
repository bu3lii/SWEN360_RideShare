import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';
import '../widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _messageService = MessageService();
  final _socketService = SocketService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  Conversation? _conversation;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSocket();
    _loadConversationAndMessages();
    _markAsRead();
  }

  Future<void> _initializeSocket() async {
    await _socketService.connect();
    
    // Set up message listener (will be activated when conversation is joined)
    _socketService.onNewMessage((data) {
      if (mounted) {
        final conversationId = _conversation?.oderId ?? widget.conversation.oderId;
        final message = Message.fromJson(data);
        // Only add if it's not already in the list and belongs to this conversation
        if ((data['conversationId'] == conversationId || 
             data['conversationId'] == null) && 
            !_messages.any((m) => m.id == message.id)) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      }
    });
  }

  Future<void> _loadConversationAndMessages() async {
    // Reload conversation to get fresh data with participant info
    final conversations = await _messageService.getConversations();
    final updatedConversation = conversations.firstWhere(
      (conv) => conv.oderId == widget.conversation.oderId,
      orElse: () => widget.conversation,
    );
    
    if (mounted) {
      setState(() {
        _conversation = updatedConversation;
      });
      
      // Initialize socket after conversation is loaded
      final conversationId = _conversation?.oderId ?? widget.conversation.oderId;
      if (conversationId.isNotEmpty) {
        _socketService.joinConversation(conversationId);
      }
    }
    
    await _loadMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final conversationId = _conversation?.oderId ?? widget.conversation.oderId;
    _socketService.leaveConversation(conversationId);
    _socketService.offNewMessage();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh messages when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    final conversationId = _conversation?.oderId ?? widget.conversation.oderId;
    final messages = await _messageService.getConversationMessages(conversationId);

    if (mounted) {
      setState(() {
        // Backend already returns messages in chronological order (oldest first)
        // Keep them in that order so newest appears at bottom
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _markAsRead() async {
    final conversationId = _conversation?.oderId ?? widget.conversation.oderId;
    await _messageService.markAsRead(conversationId);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    // Get recipient ID from current conversation
    final conversation = _conversation ?? widget.conversation;
    final recipientId = conversation.participant?.oderId;

    if (recipientId == null || recipientId.isEmpty) {
      // Try to reload conversation data
      final conversations = await _messageService.getConversations();
      final updatedConversation = conversations.firstWhere(
        (conv) => conv.oderId == conversation.oderId,
        orElse: () => conversation,
      );
      
      if (updatedConversation.participant?.oderId == null || updatedConversation.participant!.oderId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to send message. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      if (mounted) {
        setState(() {
          _conversation = updatedConversation;
        });
      }
    }

    final finalRecipientId = _conversation?.participant?.oderId ?? conversation.participant?.oderId;
    if (finalRecipientId == null || finalRecipientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send message. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();

    // Get rideId from conversation if available (use the updated conversation)
    final currentConversation = _conversation ?? conversation;
    final rideId = currentConversation.rideId;

    final message = await _messageService.sendMessage(
      recipientId: finalRecipientId,
      content: content,
      rideId: currentConversation.rideId,
    );

    if (mounted) {
      setState(() => _isSending = false);

      if (message != null) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      } else {
        // Reload messages to see if message was sent but not returned
        await _loadMessages();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleBlock() async {
    final conversation = _conversation ?? widget.conversation;
    final action = conversation.isBlocked ? 'unblock' : 'block';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.capitalize()} User'),
        content: Text(
          'Are you sure you want to $action ${conversation.participant?.name ?? 'this user'}?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: conversation.isBlocked
                  ? AppColors.primary
                  : AppColors.error,
            ),
            child: Text(action.capitalize()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final conversation = _conversation ?? widget.conversation;
      await _messageService.toggleBlock(conversation.oderId);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final conversation = _conversation ?? widget.conversation;
    final participant = conversation.participant;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: participant?.profilePicture != null
                  ? ClipOval(
                      child: Image.network(
                        participant!.profilePicture!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      participant?.initials ?? 'U',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant?.name ?? 'Unknown',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (conversation.isBlocked)
                    Text(
                      'Blocked',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                _toggleBlock();
              } else if (value == 'profile' && participant?.oderId != null) {
                Navigator.pushNamed(
                  context,
                  '/user-profile',
                  arguments: participant!.oderId,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Iconsax.user, size: 20),
                    SizedBox(width: 12),
                    Text('View Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      conversation.isBlocked
                          ? Iconsax.unlock
                          : Iconsax.slash,
                      size: 20,
                      color: conversation.isBlocked
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      conversation.isBlocked ? 'Unblock' : 'Block',
                      style: TextStyle(
                        color: conversation.isBlocked
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : _messages.isEmpty
                    ? const _EmptyChat()
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        color: AppColors.primary,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.senderId == currentUserId;
                            final showDate = index == 0 ||
                                !_isSameDay(
                                  _messages[index - 1].createdAt,
                                  message.createdAt,
                                );

                            return Column(
                              children: [
                                if (showDate)
                                  _DateDivider(date: message.createdAt),
                                _MessageBubble(
                                  message: message,
                                  isMe: isMe,
                                ).animate().fadeIn().scale(
                                      begin: const Offset(0.95, 0.95),
                                      duration: 200.ms,
                                    ),
                              ],
                            );
                          },
                        ),
                      ),
          ),

          // Message Input
          if (!conversation.isBlocked && participant != null)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(
                              Iconsax.send_1,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.errorLight,
              child: Text(
                'You have blocked this user. Unblock to send messages.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Iconsax.tick_circle : Iconsax.tick_circle,
                    size: 14,
                    color: message.isRead
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  String get _dateText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _dateText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message_text,
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
            'Send a message to start the conversation',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}