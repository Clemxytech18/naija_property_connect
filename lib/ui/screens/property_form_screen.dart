import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/property_model.dart';
import 'shared/location_picker_screen.dart';
import '../../data/services/property_service.dart';
import '../../data/services/auth_service.dart';

class PropertyFormScreen extends StatefulWidget {
  final PropertyModel? property; // If editing

  const PropertyFormScreen({super.key, this.property});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _featuresController = TextEditingController();

  // New Controllers
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _sqftController = TextEditingController();
  final _parkingController = TextEditingController();

  final _agentFeeController = TextEditingController();
  final _legalFeeController = TextEditingController();
  final _agreementFeeController = TextEditingController();
  final _cautionFeeController = TextEditingController();
  final _serviceFeeController = TextEditingController();

  String _selectedType = 'Apartment';
  final List<String> _types = ['Apartment', 'House', 'Land', 'Office'];

  final List<XFile> _newImages = [];
  List<String> _existingImages = [];
  XFile? _newVideo;
  String? _existingVideo;
  bool _isLoading = false;

  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _titleController.text = widget.property!.title;
      _descriptionController.text = widget.property!.description ?? '';
      _priceController.text = widget.property!.price?.toString() ?? '';
      _locationController.text = widget.property!.location ?? '';
      _featuresController.text = widget.property!.features.join(', ');
      _selectedType = widget.property!.type ?? 'Apartment';
      _existingImages = List.from(widget.property!.images);
      _existingVideo = widget.property!.video;

      _bedroomsController.text = widget.property!.bedrooms?.toString() ?? '';
      _bathroomsController.text = widget.property!.bathrooms?.toString() ?? '';
      _sqftController.text = widget.property!.sqft?.toString() ?? '';
      _parkingController.text =
          widget.property!.parkingSpaces?.toString() ?? '';

      _agentFeeController.text = widget.property!.agentFee?.toString() ?? '';
      _legalFeeController.text = widget.property!.legalFee?.toString() ?? '';
      _agreementFeeController.text =
          widget.property!.agreementFee?.toString() ?? '';
      _cautionFeeController.text =
          widget.property!.cautionFee?.toString() ?? '';
      _serviceFeeController.text =
          widget.property!.serviceFee?.toString() ?? '';

