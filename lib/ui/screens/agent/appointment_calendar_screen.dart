import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/services/auth_service.dart';

class AppointmentCalendarScreen extends StatefulWidget {
  const AppointmentCalendarScreen({super.key});

  @override
  State<AppointmentCalendarScreen> createState() =>
      _AppointmentCalendarScreenState();
}

class _AppointmentCalendarScreenState extends State<AppointmentCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final AuthService _authService = AuthService();

  Map<DateTime, List<Map<String, dynamic>>> _appointments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      // Fetch bookings for properties owned by this agent
      // Note: We need to use !inner join to filter on property owner
      final response = await Supabase.instance.client
          .from('bookings')
          .select('*, properties!inner(*), users!inner(*)')
          .eq('properties.owner_id', userId);

      final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

      for (final booking in response) {
        final dateStr = booking['date'] as String;
        final date = DateTime.parse(dateStr);
        final dateKey = DateTime(
          date.year,
          date.month,
          date.day,
        ); // Normalize to midnight

        if (grouped[dateKey] == null) grouped[dateKey] = [];
        grouped[dateKey]!.add(booking);
      }

      if (mounted) {
        setState(() {
          _appointments = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading agent appointments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${newStatus == 'CONFIRMED' ? 'Confirm' : 'Decline'} Appointment',
        ),
        content: Text(
          'Are you sure you want to ${newStatus == 'CONFIRMED' ? 'confirm' : 'decline'} this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'CONFIRMED'
                  ? Colors.green
                  : Colors.red,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);

      await _loadAppointments(); // Refresh

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Appointment $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _appointments[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Appointment Calendar'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (_selectedDay != null) ...[
                        _buildSectionHeader(
                          'Schedule',
                          DateFormat('EEEE, MMM d').format(_selectedDay!),
                        ),
                        ..._getEventsForDay(_selectedDay!).map((booking) {
                          final tenant =
                              booking['users'] as Map<String, dynamic>? ?? {};
                          final property =
                              booking['properties'] as Map<String, dynamic>? ??
                              {};
                          final status =
                              (booking['status'] as String? ?? 'Pending')
                                  .toUpperCase();

                          final Color statusColor;
                          if (status == 'CONFIRMED') {
                            statusColor = Colors.green;
                          } else if (status == 'CANCELLED') {
                            statusColor = Colors.red;
                          } else {
                            statusColor = Colors.orange;
                          }

                          return _buildAppointmentCard(
                            time: DateFormat(
                              'h:mm a',
                            ).format(DateTime.parse(booking['date'])),
                            status: status,
                            statusColor: statusColor,
                            title: 'Viewing Request',
                            tenantName: tenant['full_name'] ?? 'Unknown Tenant',
                            tenantImage:
                                tenant['avatar_url'] ??
                                'https://via.placeholder.com/150',
                            propertyTitle:
                                property['title'] ?? 'Unknown Property',
                            actions: status == 'PENDING'
                                ? [
                                    _buildActionButton(
                                      null,
                                      'Decline',
                                      Colors.grey[200]!,
                                      Colors.black87,
                                      () => _updateStatus(
                                        booking['id'],
                                        'CANCELLED',
                                      ),
                                    ),
                                    _buildActionButton(
                                      null,
                                      'Approve',
                                      Colors.orange,
                                      Colors.white,
                                      () => _updateStatus(
                                        booking['id'],
                                        'CONFIRMED',
                                      ),
                                    ),
                                  ]
                                : [],
                          );
                        }),
                        if (_getEventsForDay(_selectedDay!).isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No appointments for this day'),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String time,
    required String status,
    required Color statusColor,
    required String title,
    required String tenantName,
    required String tenantImage,
    required String propertyTitle,
    required List<Widget> actions,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
          top: BorderSide(color: Colors.grey[200]!),
          right: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.access_time, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(tenantImage),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child:
                      tenantImage.isEmpty || tenantImage.contains('placeholder')
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        propertyTitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(children: actions.map((e) => Expanded(child: e)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData? icon,
    String label,
    Color bgColor,
    Color fgColor,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
        label: Text(label),
      ),
    );
  }
}
