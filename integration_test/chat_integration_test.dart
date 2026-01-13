import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naija_property_connect/data/models/chat_model.dart';
import 'package:naija_property_connect/data/services/auth_service.dart';
import 'package:naija_property_connect/data/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../test/test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Integration Tests', () {
    late ChatService chatService;
    late AuthService authService;
    String? user1Id;
    String? user2Id;

    setUpAll(() async {
      // Initialize Supabase
      await Supabase.initialize(
        url: TestConfig.supabaseUrl,
        anonKey: TestConfig.supabaseAnonKey,
      );

      chatService = ChatService();
      authService = AuthService();

      // Create/sign in as first user
      try {
        await authService.signIn(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
        );
      } catch (e) {
        await authService.signUp(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
          fullName: TestConfig.testUserFullName,
          phone: TestConfig.testUserPhone,
          role: TestConfig.testUserRole,
        );
      }

      user1Id = authService.currentUserId;
      await authService.signOut();
      await Future.delayed(TestConfig.shortDelay);

      // Create/sign in as second user
      try {
        await authService.signIn(
          email: TestConfig.testUser2Email,
          password: TestConfig.testUser2Password,
        );
      } catch (e) {
        await authService.signUp(
          email: TestConfig.testUser2Email,
          password: TestConfig.testUser2Password,
          fullName: TestConfig.testUser2FullName,
          role: TestConfig.testUser2Role,
        );
      }

      user2Id = authService.currentUserId;
      await Future.delayed(TestConfig.mediumDelay);
    });

    tearDownAll(() async {
      // Clean up: delete test messages
      final supabase = Supabase.instance.client;

      if (user1Id != null && user2Id != null) {
        try {
          await supabase
              .from('chats')
              .delete()
              .or(
                'and(sender_id.eq.$user1Id,receiver_id.eq.$user2Id),and(sender_id.eq.$user2Id,receiver_id.eq.$user1Id)',
              );
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      await authService.signOut();
    });

    test('should send a message successfully', () async {
      expect(user1Id, isNotNull);
      expect(user2Id, isNotNull);

      // Sign in as user 1
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUserEmail,
        password: TestConfig.testUserPassword,
      );
      await Future.delayed(TestConfig.shortDelay);

      // Send message to user 2
      await chatService.sendMessage(user2Id!, 'Hello from User 1!');

      // Wait for message to be saved
      await Future.delayed(TestConfig.mediumDelay);

      // Verify message was sent
      final messages = await chatService.getMessages(user2Id!);
      expect(messages, isNotEmpty);

      final sentMessage = messages.firstWhere(
        (m) => m.message == 'Hello from User 1!',
        orElse: () => throw Exception('Message not found'),
      );

      expect(sentMessage.senderId, equals(user1Id));
      expect(sentMessage.receiverId, equals(user2Id));
      expect(sentMessage.message, equals('Hello from User 1!'));
    });

    test('should receive messages from another user', () async {
      expect(user1Id, isNotNull);
      expect(user2Id, isNotNull);

      // Sign in as user 2
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUser2Email,
        password: TestConfig.testUser2Password,
      );
      await Future.delayed(TestConfig.shortDelay);

      // Send message to user 1
      await chatService.sendMessage(user1Id!, 'Hello from User 2!');
      await Future.delayed(TestConfig.mediumDelay);

      // Sign in as user 1
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUserEmail,
        password: TestConfig.testUserPassword,
      );
      await Future.delayed(TestConfig.shortDelay);

      // Get messages
      final messages = await chatService.getMessages(user2Id!);
      expect(messages, isNotEmpty);

      final receivedMessage = messages.firstWhere(
        (m) => m.message == 'Hello from User 2!',
        orElse: () => throw Exception('Message not found'),
      );

      expect(receivedMessage.senderId, equals(user2Id));
      expect(receivedMessage.receiverId, equals(user1Id));
      expect(receivedMessage.message, equals('Hello from User 2!'));
    });

    test('should get messages in chronological order', () async {
      expect(user1Id, isNotNull);
      expect(user2Id, isNotNull);

      // Sign in as user 1
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUserEmail,
        password: TestConfig.testUserPassword,
      );
      await Future.delayed(TestConfig.shortDelay);

      // Send multiple messages
      await chatService.sendMessage(user2Id!, 'Message 1');
      await Future.delayed(TestConfig.shortDelay);

      await chatService.sendMessage(user2Id!, 'Message 2');
      await Future.delayed(TestConfig.shortDelay);

      await chatService.sendMessage(user2Id!, 'Message 3');
      await Future.delayed(TestConfig.mediumDelay);

      // Get messages
      final messages = await chatService.getMessages(user2Id!);

      // Find our test messages
      final testMessages = messages
          .where((m) => m.message.startsWith('Message '))
          .toList();

      expect(testMessages.length, greaterThanOrEqualTo(3));

      // Verify chronological order
      for (int i = 0; i < testMessages.length - 1; i++) {
        expect(
          testMessages[i].createdAt.isBefore(testMessages[i + 1].createdAt) ||
              testMessages[i].createdAt.isAtSameMomentAs(
                testMessages[i + 1].createdAt,
              ),
          isTrue,
        );
      }
    });

    test('should stream real-time messages', () async {
      expect(user1Id, isNotNull);
      expect(user2Id, isNotNull);

      // Sign in as user 1
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUserEmail,
        password: TestConfig.testUserPassword,
      );
      await Future.delayed(TestConfig.shortDelay);

      // Set up message stream
      final messageStream = chatService.getMessageStream(user2Id!);
      expect(messageStream, isA<Stream<List<ChatModel>>>());

      final completer = Completer<bool>();
      late StreamSubscription subscription;

      // Listen to stream
      subscription = messageStream.listen((messages) {
        // Check if our test message arrived
        final hasTestMessage = messages.any(
          (m) => m.message == 'Real-time test message',
        );

        if (hasTestMessage && !completer.isCompleted) {
          completer.complete(true);
        }
      });

      // Wait a bit for stream to initialize
      await Future.delayed(TestConfig.mediumDelay);

      // Send a message
      await chatService.sendMessage(user2Id!, 'Real-time test message');

      // Wait for message to arrive via stream
      final received = await completer.future.timeout(
        TestConfig.realtimeTimeout,
        onTimeout: () => false,
      );

      expect(received, isTrue);
      await subscription.cancel();
    });

    test('should get list of chat partners', () async {
      expect(user1Id, isNotNull);
      expect(user2Id, isNotNull);

      // Sign in as user 1
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUserEmail,
        password: TestConfig.testUserPassword,
      );
      await Future.delayed(TestConfig.shortDelay);

      // Ensure at least one message exists
      await chatService.sendMessage(user2Id!, 'Partner test message');
      await Future.delayed(TestConfig.mediumDelay);

      // Get chat partners
      final partners = await chatService.getChatPartners();

      expect(partners, isA<List<String>>());
      expect(partners, contains(user2Id));
    });

    test('should handle bidirectional conversation', () async {
      expect(user1Id, isNotNull);
      expect(user2Id, isNotNull);

      // User 1 sends message
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUserEmail,
        password: TestConfig.testUserPassword,
      );
      await Future.delayed(TestConfig.shortDelay);

      await chatService.sendMessage(user2Id!, 'User 1 to User 2');
      await Future.delayed(TestConfig.mediumDelay);

      // User 2 sends message
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUser2Email,
        password: TestConfig.testUser2Password,
      );
      await Future.delayed(TestConfig.shortDelay);

      await chatService.sendMessage(user1Id!, 'User 2 to User 1');
      await Future.delayed(TestConfig.mediumDelay);

      // User 1 gets all messages
      await authService.signOut();
      await authService.signIn(
        email: TestConfig.testUserEmail,
        password: TestConfig.testUserPassword,
      );
      await Future.delayed(TestConfig.shortDelay);

      final messages = await chatService.getMessages(user2Id!);

      // Should have both messages
      final user1Message = messages.any(
        (m) => m.message == 'User 1 to User 2' && m.senderId == user1Id,
      );
      final user2Message = messages.any(
        (m) => m.message == 'User 2 to User 1' && m.senderId == user2Id,
      );

      expect(user1Message, isTrue);
      expect(user2Message, isTrue);
    });
  });
}
