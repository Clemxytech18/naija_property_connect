import 'package:flutter/material.dart';
import '../../../data/models/property_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/wishlist_service.dart';
import '../../widgets/property_card.dart';
import '../property_detail_screen.dart';

class TenantWishlistScreen extends StatefulWidget {
  const TenantWishlistScreen({super.key});

  @override
  State<TenantWishlistScreen> createState() => _TenantWishlistScreenState();
}

class _TenantWishlistScreenState extends State<TenantWishlistScreen> {
  final WishlistService _wishlistService = WishlistService();
  final AuthService _authService = AuthService();
  late Future<List<PropertyModel>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _refreshWishlist();
  }

  void _refreshWishlist() {
    // Falls back to demo tenant if no user logged in
    final user =
        _authService.currentUserId ?? 'c2c0d9f0-c855-4dcf-b3bf-80aa2422025d';
    setState(() {
      _wishlistFuture = _wishlistService.getWishlistProperties(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: FutureBuilder<List<PropertyModel>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final properties = snapshot.data ?? [];
          if (properties.isEmpty) {
            return const Center(child: Text('Your wishlist is empty.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return PropertyCard(
                property: property,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(property: property),
                    ),
                  );
                  _refreshWishlist(); // Refresh on return in case removed
                },
              );
            },
          );
        },
      ),
    );
  }
}
