import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/property_model.dart';
import '../../../data/services/property_service.dart';
import '../../widgets/map_property_card.dart';
import '../property_detail_screen.dart';
import '../../utils/map_marker_util.dart';

class TenantSearchScreen extends StatefulWidget {
  const TenantSearchScreen({super.key});

  @override
  State<TenantSearchScreen> createState() => _TenantSearchScreenState();
}

class _TenantSearchScreenState extends State<TenantSearchScreen> {
  final PropertyService _propertyService = PropertyService();

  final Set<Marker> _markers = {};
  List<PropertyModel> _properties = [];
  bool _isLoading = true;

  Map<String, BitmapDescriptor> _customMarkers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.5244, 3.3792), // Lagos
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      // Load markers first or in parallel
      await _loadCustomMarkers();

      final properties = await _propertyService.getProperties();
      _properties = properties;
      _createMarkers();
    } catch (e) {
      debugPrint('Error loading properties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomMarkers() async {
    final houseMarker = await MapMarkerUtil.createCustomMarkerBitmap(
      MapMarkerUtil.getIconForType('house'),
      color: MapMarkerUtil.getColorForType('house'),
    );
    final landMarker = await MapMarkerUtil.createCustomMarkerBitmap(
      MapMarkerUtil.getIconForType('land'),
      color: MapMarkerUtil.getColorForType('land'),
    );
    final officeMarker = await MapMarkerUtil.createCustomMarkerBitmap(
      MapMarkerUtil.getIconForType('office'),
      color: MapMarkerUtil.getColorForType('office'),
    );
    final defaultMarker = await MapMarkerUtil.createCustomMarkerBitmap(
      MapMarkerUtil.getIconForType('other'),
      color: MapMarkerUtil.getColorForType('other'),
    );

    if (mounted) {
      _customMarkers = {
        'house': houseMarker,
        'apartment': houseMarker,
        'land': landMarker,
        'office': officeMarker,
        'other': defaultMarker,
      };
    }
  }

  void _createMarkers() {
    _markers.clear();
    for (final property in _properties) {
      // Use fake coords if not present. Real app would geocode 'location'
      final lat =
          property.latitude ?? (6.45 + (property.hashCode % 100) * 0.001);
      final lng =
          property.longitude ?? (3.35 + (property.hashCode % 100) * 0.002);

      final typeKey = property.type?.toLowerCase() ?? 'other';
      final icon = _customMarkers[typeKey] ?? _customMarkers['other'];

      _markers.add(
        Marker(
          markerId: MarkerId(property.id),
          position: LatLng(lat, lng),
          icon: icon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: property.title),
          onTap: () {
            // Scroll carousel to this item?
          },
        ),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Top Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search location...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune), // Filter icon
                      onPressed: () {
                        // Show filter modal
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Property Carousel
          Positioned(
            bottom: 30, // Above bottom nav
            left: 0,
            right: 0,
            child: SizedBox(
              height: 120,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _properties.length,
                      itemBuilder: (context, index) {
                        final property = _properties[index];
                        return MapPropertyCard(
                          property: property,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PropertyDetailScreen(property: property),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140),
        child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          onPressed: () {
            // Locate me or reset view
          },
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}
