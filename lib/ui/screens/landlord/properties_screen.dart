import 'package:flutter/material.dart';
import '../../../data/models/property_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/property_service.dart';
import '../../widgets/property_card.dart';
import '../property_form_screen.dart';

class LandlordPropertiesScreen extends StatefulWidget {
  const LandlordPropertiesScreen({super.key});

  @override
  State<LandlordPropertiesScreen> createState() =>
      _LandlordPropertiesScreenState();
}

class _LandlordPropertiesScreenState extends State<LandlordPropertiesScreen> {
  final PropertyService _propertyService = PropertyService();
  final AuthService _authService = AuthService();
  late Future<List<PropertyModel>> _propertiesFuture;

  String _selectedFilter = 'Available'; // Available, Closed, All

  @override
  void initState() {
    super.initState();
    _refreshProperties();
  }

  void _refreshProperties() {
    final user = _authService.currentUserId;
    if (user != null) {
      setState(() {
        String? statusParam;
        if (_selectedFilter == 'Available') statusParam = 'available';
        if (_selectedFilter == 'Closed') statusParam = 'closed';
        // 'All' sends null to let service decide or we explicitly handle 'all'

        _propertiesFuture = _propertyService.getProperties(
          ownerId: user,
          status: statusParam ?? 'all',
        );
      });
    } else {
      setState(() {
        _propertiesFuture = Future.value([]);
      });
    }
  }

  Future<void> _handleCloseProperty(PropertyModel property) async {
    String? selectedReason;
    final reasons = [
      "Property rented out or sold to a user on the app",
      "Property rented out or sold to someone not registered on the app",
      "Property no longer for sale or rentage",
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        String? tempReason = reasons[0];
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Close Property'),
              content: RadioGroup<String>(
                groupValue: tempReason,
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => tempReason = val);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons.map((r) {
                    return RadioListTile<String>(
                      title: Text(r, style: const TextStyle(fontSize: 14)),
                      value: r,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    selectedReason = tempReason;
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedReason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Closing property...')));

      await _propertyService.updatePropertyStatus(
        property.id,
        'closed',
        selectedReason,
      );

      _refreshProperties();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Properties')),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['Available', 'Closed', 'All'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                        _refreshProperties();
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<PropertyModel>>(
              future: _propertiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final properties = snapshot.data ?? [];

                if (properties.isEmpty) {
                  return Center(
                    child: Text('No $_selectedFilter properties found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    final isAvailable = property.status == 'available';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PropertyCard(
                          property: property,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PropertyFormScreen(property: property),
                              ),
                            );
                            _refreshProperties();
                          },
                        ),
                        if (isAvailable)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: OutlinedButton.icon(
                              onPressed: () => _handleCloseProperty(property),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Close Listing'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertyFormScreen()),
          );
          _refreshProperties();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
