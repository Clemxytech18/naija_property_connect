import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/property_model.dart';
import 'supabase_service.dart';

class WishlistService {
  final SupabaseClient _supabase = SupabaseService().client;

  Future<void> addToWishlist(String userId, String propertyId) async {
    await _supabase.from('wishlists').insert({
      'user_id': userId,
      'property_id': propertyId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFromWishlist(String userId, String propertyId) async {
    await _supabase
        .from('wishlists')
        .delete()
        .eq('user_id', userId)
        .eq('property_id', propertyId);
  }

  Future<bool> isInWishlist(String userId, String propertyId) async {
    final data = await _supabase
        .from('wishlists')
        .select()
        .eq('user_id', userId)
        .eq('property_id', propertyId)
        .maybeSingle();
    return data != null;
  }

  Future<List<PropertyModel>> getWishlistProperties(String userId) async {
    // Fetch wishlist items with property details
    final data = await _supabase
        .from('wishlists')
        .select('*, properties(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    List<PropertyModel> properties = [];
    for (var item in data) {
      if (item['properties'] != null) {
        properties.add(PropertyModel.fromJson(item['properties']));
      }
    }
    return properties;
  }
}
