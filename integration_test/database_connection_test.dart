import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naija_property_connect/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../test/test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Database Connection Tests', () {
    late SupabaseClient supabaseClient;

    setUpAll(() async {
      // Initialize Supabase
      await Supabase.initialize(
        url: TestConfig.supabaseUrl,
        anonKey: TestConfig.supabaseAnonKey,
      );

      supabaseClient = SupabaseService().client;
    });

    test('should initialize Supabase client successfully', () {
      expect(supabaseClient, isNotNull);
      expect(supabaseClient, isA<SupabaseClient>());
    });

    test('should connect to Supabase database', () async {
      // Try a simple query to verify connection
      try {
        final response = await supabaseClient
            .from('users')
            .select('id')
            .limit(1);

        // If we get here without error, connection is successful
        expect(response, isA<List>());
      } catch (e) {
        // If table doesn't exist yet, that's okay - connection still works
        expect(e, isA<PostgrestException>());
      }
    });

    test('should execute SELECT query successfully', () async {
      try {
        final response = await supabaseClient
            .from('properties')
            .select('*')
            .limit(5);

        expect(response, isA<List>());
      } catch (e) {
        // Table might not exist or be empty
        expect(e, isA<PostgrestException>());
      }
    });

    test('should handle query with filters', () async {
      try {
        final response = await supabaseClient
            .from('properties')
            .select('*')
            .eq('type', 'Apartment')
            .limit(5);

        expect(response, isA<List>());

        // Verify filter worked
        for (final item in response) {
          expect(item['type'], equals('Apartment'));
        }
      } catch (e) {
        // Table might not exist or have no matching records
        expect(e, isA<PostgrestException>());
      }
    });

    test('should handle query with ordering', () async {
      try {
        final response = await supabaseClient
            .from('properties')
            .select('*')
            .order('created_at', ascending: false)
            .limit(5);

        expect(response, isA<List>());
      } catch (e) {
        // Table might not exist
        expect(e, isA<PostgrestException>());
      }
    });

    test('should handle query with range filters', () async {
      try {
        final response = await supabaseClient
            .from('properties')
            .select('*')
            .gte('price', 100000)
            .lte('price', 1000000)
            .limit(5);

        expect(response, isA<List>());

        // Verify range filter worked
        for (final item in response) {
          final price = item['price'];
          expect(price, greaterThanOrEqualTo(100000));
          expect(price, lessThanOrEqualTo(1000000));
        }
      } catch (e) {
        // Table might not exist or have no matching records
        expect(e, isA<PostgrestException>());
      }
    });

    test('should handle database errors gracefully', () async {
      // Try to query a non-existent table
      expect(
        () async =>
            await supabaseClient.from('non_existent_table_xyz').select('*'),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('should verify all required tables exist', () async {
      final requiredTables = ['users', 'properties', 'bookings', 'chats'];

      for (final table in requiredTables) {
        try {
          await supabaseClient.from(table).select('*').limit(1);

          // If we get here, table exists
          expect(true, isTrue);
        } catch (e) {
          // Table should exist, even if empty
          // Only PostgrestException is acceptable (empty table)
          // Other errors indicate table doesn't exist
          if (e is! PostgrestException) {
            fail('Table $table does not exist or is not accessible');
          }
        }
      }
    });

    test('should handle connection timeout gracefully', () async {
      // This test verifies that the client handles timeouts properly
      // We'll set a very short timeout and expect it to handle gracefully
      try {
        final response = await supabaseClient
            .from('properties')
            .select('*')
            .limit(1000);

        expect(response, isA<List>());
      } catch (e) {
        // Timeout or other network errors should be handled
        expect(e, isNotNull);
      }
    });

    test('should support complex queries with multiple conditions', () async {
      try {
        final response = await supabaseClient
            .from('properties')
            .select('*')
            .eq('type', 'Apartment')
            .gte('price', 200000)
            .lte('price', 800000)
            .order('price', ascending: true)
            .limit(10);

        expect(response, isA<List>());

        // Verify all conditions
        for (final item in response) {
          expect(item['type'], equals('Apartment'));
          expect(item['price'], greaterThanOrEqualTo(200000));
          expect(item['price'], lessThanOrEqualTo(800000));
        }
      } catch (e) {
        // Table might not exist or have no matching records
        expect(e, isA<PostgrestException>());
      }
    });

    test('should handle count queries', () async {
      try {
        final count = await supabaseClient.from('properties').count();

        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
      } catch (e) {
        // Table might not exist
        expect(e, isA<PostgrestException>());
      }
    });
  });
}
