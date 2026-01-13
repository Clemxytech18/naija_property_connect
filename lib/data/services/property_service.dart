import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
import '../models/property_model.dart';

class PropertyService {
  final SupabaseClient _supabase = SupabaseService().client;

  Future<List<PropertyModel>> getProperties({
    String? type,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? ownerId,
    int? bedrooms,
    bool? hasParking,
    bool? hasVideo,
    String? searchQuery,
    String? status, // 'available', 'closed', 'all'
  }) async {
    var query = _supabase.from('properties').select('*');

    // Default status handling
    if (ownerId == null) {
      // For public feed, only show available properties by default
      if (status == null || status.isEmpty) {
        query = query.eq('status', 'available');
      } else if (status != 'all') {
        query = query.eq('status', status);
      }
    } else {
      // For agent view, allow filtering
      if (status != null &&
          status.isNotEmpty &&
          status.toLowerCase() != 'all') {
        query = query.eq('status', status.toLowerCase());
      }
    }

    // Smart Search Query Parser
    if (searchQuery != null && searchQuery.isNotEmpty) {
      String cleanQuery = searchQuery.toLowerCase();

      // Extract Bedrooms (e.g. "2 beds", "3 bedrooms")
      final bedRegex = RegExp(r'(\d+)\s*(?:beds?|bedrooms?|bds?)\b');
      final bedMatch = bedRegex.firstMatch(cleanQuery);
      if (bedMatch != null) {
        bedrooms = int.tryParse(bedMatch.group(1)!);
        cleanQuery = cleanQuery.replaceAll(bedRegex, '');
      }

      // Extract Bathrooms (e.g. "2 baths", "1 bathroom")
      final bathRegex = RegExp(r'(\d+)\s*(?:baths?|bathrooms?|bths?)\b');
      final bathMatch = bathRegex.firstMatch(cleanQuery);
      if (bathMatch != null) {
        int? baths = int.tryParse(bathMatch.group(1)!);
        if (baths != null) {
          query = query.eq('bathrooms', baths);
        }
        cleanQuery = cleanQuery.replaceAll(bathRegex, '');
      }

      // Attempt to extract Type if not explicitly set
      if (type == null || type == 'All') {
        if (cleanQuery.contains('apartment')) {
          type = 'apartment';
        } else if (cleanQuery.contains('house')) {
          type = 'house';
        } else if (cleanQuery.contains('land')) {
          type = 'land';
        } else if (cleanQuery.contains('office')) {
          type = 'office';
        }
      }

      // Cleaned text for general search
      cleanQuery = cleanQuery.trim();
      if (cleanQuery.isNotEmpty) {
        // Search title, location, description
        // For features (array), we can't easily ILIKE.
        // We stick to standard matches.
        query = query.or(
          'title.ilike.%$cleanQuery%,location.ilike.%$cleanQuery%,description.ilike.%$cleanQuery%',
        );
      }
    }

    if (type != null && type.isNotEmpty && type != 'All') {
      // Allow partial match for types in case of synonyms if strict match fails?
      // Strict for now as schema usually has fixed types.
      // But normalizing:
      query = query.ilike('type', '%$type%');
    }

    if (location != null && location.isNotEmpty) {
      query = query.ilike('location', '%$location%');
    }

    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }

    if (maxPrice != null && maxPrice > 0) {
      query = query.lte('price', maxPrice);
    }

    if (ownerId != null) {
      query = query.eq('owner_id', ownerId);
    }

    if (bedrooms != null) {
      query = query.eq('bedrooms', bedrooms);
    }

    if (hasParking == true) {
      query = query.gt('parking_spaces', 0);
    }

    if (hasVideo == true) {
      query = query.not('video', 'is', null).neq('video', '');
    }

    // Default sort by created_at desc
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<PropertyModel?> getPropertyById(String id) async {
    final data = await _supabase
        .from('properties')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return PropertyModel.fromJson(data);
  }

  // Helper to add property
  Future<void> addProperty(PropertyModel property) async {
    // We remove 'id' and 'created_at' to let Supabase generate them,
    // but PropertyModel requires them. So we pass them as dummy/null if needed or specific values.
    // Ideally, we create a CreatePropertyDto, but for speed, we convert and remove keys.
    final data = property.toJson();
    data.remove('id');
    data.remove('created_at');
    data.remove('status'); // Default to available on create
    data.remove('closed_reason');

    await _supabase.from('properties').insert(data);
  }

  Future<void> updateProperty(PropertyModel property) async {
    final data = property.toJson();
    data.remove('id');
    data.remove('created_at');
    data.remove('owner_id'); // Usually owner shouldn't change
    // We don't remove status here, allowing full update if needed via this method,
    // but typically updatePropertyStatus is preferred for status changes.

    await _supabase.from('properties').update(data).eq('id', property.id);
  }

  Future<void> updatePropertyStatus(
    String propertyId,
    String status,
    String? reason,
  ) async {
    // 1. Update the property
    await _supabase
        .from('properties')
        .update({'status': status, 'closed_reason': reason})
        .eq('id', propertyId);

    // 2. Handle Revenue Logic if applicable
    if (status == 'closed' &&
        reason == 'Property rented out or sold to a user on the app') {
      // Fetch property to get price details
      final propertyData = await _supabase
          .from('properties')
          .select()
          .eq('id', propertyId)
          .single();
      final property = PropertyModel.fromJson(propertyData);

      // Calculate total package
      // Note: Model logic for totalPackage is: price + agentFee + others
      final amount = property.totalPackage;

      if (amount > 0) {
        // Increment user revenue
        // We use an RPC call or direct update. Since we don't have an RPC for increment,
        // we fetch user, add, update. Potential race condition but acceptable for MVP.
        final userId = property.ownerId;
        final userData = await _supabase
            .from('users')
            .select('total_revenue')
            .eq('id', userId)
            .single();

        final currentRevenue = (userData['total_revenue'] as num? ?? 0)
            .toDouble();
        final newRevenue = currentRevenue + amount;

        await _supabase
            .from('users')
            .update({'total_revenue': newRevenue})
            .eq('id', userId);
      }
    }
  }

  /// Calculates the total revenue for an agent/landlord based on their closed properties
  /// where the reason is "Property rented out or sold to a user on the app".
  Future<double> calculateGeneratedRevenue(String ownerId) async {
    final data = await _supabase
        .from('properties')
        .select()
        .eq('owner_id', ownerId)
        .eq('status', 'closed')
        .eq(
          'closed_reason',
          'Property rented out or sold to a user on the app',
        );

    final properties = (data as List)
        .map((e) => PropertyModel.fromJson(e))
        .toList();

    double total = 0;
    for (var p in properties) {
      total += p.totalPackage;
    }

    return total;
  }

  Future<String> uploadMedia(List<int> bytes, String fileName) async {
    // Uploads to 'property_images' bucket
    final path = 'public/$fileName';
    await _supabase.storage
        .from('property_images')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );

    // Get Public URL
    return _supabase.storage.from('property_images').getPublicUrl(path);
  }
}
