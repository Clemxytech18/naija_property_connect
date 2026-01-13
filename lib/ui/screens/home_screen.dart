import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/property_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/property_service.dart';
import '../../data/services/auth_service.dart';
import '../widgets/feed_property_card.dart';
import 'property_detail_screen.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:shimmer/shimmer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'shared/notifications_screen.dart';
import '../utils/map_marker_util.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PropertyService _propertyService = PropertyService();
  late Future<List<PropertyModel>> _propertiesFuture;

  // Filters
  final String _selectedType = 'All';
  final RangeValues _priceRange = const RangeValues(0, 100000000);
  int? _selectedBedrooms;
  bool _showVideoOnly = false;
  bool _showParkingOnly = false;
  bool _isMapView = false;

  Map<String, BitmapDescriptor> _customMarkers = {};

  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _propertiesFuture = _propertyService.getProperties();
    _loadCustomMarkers();
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
      setState(() {
        _customMarkers = {
          'house': houseMarker,
          'apartment': houseMarker,
          'land': landMarker,
          'office': officeMarker,
          'other': defaultMarker,
        };
      });
    }
  }

  Future<void> _refreshProperties() async {
    setState(() {
      _propertiesFuture = _propertyService.getProperties(
        type: _selectedType == 'All' ? null : _selectedType,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end == 100000000 ? null : _priceRange.end,
        bedrooms: _selectedBedrooms,
        hasParking: _showParkingOnly ? true : null,
        hasVideo: _showVideoOnly ? true : null,
        searchQuery: _searchQuery,
      );
    });
  }

  void _toggleBedroomFilter(int bedrooms) {
    if (_selectedBedrooms == bedrooms) {
      _selectedBedrooms = null;
    } else {
      _selectedBedrooms = bedrooms;
    }
    _refreshProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isMapView = !_isMapView;
          });
        },
        icon: Icon(_isMapView ? Icons.list : Icons.map),
        label: Text(_isMapView ? 'List View' : 'Map View'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your location',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        FutureBuilder<UserModel?>(
                          future: AuthService().getUserProfile(),
                          builder: (context, snapshot) {
                            final city = snapshot.data?.city;
                            final state = snapshot.data?.state;
                            String location = 'Select Location';
                            if (city != null && state != null) {
                              location = '$city, $state';
                            } else if (state != null) {
                              location = state;
                            }
                            return Text(
                              location,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            );
                          },
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                      color: Colors.grey[700],
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by area, landmark, or estate...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  setState(() {
                    _searchQuery = val;
                  });
                  _refreshProperties();
                });
              },
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterButton(
                  context,
                  label: 'Filters',
                  icon: Icons.tune,
                  isPrimary:
                      true, // Always highlighted as the main filter button
                  onTap: () {
                    // Show full filter modal
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  context,
                  label: '1 Bedroom',
                  isPrimary: _selectedBedrooms == 1,
                  onTap: () => _toggleBedroomFilter(1),
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  context,
                  label: '2 Bedrooms',
                  isPrimary: _selectedBedrooms == 2,
                  onTap: () => _toggleBedroomFilter(2),
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  context,
                  label: 'Parking',
                  icon: Icons.local_parking,
                  isPrimary: _showParkingOnly,
                  onTap: () {
                    setState(() {
                      _showParkingOnly = !_showParkingOnly;
                    });
                    _refreshProperties();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  context,
                  label: 'Video Tours',
                  icon: Icons.videocam_outlined,
                  isPrimary: _showVideoOnly,
                  onTap: () {
                    setState(() {
                      _showVideoOnly = !_showVideoOnly;
                    });
                    _refreshProperties();
                  },
                ),
              ],
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Text(
                //   'See all',
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: Theme.of(context).primaryColor,
                //   ),
                // ),
              ],
            ),
          ),

          // Feed
          Expanded(
            child: _isMapView
                ? _buildMapView()
                : FutureBuilder<List<PropertyModel>>(
                    future: _propertiesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerLoading();
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.wifi_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Connection Error',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please check your internet connection.',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshProperties,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final properties = snapshot.data!;

                      if (properties.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animations/empty.json',
                                height: 200,
                              ),
                              const Text('No properties found'),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: properties.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final property = properties[index];
                          return FeedPropertyCard(
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
                            onFavorite: () {
                              // Toggle favorite logic
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return FutureBuilder<List<PropertyModel>>(
      future: _propertiesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final properties = snapshot.data!;
        final markers = properties
            .where((p) => p.latitude != null && p.longitude != null)
            .map((p) {
              final typeKey = p.type?.toLowerCase() ?? 'other';
              final icon = _customMarkers[typeKey] ?? _customMarkers['other'];

              return Marker(
                markerId: MarkerId(p.id),
                position: LatLng(p.latitude!, p.longitude!),
                icon: icon ?? BitmapDescriptor.defaultMarker,
                infoWindow: InfoWindow(
                  title: p.title,
                  snippet: '₦${p.price?.toStringAsFixed(0)}',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailScreen(property: p),
                      ),
                    );
                  },
                ),
              );
            })
            .toSet();

        return GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(6.5244, 3.3792), // Default Lagos
            zoom: 12,
          ),
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        );
      },
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required String label,
    IconData? icon,
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isPrimary ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
