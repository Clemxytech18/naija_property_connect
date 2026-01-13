/// Test configuration for integration tests
///
/// This file contains test environment configuration including
/// Supabase credentials and test data constants.
library;

class TestConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://maplrpeqvzhjahwuowwk.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hcGxycGVxdnpoamFod3Vvd3drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODQ3NDQsImV4cCI6MjA4MTA2MDc0NH0.pZxNqBFd85s7hDrihvFGgH7zvBeSuiKv_eAfdDKR4fA',
  );

  // Test User Credentials
  static const String testUserEmail = 'test.user@example.com';
  static const String testUserPassword = 'TestPassword123!';
  static const String testUserFullName = 'Test User';
  static const String testUserPhone = '+2348012345678';
  static const String testUserRole = 'tenant';

  // Test User 2 (for chat testing)
  static const String testUser2Email = 'test.user2@example.com';
  static const String testUser2Password = 'TestPassword123!';
  static const String testUser2FullName = 'Test User 2';
  static const String testUser2Role = 'landlord';

  // Test Property Data
  static const String testPropertyTitle = 'Test Property';
  static const String testPropertyDescription = 'A beautiful test property';
  static const String testPropertyType = 'Apartment';
  static const String testPropertyLocation = 'Lagos, Nigeria';
  static const double testPropertyPrice = 500000.0;
  static const int testPropertyBedrooms = 3;
  static const int testPropertyBathrooms = 2;

  // Test Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration realtimeTimeout = Duration(seconds: 10);

  // Test Delays
  static const Duration shortDelay = Duration(milliseconds: 500);
  static const Duration mediumDelay = Duration(seconds: 2);
  static const Duration longDelay = Duration(seconds: 5);
}
