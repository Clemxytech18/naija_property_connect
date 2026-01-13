import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naija_property_connect/data/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../test/test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Integration Tests', () {
    late AuthService authService;

    setUpAll(() async {
      // Initialize Supabase
      await Supabase.initialize(
        url: TestConfig.supabaseUrl,
        anonKey: TestConfig.supabaseAnonKey,
      );
      authService = AuthService();
    });

    tearDown(() async {
      // Sign out after each test
      try {
        await authService.signOut();
      } catch (e) {
        // Ignore errors if already signed out
      }
      await Future.delayed(TestConfig.shortDelay);
    });

    test('should sign up a new user successfully', () async {
      try {
        await authService.signUp(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
          fullName: TestConfig.testUserFullName,
          phone: TestConfig.testUserPhone,
          role: TestConfig.testUserRole,
        );

        // Verify user is signed in
        final session = authService.currentSession;
        expect(session, isNotNull);
        expect(session?.user.email, equals(TestConfig.testUserEmail));
      } catch (e) {
        // If user already exists, that's okay for this test
        if (!e.toString().contains('already registered')) {
          rethrow;
        }
      }
    });

    test('should sign in with valid credentials', () async {
      // First ensure user exists
      try {
        await authService.signUp(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
          fullName: TestConfig.testUserFullName,
          phone: TestConfig.testUserPhone,
          role: TestConfig.testUserRole,
        );
      } catch (e) {
        // User might already exist
      }

      // Sign out first
      await authService.signOut();
      await Future.delayed(TestConfig.shortDelay);

      // Now sign in
      final response = await authService.signIn(
        email: TestConfig.testUserEmail,
        password: TestConfig.testUserPassword,
      );

      expect(response.session, isNotNull);
      expect(response.user, isNotNull);
      expect(response.user?.email, equals(TestConfig.testUserEmail));
    });

    test('should fail to sign in with invalid credentials', () async {
      expect(
        () async => await authService.signIn(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('should sign out successfully', () async {
      // Sign in first
      try {
        await authService.signIn(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
        );
      } catch (e) {
        // Create user if doesn't exist
        await authService.signUp(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
          fullName: TestConfig.testUserFullName,
          phone: TestConfig.testUserPhone,
          role: TestConfig.testUserRole,
        );
      }

      // Verify signed in
      expect(authService.currentSession, isNotNull);

      // Sign out
      await authService.signOut();
      await Future.delayed(TestConfig.shortDelay);

      // Verify signed out
      expect(authService.currentSession, isNull);
    });

    test('should retrieve user profile', () async {
      // Sign in first
      try {
        await authService.signIn(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
        );
      } catch (e) {
        // Create user if doesn't exist
        await authService.signUp(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
          fullName: TestConfig.testUserFullName,
          phone: TestConfig.testUserPhone,
          role: TestConfig.testUserRole,
        );
      }

      await Future.delayed(TestConfig.mediumDelay);

      final profile = await authService.getUserProfile();
      expect(profile, isNotNull);
      expect(profile?.email, equals(TestConfig.testUserEmail));
      expect(profile?.fullName, equals(TestConfig.testUserFullName));
      expect(profile?.role, equals(TestConfig.testUserRole));
    });

    test('should listen to auth state changes', () async {
      final authStateStream = authService.authStateChanges;

      expect(authStateStream, isA<Stream<AuthState>>());

      // Listen to auth state changes
      final subscription = authStateStream.listen((state) {
        expect(state, isNotNull);
      });

      // Sign in to trigger state change
      try {
        await authService.signIn(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
        );
      } catch (e) {
        // Create user if doesn't exist
        await authService.signUp(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
          fullName: TestConfig.testUserFullName,
          phone: TestConfig.testUserPhone,
          role: TestConfig.testUserRole,
        );
      }

      await Future.delayed(TestConfig.mediumDelay);
      await subscription.cancel();
    });
  });
}
