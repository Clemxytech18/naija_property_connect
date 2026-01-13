import 'package:flutter/material.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  List<UserModel> _partners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      final partnerIds = await _chatService.getChatPartners();
      final users = await _authService.getUsersByIds(partnerIds);

      if (mounted) {
        setState(() {
          _partners = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _partners.isEmpty
          ? const Center(child: Text('No messages yet'))
          : ListView.builder(
              itemCount: _partners.length,
              itemBuilder: (context, index) {
                final user = _partners[index];
                final name = user.fullName ?? 'User';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    backgroundImage: (user.avatarUrl?.isNotEmpty ?? false)
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: (user.avatarUrl?.isNotEmpty ?? false)
                        ? null
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                  ),
                  title: Text(name),
                  subtitle: const Text('Tap to chat'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUserId: user.id,
                          otherUserName: name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
