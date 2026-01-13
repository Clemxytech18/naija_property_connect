# Integration Testing Guide

## Overview

This document provides comprehensive guidance for running integration tests for the Naija Property Connect Flutter application.

## Prerequisites

1. **Supabase Project**: You need a Supabase project with the following tables:
   - `users`
   - `properties`
   - `bookings`
   - `chats`

2. **Environment Configuration**: Update `test/test_config.dart` with your Supabase credentials:
   ```dart
   static const String supabaseUrl = 'https://your-project.supabase.co';
   static const String supabaseAnonKey = 'your-anon-key';
   ```

3. **Dependencies**: Ensure all dependencies are installed:
   ```bash
   flutter pub get
   ```

## Running Tests

### Run All Integration Tests

```bash
flutter test integration_test/
```

### Run Specific Test Suites

#### Authentication Tests
```bash
flutter test integration_test/auth_integration_test.dart
```

Tests covered:
- User sign up
- User sign in with valid credentials
- Sign in with invalid credentials
- Sign out functionality
- User profile retrieval
- Auth state changes

#### Property Listing Tests
```bash
flutter test integration_test/property_integration_test.dart
```

Tests covered:
- Fetch all properties
- Filter by type
- Filter by location
- Filter by price range
- Filter with multiple criteria
- Add new property
- Update existing property

#### Booking Tests
```bash
flutter test integration_test/booking_integration_test.dart
```

Tests covered:
- Check date availability
- Create booking
- Fetch bookings for property
- Prevent double booking
- Date availability after booking

#### Chat Tests
```bash
flutter test integration_test/chat_integration_test.dart
```

Tests covered:
- Send messages
- Receive messages
- Chronological message ordering
- Real-time message streaming
- Get chat partners list
- Bidirectional conversations

#### Database Connection Tests
```bash
flutter test integration_test/database_connection_test.dart
```

Tests covered:
- Supabase client initialization
- Database connectivity
- SELECT queries
- Queries with filters
- Queries with ordering
- Range filters
- Error handling
- Table existence verification
- Complex queries
- Count queries

#### Realtime Subscription Tests
```bash
flutter test integration_test/realtime_subscription_test.dart
```

Tests covered:
- Channel creation
- Subscribe to table changes
- INSERT event reception
- UPDATE event reception
- DELETE event reception
- Table data streaming
- Multiple subscriptions
- Subscription cleanup
- Reconnection handling

#### Responsive UI Tests
```bash
flutter test integration_test/responsive_ui_test.dart
```

Tests covered:
- Phone screen rendering
- Small phone screen
- Large phone screen
- Tablet screen rendering
- Large tablet screen
- Portrait orientation
- Landscape orientation
- Orientation changes
- Safe area handling
- Text readability
- Different pixel densities
- Overflow prevention
- Image aspect ratios
- Scrolling on small screens
- Layout adaptation

## Performance Testing

### Enable Performance Overlay

The app includes a built-in performance overlay toggle:

1. Run the app in debug mode:
   ```bash
   flutter run
   ```

2. Tap the floating speed icon button (bottom-right corner) to toggle the performance overlay

3. Navigate through the app and monitor:
   - Frame rate (should be 60fps or higher)
   - GPU/UI thread performance
   - Jank detection

### Using Performance Test Helper

```dart
import 'package:naija_property_connect/test/helpers/performance_test_helper.dart';

// Start tracking
PerformanceTestHelper().startFrameTracking();

// Perform operations...

// Stop tracking and get report
PerformanceTestHelper().stopFrameTracking();
PerformanceTestHelper().printPerformanceReport();

// Check if performance is good
final isGood = PerformanceTestHelper().isPerformanceGood();
```

## Testing on Devices

### Android

1. Connect Android device or start emulator
2. List devices:
   ```bash
   flutter devices
   ```
3. Run tests on specific device:
   ```bash
   flutter test integration_test/responsive_ui_test.dart -d <device-id>
   ```

### iOS

1. Connect iOS device or start simulator
2. List devices:
   ```bash
   flutter devices
   ```
3. Run tests on specific device:
   ```bash
   flutter test integration_test/responsive_ui_test.dart -d <device-id>
   ```

## Test Data Management

### Important Notes

- Integration tests create real data in your Supabase database
- Test users are created with emails from `test_config.dart`
- Tests include cleanup mechanisms in `tearDownAll` hooks
- Some test data may persist if tests fail

### Manual Cleanup

If needed, manually clean up test data:

```sql
-- Delete test users
DELETE FROM users WHERE email LIKE 'test.user%@example.com';

-- Delete test properties
DELETE FROM properties WHERE title LIKE '%Test Property%';

-- Delete test bookings
DELETE FROM bookings WHERE property_id IN (
  SELECT id FROM properties WHERE title LIKE '%Test Property%'
);

-- Delete test chats
DELETE FROM chats WHERE message LIKE '%test%';
```

## Troubleshooting

### Tests Failing Due to Missing Tables

Ensure your Supabase project has all required tables. Run the schema from `schema.sql`:

```bash
# Copy schema.sql content and run in Supabase SQL editor
```

### Authentication Errors

- Verify Supabase URL and anon key in `test_config.dart`
- Check that email confirmation is disabled in Supabase Auth settings
- Ensure Row Level Security (RLS) policies allow test operations

### Realtime Tests Timing Out

- Increase timeout values in `test_config.dart`
- Check Supabase Realtime is enabled for your tables
- Verify network connectivity

### Performance Overlay Not Showing

- Ensure you're running in debug mode (not release or profile)
- The overlay toggle only appears in debug builds
- Try restarting the app

## Continuous Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test integration_test/
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

## Best Practices

1. **Run tests in order**: Some tests may depend on data created by previous tests
2. **Use test Supabase project**: Don't run tests against production database
3. **Monitor test execution time**: Long-running tests may indicate performance issues
4. **Check test coverage**: Aim for comprehensive coverage of critical paths
5. **Update tests with code changes**: Keep tests in sync with application code

## Performance Benchmarks

Expected performance metrics:

- **Frame Rate**: ≥ 55 FPS
- **Dropped Frames**: < 10%
- **Average Frame Time**: ≤ 16.67ms (60 FPS)
- **Database Queries**: < 500ms for simple queries
- **Realtime Events**: < 2s latency

## Support

For issues or questions:
1. Check this documentation
2. Review test code for examples
3. Check Supabase documentation
4. Review Flutter testing documentation
