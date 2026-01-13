# Test Configuration

## Quick Start

Before running integration tests, you need to configure your Supabase credentials.

### 1. Update Test Configuration

Edit `test/test_config.dart` and replace the placeholder values:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

### 2. Set Up Test Database

Ensure your Supabase project has the required tables:
- `users`
- `properties`
- `bookings`
- `chats`

You can use the schema from `schema.sql` to set up your database.

### 3. Configure Supabase Settings

For testing to work properly:

1. **Disable Email Confirmation** (Auth Settings):
   - Go to Authentication → Settings
   - Disable "Enable email confirmations"
   
2. **Enable Realtime** (for realtime tests):
   - Go to Database → Replication
   - Enable replication for `properties`, `bookings`, and `chats` tables

3. **Configure RLS Policies** (if needed):
   - Ensure test users can read/write test data
   - Consider using a separate test project

### 4. Run Tests

```bash
# Make script executable (first time only)
chmod +x run_tests.sh

# Run all tests
./run_tests.sh all

# Or run specific test suite
./run_tests.sh auth
```

## Environment Variables (Optional)

You can also use environment variables instead of hardcoding credentials:

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"

flutter test integration_test/
```

Then update `test_config.dart` to use:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://your-project.supabase.co',
);
```

## Test Data

Tests will create the following test users:
- `test.user@example.com` (tenant)
- `test.user2@example.com` (landlord)

These users and their associated data will be created and cleaned up automatically during test execution.

## Troubleshooting

### "Table does not exist" errors
- Run the schema from `schema.sql` in your Supabase SQL editor

### "User already exists" errors
- This is normal and handled by the tests
- Tests will sign in with existing users

### Realtime tests timing out
- Ensure Realtime is enabled for your tables
- Check network connectivity
- Increase timeout values in `test_config.dart` if needed

## Next Steps

See [TESTING.md](../TESTING.md) for comprehensive testing documentation.
