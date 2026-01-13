import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final String selectedType;
  final Function(String?) onTypeChanged;
  final Function(String) onSearchChanged;
  final RangeValues currentPriceRange;
  final Function(RangeValues) onPriceChanged;

  const FilterBar({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onSearchChanged,
    required this.currentPriceRange,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by location...',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  underline: Container(),
                  items: ['All', 'Apartment', 'House', 'Land', 'Office']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: onTypeChanged,
                ),
                const SizedBox(width: 16),
                ActionChip(
                  label: Text(
                    '₦${(currentPriceRange.start / 1000000).toStringAsFixed(1)}M - ₦${(currentPriceRange.end / 1000000).toStringAsFixed(1)}M+',
                  ),
                  avatar: const Icon(Icons.attach_money),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Price Range',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            RangeSlider(
                              values: currentPriceRange,
                              min: 0,
                              max: 100000000,
                              divisions: 20,
                              labels: RangeLabels(
                                '₦${(currentPriceRange.start / 1000000).toStringAsFixed(1)}M',
                                '₦${(currentPriceRange.end / 1000000).toStringAsFixed(1)}M',
                              ),
                              onChanged: onPriceChanged,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
