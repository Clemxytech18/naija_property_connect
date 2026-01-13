import 'package:flutter/material.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/property_model.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/property_service.dart';
import '../../data/services/notification_service.dart';
import 'property_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  final PropertyModel? propertyContext;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    this.otherUserName,
    this.propertyContext,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _currentUserId;
  String? _otherName;

  // Cache for properties mentioned in chat
  final Map<String, PropertyModel> _propertyCache = {};
  final Set<String> _loadingProperties = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.currentUserId!;
    _otherName = widget.otherUserName;

    if (_otherName == null) {
      _fetchOtherUserName();
    }

    if (widget.propertyContext != null) {
      _propertyCache[widget.propertyContext!.id] = widget.propertyContext!;
    }
  }

  Future<void> _fetchOtherUserName() async {
    final user = await _authService.getUserById(widget.otherUserId);
    if (mounted && user != null) {
      setState(() {
        _otherName = user.fullName;
      });
    }
  }

  Future<void> _fetchProperty(String propertyId) async {
    if (_propertyCache.containsKey(propertyId) ||
        _loadingProperties.contains(propertyId)) {
      return;
    }

    _loadingProperties.add(propertyId);
    try {
      final prop = await _propertyService.getPropertyById(propertyId);
      if (mounted && prop != null) {
        setState(() {
          _propertyCache[propertyId] = prop;
        });
      }
    } finally {
      _loadingProperties.remove(propertyId);
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    try {
      await _chatService.sendMessage(
        widget.otherUserId,
        text,
        propertyId: widget.propertyContext?.id,
      );

      // Send notification to recipient
      await NotificationService().createNotification(
        userId: widget.otherUserId,
        title: 'New Message',
        body:
            '${_authService.currentUser?.email?.split('@')[0] ?? 'User'} sent you a message: $text',
        category: 'messages',
        relatedEntityId: null, // Could be chat room ID if we had one
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100, // Small buffer
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_otherName ?? 'Chat', style: const TextStyle(fontSize: 16)),
            if (widget.propertyContext != null)
              Text(
                'Re: ${widget.propertyContext!.title}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Optional Sticky Context for new chats
          if (widget.propertyContext != null)
            _buildStickyPropertyHeader(widget.propertyContext!),

          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.getMessageStream(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                // Auto-scroll on new data
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _currentUserId;

                    // Trigger fetch if property info missing
                    if (msg.propertyId != null &&
                        !_propertyCache.containsKey(msg.propertyId)) {
                      _fetchProperty(msg.propertyId!);
                    }

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (msg.propertyId != null &&
                                _propertyCache.containsKey(msg.propertyId))
                              _buildPropertyBubble(
                                _propertyCache[msg.propertyId]!,
                                isMe,
                              ),

                            Text(
                              msg.message,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: widget.propertyContext != null
                            ? 'Ask about ${widget.propertyContext!.title}...'
                            : 'Type a message...',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyPropertyHeader(PropertyModel property) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: property.images.isNotEmpty
              ? Image.network(
                  property.images.first,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.grey,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.home),
                ),
        ),
        title: Text(
          property.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('₦${property.price?.toStringAsFixed(0)}/yr'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertyBubble(PropertyModel property, bool isMe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(property: property),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: property.images.isNotEmpty
                  ? Image.network(
                      property.images.first,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.home, size: 20),
                    ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₦${property.price?.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
