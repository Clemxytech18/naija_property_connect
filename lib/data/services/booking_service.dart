import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

class BookingService {
  final SupabaseClient _supabase = SupabaseService().client;

  // Get bookings for properties owned by the current user (Agent/Landlord view)
  Future<List<BookingModel>> getAgentBookings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // 1. Get properties owned by agent
      final propertiesData = await _supabase
          .from('properties')
          .select('id')
          .eq('owner_id', user.id);

      final propertyIds = (propertiesData as List)
          .map((e) => e['id'] as String)
          .toList();

      if (propertyIds.isEmpty) return [];

      // 2. Get bookings for these properties
      final data = await _supabase
          .from('bookings')
          .select('*, properties(*), users(*)')
          .filter('property_id', 'in', propertyIds)
          .order('date', ascending: true);

      return (data as List).map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      // Fallback or log error
      debugPrint('Error fetching agent bookings: $e');
      return [];
    }
  }

  // Get bookings made by the current user (Tenant view)
  Future<List<BookingModel>> getTenantBookings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final data = await _supabase
        .from('bookings')
        .select('*, properties(*)') // Join properties to show what was booked
        .eq('user_id', user.id)
        .order('date', ascending: true);

    return (data as List).map((e) => BookingModel.fromJson(e)).toList();
  }

  // Create a new booking
  Future<void> createBooking(BookingModel booking) async {
    // 1. Insert Booking
    final data = await _supabase
        .from('bookings')
        .insert({
          'property_id': booking.propertyId,
          'user_id': booking.userId,
          'date': booking.date.toIso8601String(),
          'status': 'pending',
        })
        .select()
        .single();

    // 2. Fetch Property Owner to notify them
    final property = await _supabase
        .from('properties')
        .select('owner_id, title')
        .eq('id', booking.propertyId)
        .single();

    final ownerId = property['owner_id'];
    final propertyTitle = property['title'];

    // 3. Notify Agent/Landlord
    if (ownerId != null) {
      await NotificationService().createNotification(
        userId: ownerId,
        title: 'New Booking Request',
        body:
            'You have a new booking request for $propertyTitle on ${booking.date.toString().split(' ')[0]}.',
        category: 'bookings',
        relatedEntityId: data['id'],
      );
    }
  }

  // Update Booking Status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    // 1. Update status
    final data = await _supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId)
        .select('*, properties(title)')
        .single();

    // 2. Notify Tenant
    final tenantId = data['user_id'];
    final propertyTitle = data['properties']['title'];

    await NotificationService().createNotification(
      userId: tenantId,
      title: 'Booking Status Update',
      body: 'Your booking for $propertyTitle has been $status.',
      category: 'bookings',
      relatedEntityId: bookingId,
    );
  }

  // Cancel Booking (by Tenant)
  Future<void> cancelBooking(String bookingId) async {
    // 1. Get booking details before deleting/cancelling
    final bookingData = await _supabase
        .from('bookings')
        .select('*, properties(owner_id, title)')
        .eq('id', bookingId)
        .single();

    // 2. Update status to cancelled (Soft delete preference over hard delete for records)
    await _supabase
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);

    // 3. Notify Agent/Landlord
    final ownerId = bookingData['properties']['owner_id'];
    final propertyTitle = bookingData['properties']['title'];
    final date = DateTime.parse(bookingData['date']);

    if (ownerId != null) {
      await NotificationService().createNotification(
        userId: ownerId,
        title: 'Booking Cancelled',
        body:
            'The booking for $propertyTitle on ${date.toString().split(' ')[0]} was cancelled by the tenant.',
        category: 'bookings',
        relatedEntityId: bookingId,
      );
    }
  }

  // Check if a date is available for a property
  Future<bool> isDateAvailable(String propertyId, DateTime date) async {
    // Just a basic check for MVP - real logic might check time slots
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final count = await _supabase
        .from('bookings')
        .count()
        .eq('property_id', propertyId)
        .gte('date', startOfDay.toIso8601String())
        .lt('date', endOfDay.toIso8601String());

    return count == 0;
  }

  // Get bookings for a specific property
  Future<List<BookingModel>> getBookingsForProperty(String propertyId) async {
    final data = await _supabase
        .from('bookings')
        .select('*, users(*)')
        .eq('property_id', propertyId)
        .order('date', ascending: true);

    return (data as List).map((e) => BookingModel.fromJson(e)).toList();
  }
}
