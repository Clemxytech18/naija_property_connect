import 'package:flutter/material.dart';

class LandlordBookingsScreen extends StatelessWidget {
  const LandlordBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: const Center(child: Text('Incoming Booking Requests')),
    );
  }
}
