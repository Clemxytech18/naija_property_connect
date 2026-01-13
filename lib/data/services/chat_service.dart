import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/chat_model.dart';

class ChatService {
  final SupabaseClient _supabase = SupabaseService().client;

  // Send a message
  Future<void> sendMessage(
    String receiverId,
    String message, {
    String? propertyId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'sender_id': user.id,
      'receiver_id': receiverId,
      'message': message,
      // 'created_at' is handled by default in DB usually
    };

    if (propertyId != null) {
      data['property_id'] = propertyId;
    }

    await _supabase.from('chats').insert(data);
  }

  // Get messages between current user and another user
  Future<List<ChatModel>> getMessages(String otherUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = await _supabase
        .from('chats')
        .select()
        .or(
          'and(sender_id.eq.${user.id},receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.${user.id})',
        )
        .order('created_at', ascending: true);

    return (data as List).map((e) => ChatModel.fromJson(e)).toList();
  }

  // Subscribe to new messages for a specific conversation
  Stream<List<ChatModel>> getMessageStream(String otherUserId) {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Supabase Realtime 'stream' returns the current state of selected rows
    // and updates on changes.
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .order('created_at', ascending: true)
        .map((data) {
          // Force sort locally as well just in case stream order is flaky on updates
          data.sort(
            (a, b) => (a['created_at'] as String).compareTo(
              b['created_at'] as String,
            ),
          );

          // Filter client-side for the specific conversation
          // Note: Row Level Security (RLS) should ideally filter this on server,
          // but stream() often gets more data if not scoped carefully.
          // For now, we filter manually to ensure we only see relevant chats.

          final messages = data.map((e) => ChatModel.fromJson(e)).toList();
          return messages
              .where(
                (m) =>
                    (m.senderId == user.id && m.receiverId == otherUserId) ||
                    (m.senderId == otherUserId && m.receiverId == user.id),
              )
              .toList();
        });
  }

  // Get list of users the current user has chatted with
  // This is complex with just a 'chats' table.
  // Naive approach: fetch all chats involved, map to unique IDs.
  // Better approach: Separate 'conversations' table.
  // We will stick to naive for MVP.
  Future<List<String>> getChatPartners() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final data = await _supabase
        .from('chats')
        .select('sender_id, receiver_id')
        .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}');

    final Set<String> partnerIds = {};
    for (var row in data) {
      if (row['sender_id'] != user.id) partnerIds.add(row['sender_id']);
      if (row['receiver_id'] != user.id) partnerIds.add(row['receiver_id']);
    }

    return partnerIds.toList();
  }
}
