import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/property_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/services/booking_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';

class BookingScreen extends StatefulWidget {
  final PropertyModel property;

  const BookingScreen({super.key, required this.property});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Set<DateTime> _bookedDates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final bookings = await _bookingService.getBookingsForProperty(
        widget.property.id,
      );
      if (mounted) {
        setState(() {
          _bookedDates = bookings
              .map((b) => DateTime(b.date.year, b.date.month, b.date.day))
              .toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading availability: $e')),
        );
      }
    }
  }

  bool _isDayBooked(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _bookedDates.contains(normalizedDay);
  }

  Future<void> _confirmBooking() async {
    if (_selectedDay == null) return;

    final user = _authService.currentUserId;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to book')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final booking = BookingModel(
        id: '',
        propertyId: widget.property.id,
        userId: user,
        date: _selectedDay!,
        status: 'pending',
      );

      await _bookingService.createBooking(booking);

      await NotificationService().showLocalNotification(
        title: 'Booking Request Sent',
        body:
            'Your booking for ${_selectedDay.toString().split(' ')[0]} is pending confirmed.',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking confirmed!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Date')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  enabledDayPredicate: (day) =>
                      !_isDayBooked(day), // Disable booked days in UI
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay) &&
                        !_isDayBooked(selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() => _calendarFormat = format);
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    disabledTextStyle: TextStyle(color: Colors.red),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedDay != null && !_isLoading
                          ? _confirmBooking
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _selectedDay == null
                            ? 'Select a Date'
                            : 'Confirm Booking for ${_selectedDay!.toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
