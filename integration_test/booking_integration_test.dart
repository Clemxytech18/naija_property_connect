import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naija_property_connect/data/models/booking_model.dart';
import 'package:naija_property_connect/data/models/property_model.dart';
import 'package:naija_property_connect/data/services/auth_service.dart';
import 'package:naija_property_connect/data/services/booking_service.dart';
import 'package:naija_property_connect/data/services/property_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../test/test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking Integration Tests', () {
    late BookingService bookingService;
    late PropertyService propertyService;
    late AuthService authService;
    String? testPropertyId;
    String? testBookingId;

    setUpAll(() async {
      // Initialize Supabase
      await Supabase.initialize(
        url: TestConfig.supabaseUrl,
        anonKey: TestConfig.supabaseAnonKey,
      );

      bookingService = BookingService();
      propertyService = PropertyService();
      authService = AuthService();

      // Sign in as tenant
      try {
        await authService.signIn(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
        );
      } catch (e) {
        // Create tenant user if doesn't exist
        await authService.signUp(
          email: TestConfig.testUserEmail,
          password: TestConfig.testUserPassword,
          fullName: TestConfig.testUserFullName,
          phone: TestConfig.testUserPhone,
          role: TestConfig.testUserRole,
        );
      }

      await Future.delayed(TestConfig.mediumDelay);

      // Create a test property for booking
      final userId = authService.currentUserId;
      if (userId != null) {
        final testProperty = PropertyModel(
          id: '',
          title: 'Booking Test Property',
          description: 'Property for booking tests',
          type: 'Apartment',
          location: 'Lagos',
          price: 500000.0,
          images: [],
          features: ['2 bedrooms', '1 bathroom'],
          ownerId: userId,
          createdAt: DateTime.now(),
        );

        await propertyService.addProperty(testProperty);
        await Future.delayed(TestConfig.mediumDelay);

        // Get the created property ID
        final properties = await propertyService.getProperties();
        final createdProperty = properties.firstWhere(
          (p) => p.title == 'Booking Test Property',
        );
        testPropertyId = createdProperty.id;
      }
    });

    tearDownAll(() async {
      // Clean up: delete test booking and property
      final supabase = Supabase.instance.client;

      if (testBookingId != null) {
        try {
          await supabase.from('bookings').delete().eq('id', testBookingId!);
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      if (testPropertyId != null) {
        try {
          await supabase.from('properties').delete().eq('id', testPropertyId!);
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      await authService.signOut();
    });

    test('should check if date is available', () async {
      expect(testPropertyId, isNotNull);

      final futureDate = DateTime.now().add(const Duration(days: 7));
      final isAvailable = await bookingService.isDateAvailable(
        testPropertyId!,
        futureDate,
      );

      expect(isAvailable, isA<bool>());
      // Should be true since no bookings exist yet
      expect(isAvailable, isTrue);
    });

    test('should create a booking successfully', () async {
      expect(testPropertyId, isNotNull);
      final userId = authService.currentUserId;
      expect(userId, isNotNull);

      final bookingDate = DateTime.now().add(const Duration(days: 10));

      final newBooking = BookingModel(
        id: '',
        propertyId: testPropertyId!,
        userId: userId!,
        date: bookingDate,
        status: 'pending',
      );

      await bookingService.createBooking(newBooking);

      // Wait for database to process
      await Future.delayed(TestConfig.mediumDelay);

      // Verify booking was created
      final bookings = await bookingService.getBookingsForProperty(
        testPropertyId!,
      );
      expect(bookings, isNotEmpty);

      final createdBooking = bookings.firstWhere(
        (b) => b.userId == userId,
        orElse: () => throw Exception('Booking not found'),
      );

      expect(createdBooking.propertyId, equals(testPropertyId));
      expect(createdBooking.userId, equals(userId));
      expect(createdBooking.status, equals('pending'));

      // Save ID for cleanup
      testBookingId = createdBooking.id;
    });

    test('should fetch bookings for a property', () async {
      expect(testPropertyId, isNotNull);

      final bookings = await bookingService.getBookingsForProperty(
        testPropertyId!,
      );

      expect(bookings, isA<List<BookingModel>>());

      // Verify all bookings are for the correct property
      for (final booking in bookings) {
        expect(booking.propertyId, equals(testPropertyId));
      }
    });

    test('should prevent double booking on same date', () async {
      expect(testPropertyId, isNotNull);
      final userId = authService.currentUserId;
      expect(userId, isNotNull);

      final bookingDate = DateTime.now().add(const Duration(days: 15));

      // Create first booking
      final firstBooking = BookingModel(
        id: '',
        propertyId: testPropertyId!,
        userId: userId!,
        date: bookingDate,
        status: 'pending',
      );

      await bookingService.createBooking(firstBooking);
      await Future.delayed(TestConfig.mediumDelay);

      // Try to create second booking on same date
      final secondBooking = BookingModel(
        id: '',
        propertyId: testPropertyId!,
        userId: userId,
        date: bookingDate,
        status: 'pending',
      );

      expect(
        () async => await bookingService.createBooking(secondBooking),
        throwsA(isA<Exception>()),
      );

      // Cleanup the first booking
      final supabase = Supabase.instance.client;
      final bookings = await bookingService.getBookingsForProperty(
        testPropertyId!,
      );
      for (final booking in bookings) {
        if (booking.date.year == bookingDate.year &&
            booking.date.month == bookingDate.month &&
            booking.date.day == bookingDate.day) {
          await supabase.from('bookings').delete().eq('id', booking.id);
        }
      }
    });

    test('should show date as unavailable after booking', () async {
      expect(testPropertyId, isNotNull);
      final userId = authService.currentUserId;
      expect(userId, isNotNull);

      final bookingDate = DateTime.now().add(const Duration(days: 20));

      // Check availability before booking
      final beforeBooking = await bookingService.isDateAvailable(
        testPropertyId!,
        bookingDate,
      );
      expect(beforeBooking, isTrue);

      // Create booking
      final newBooking = BookingModel(
        id: '',
        propertyId: testPropertyId!,
        userId: userId!,
        date: bookingDate,
        status: 'pending',
      );

      await bookingService.createBooking(newBooking);
      await Future.delayed(TestConfig.mediumDelay);

      // Check availability after booking
      final afterBooking = await bookingService.isDateAvailable(
        testPropertyId!,
        bookingDate,
      );
      expect(afterBooking, isFalse);

      // Cleanup
      final supabase = Supabase.instance.client;
      final bookings = await bookingService.getBookingsForProperty(
        testPropertyId!,
      );
      for (final booking in bookings) {
        if (booking.date.year == bookingDate.year &&
            booking.date.month == bookingDate.month &&
            booking.date.day == bookingDate.day) {
          await supabase.from('bookings').delete().eq('id', booking.id);
        }
      }
    });
  });
}