      if (widget.property!.latitude != null &&
          widget.property!.longitude != null) {
        _selectedLocation = LatLng(
          widget.property!.latitude!,
          widget.property!.longitude!,
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _newVideo = video;
      });
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation: 2 Images, 1 Video
    final totalImages = _existingImages.length + _newImages.length;
    if (totalImages < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 images')),
      );
      return;
    }

    if (_newVideo == null && _existingVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a property video')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUserId;
      if (user == null) throw Exception('User not logged in');

      // 1. Upload new images
      List<String> uploadedUrls = [];
      for (var img in _newImages) {
        final bytes = await img.readAsBytes();
        final name = '${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final url = await _propertyService.uploadMedia(bytes, name);
        uploadedUrls.add(url);
      }

      // 2. Upload video if new
      String? videoUrl = _existingVideo;
      if (_newVideo != null) {
        final bytes = await _newVideo!.readAsBytes();
        final name =
            'vid_${DateTime.now().millisecondsSinceEpoch}_${_newVideo!.name}';
        videoUrl = await _propertyService.uploadMedia(bytes, name);
      }

      final allMedia = [..._existingImages, ...uploadedUrls];
      final features = _featuresController.text
          .split(',')
          .map((e) => e.trim())
          .toList();

      if (widget.property == null) {
        // Create
        final newProp = PropertyModel(
          id: '', // Supabase generates
          ownerId: user,
          title: _titleController.text,
          description: _descriptionController.text,
          type: _selectedType,
          location: _locationController.text,
          price: double.tryParse(_priceController.text),
          images: allMedia,
          video: videoUrl,
          features: features,
          bedrooms: int.tryParse(_bedroomsController.text),
          bathrooms: int.tryParse(_bathroomsController.text),
          sqft: double.tryParse(_sqftController.text),
          parkingSpaces: int.tryParse(_parkingController.text),
          agentFee: double.tryParse(_agentFeeController.text),
          legalFee: double.tryParse(_legalFeeController.text),
          agreementFee: double.tryParse(_agreementFeeController.text),
          cautionFee: double.tryParse(_cautionFeeController.text),
          serviceFee: double.tryParse(_serviceFeeController.text),
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          createdAt: DateTime.now(),
        );
        await _propertyService.addProperty(newProp);
      } else {
        // Update
        final updatedProp = PropertyModel(
          id: widget.property!.id,
          ownerId: widget.property!.ownerId,
          title: _titleController.text,
          description: _descriptionController.text,
          type: _selectedType,
          location: _locationController.text,
          price: double.tryParse(_priceController.text),
          images: allMedia,
          video: videoUrl,
          features: features,
          bedrooms: int.tryParse(_bedroomsController.text),
          bathrooms: int.tryParse(_bathroomsController.text),
          sqft: double.tryParse(_sqftController.text),
          parkingSpaces: int.tryParse(_parkingController.text),
          agentFee: double.tryParse(_agentFeeController.text),
          legalFee: double.tryParse(_legalFeeController.text),
          agreementFee: double.tryParse(_agreementFeeController.text),
          cautionFee: double.tryParse(_cautionFeeController.text),
          serviceFee: double.tryParse(_serviceFeeController.text),
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          createdAt: widget.property!.createdAt,
        );
        await _propertyService.updateProperty(updatedProp);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property saved successfully!')),
        );
        context.pop(); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property == null ? 'Add Property' : 'Edit Property'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                items: _types
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (₦)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerScreen(
                        initialLocation: _selectedLocation,
                      ),
                    ),
                  );
                  if (result != null && result is LocationPickerResult) {
                    setState(() {
                      _selectedLocation = result.latLng;
                      _locationController.text = result.address;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Location/Address',
                  hintText: 'Tap to search or select on map',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationPickerScreen(
                            initialLocation: _selectedLocation,
                          ),
                        ),
                      );
                      if (result != null && result is LocationPickerResult) {
                        setState(() {
                          _selectedLocation = result.latLng;
                          _locationController.text = result.address;
                        });
                      }
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              if (_selectedLocation != null)
                Text(
                  'Selected Coords: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Specs Row 1
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      decoration: const InputDecoration(labelText: 'Bedrooms'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomsController,
                      decoration: const InputDecoration(labelText: 'Bathrooms'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Specs Row 2
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sqftController,
                      decoration: const InputDecoration(
                        labelText: 'Size (sqft)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _parkingController,
                      decoration: const InputDecoration(
                        labelText: 'Parking Spaces',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Fees (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Fees
              TextFormField(
                controller: _agentFeeController,
                decoration: const InputDecoration(labelText: 'Agent Fee'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _legalFeeController,
                decoration: const InputDecoration(labelText: 'Legal Fee'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _agreementFeeController,
                decoration: const InputDecoration(labelText: 'Agreement Fee'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cautionFeeController,
                decoration: const InputDecoration(labelText: 'Caution Fee'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _serviceFeeController,
                decoration: const InputDecoration(labelText: 'Service Charge'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features (comma separated)',
                ),
              ),
              const SizedBox(height: 16),

              // Images Section
              const Text(
                'Images (Min 2)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ..._existingImages.map(
                    (url) => Stack(
                      children: [
                        Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.error),
                        ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _existingImages.remove(url)),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._newImages.map(
                    (file) => Stack(
                      children: [
                        Image.file(
                          File(file.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _newImages.remove(file)),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.add_a_photo)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Video Section
              const Text(
                'Property Video (Required)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_existingVideo != null && _newVideo == null) ...[
                ListTile(
                  leading: const Icon(Icons.videocam, size: 40),
                  title: const Text('Current Video'),
                  subtitle: const Text('Already uploaded'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _existingVideo = null),
                  ),
                ),
              ] else if (_newVideo != null) ...[
                ListTile(
                  leading: const Icon(
                    Icons.videocam,
                    color: Colors.green,
                    size: 40,
                  ),
                  title: Text(_newVideo!.name),
                  subtitle: const Text('Ready to upload'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _newVideo = null),
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Select Video'),
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProperty,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Text(
                        widget.property == null
                            ? 'Create Listing'
                            : 'Update Listing',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
