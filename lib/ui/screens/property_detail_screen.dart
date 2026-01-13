import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../data/models/property_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/wishlist_service.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final AuthService _authService = AuthService();
  final WishlistService _wishlistService = WishlistService();

  bool _isLiked = false;
  bool _showVideo = false;
  // Media
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  late LatLng _center;
  final Set<Marker> _markers = {};
  UserModel? _owner;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
    _fetchOwner();
    _center = LatLng(
      widget.property.latitude ?? 6.5244,
      widget.property.longitude ?? 3.3792,
    );
    _markers.add(
      Marker(
        markerId: MarkerId(widget.property.id),
        position: _center,
        infoWindow: InfoWindow(title: widget.property.title),
      ),
    );
    _setupMedia();
  }

  Future<void> _fetchOwner() async {
    final owner = await _authService.getUserById(widget.property.ownerId);
    if (mounted) {
      setState(() => _owner = owner);
    }
  }

  Future<void> _checkWishlistStatus() async {
    // Check real user first, else fallback to demo tenant
    final user =
        _authService.currentUserId ?? 'c2c0d9f0-c855-4dcf-b3bf-80aa2422025d';
    try {
      final inWishlist = await _wishlistService.isInWishlist(
        user,
        widget.property.id,
      );
      if (mounted) setState(() => _isLiked = inWishlist);
    } catch (_) {
      // Ignore if table still issues or net error
    }
  }

  Future<void> _toggleWishlist() async {
    // Check real user first, else fallback to demo tenant
    final user =
        _authService.currentUserId ?? 'c2c0d9f0-c855-4dcf-b3bf-80aa2422025d';

    setState(() => _isLiked = !_isLiked);
    try {
      if (_isLiked) {
        await _wishlistService.addToWishlist(user, widget.property.id);
      } else {
        await _wishlistService.removeFromWishlist(user, widget.property.id);
      }
    } catch (e) {
      if (mounted) setState(() => _isLiked = !_isLiked);
      _showSnack('Failed to update wishlist: $e');
    }
  }

  Future<void> _setupMedia() async {
    if (widget.property.video != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.property.video!),
      );
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
      );
      if (mounted) setState(() {});
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showBookingModal() async {
    final user = _authService.currentUserId;
    if (user == null) {
      _showSnack('Please login to book');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(property: widget.property),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: const BackButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.black12),
              ),
              color: Colors.white,
            ),
            actions: [
              IconButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.black12),
                ),
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                ),
                onPressed: _toggleWishlist,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_showVideo && _chewieController != null)
                    Chewie(controller: _chewieController!)
                  else
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 350,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: widget.property.images.length > 1,
                      ),
                      items: widget.property.images.isNotEmpty
                          ? widget.property.images
                                .map(
                                  (url) =>
                                      Image.network(url, fit: BoxFit.cover),
                                )
                                .toList()
                          : [
                              Container(
                                color: Colors.grey,
                                child: const Icon(Icons.image, size: 50),
                              ),
                            ],
                    ),
                  if (widget.property.video != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showVideo = !_showVideo;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showVideo
                                    ? Icons.image
                                    : Icons.play_circle_fill,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showVideo ? 'Photos' : 'Video Tour',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.property.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.property.location ?? 'Lagos',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₦${(widget.property.price ?? 0).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Text(
                            '/year',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Total Package Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Package',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${widget.property.totalPackage.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const Text(
                          'Includes all fees + 1st year rent',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Agent Profile
                  _buildAgentProfile(context),
                  const Divider(height: 32),

                  // Specs Grid
                  _buildSpecsGrid(context),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property.description ?? 'No description.',
                    style: const TextStyle(color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Amenities
                  if (widget.property.features.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.property.features
                              .map(
                                (f) => Chip(
                                  label: Text(f),
                                  backgroundColor: Colors.grey[100],
                                  side: BorderSide.none,
                                  avatar: Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Fees if any
                  if (widget.property.agentFee != null) ...[
                    const Text(
                      'Fees',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeeRow('Agent Fee', widget.property.agentFee),
                    _buildFeeRow('Legal Fee', widget.property.legalFee),
                    _buildFeeRow('Agreement Fee', widget.property.agreementFee),
                    _buildFeeRow('Caution Fee', widget.property.cautionFee),
                    _buildFeeRow('Service Charge', widget.property.serviceFee),
                    const SizedBox(height: 24),
                  ],

                  // Map
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _center,
                          zoom: 13,
                        ),
                        markers: _markers,
                        zoomControlsEnabled: false,
                        onMapCreated: (GoogleMapController controller) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Chat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUserId: widget.property.ownerId,
                          otherUserName: _owner?.fullName,
                          propertyContext: widget.property,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _showBookingModal,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Book Viewing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentProfile(BuildContext context) {
    final agentName = _owner?.fullName ?? 'Property Owner';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          child: Text(agentName.isNotEmpty ? agentName[0].toUpperCase() : '?'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agentName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: 14,
                    color: Theme.of(context).colorScheme.tertiary,
                  ), // Accent color
                  const SizedBox(width: 4),
                  Text(
                    'Verified Partner',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSpecItem(
            Icons.bed_outlined,
            '${widget.property.bedrooms ?? 0} Bed',
          ),
          _buildSpecItem(
            Icons.bathtub_outlined,
            '${widget.property.bathrooms ?? 0} Bath',
          ),
          _buildSpecItem(
            Icons.square_foot,
            '${widget.property.sqft ?? 0} sqft',
          ),
          _buildSpecItem(
            Icons.local_parking,
            '${widget.property.parkingSpaces ?? 0} Parking',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, double? amount) {
    if (amount == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            '₦${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
