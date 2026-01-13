import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/services/auth_service.dart';

class AgentAppointmentsScreen extends StatefulWidget {
  const AgentAppointmentsScreen({super.key});

  @override
  State<AgentAppointmentsScreen> createState() =>
      _AgentAppointmentsScreenState();
}

class _AgentAppointmentsScreenState extends State<AgentAppointmentsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _refreshBookings();
  }

  Future<void> _refreshBookings() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('bookings')
          .select('*, properties!inner(*), users!inner(*)')
          .eq('properties.owner_id', userId)
          .order('date', ascending: true);

      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Debug print to help identify issues if they persist
        debugPrint('Error loading agent appointments: $e');
      }
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${newStatus == 'confirmed' ? 'Accept' : 'Decline'} Request',
        ),
        content: Text(
          'Are you sure you want to ${newStatus == 'confirmed' ? 'accept' : 'decline'} this viewing request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'confirmed'
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
          .update({'status': newStatus.toUpperCase()})
          .eq('id', bookingId);

      await _refreshBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking ${newStatus == 'confirmed' ? 'accepted' : 'declined'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Pending'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBookingList(_filterBookings('upcoming'), 'Upcoming'),
                  _buildBookingList(_filterBookings('pending'), 'Pending'),
                  _buildBookingList(_filterBookings('past'), 'Past'),
                ],
              ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterBookings(String type) {
    final now = DateTime.now();
    return _bookings.where((b) {
      final status = (b['status'] as String? ?? 'pending').toLowerCase();
      final dateStr = b['date'] as String;
      final date = DateTime.parse(dateStr);

      if (type == 'upcoming') {
        return status == 'confirmed' && date.isAfter(now);
      } else if (type == 'pending') {
        return status == 'pending';
      } else {
        // past
        return date.isBefore(now) || status == 'cancelled';
      }
    }).toList();
  }

  Widget _buildBookingList(List<Map<String, dynamic>> bookings, String label) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No $label appointments',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final tenant = booking['users'] as Map<String, dynamic>? ?? {};
        final property = booking['properties'] as Map<String, dynamic>? ?? {};
        final status = (booking['status'] as String? ?? 'Pending');
        final date = DateTime.parse(booking['date']);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      backgroundImage: tenant['avatar_url'] != null
                          ? NetworkImage(tenant['avatar_url'])
                          : null,
                      child: tenant['avatar_url'] == null
                          ? Text(
                              (tenant['full_name'] as String? ?? 'T')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(color: Colors.blue[800]),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant['full_name'] ?? 'Tenant',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            property['title'] ?? 'Unknown Property',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEE, d MMM • h:mm a').format(date),
                      style: GoogleFonts.inter(color: Colors.grey[800]),
                    ),
                  ],
                ),
                // Actions (Accept/Decline) for Pending
                if (status.toLowerCase() == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _updateStatus(booking['id'], 'cancelled'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateStatus(booking['id'], 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'upcoming':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'past':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}

// Aborting this replace to first update BookingService to support fetching all bookings for a landlord.
