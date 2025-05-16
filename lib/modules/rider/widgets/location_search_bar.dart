import 'package:flutter/material.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LocationSearchBar extends StatefulWidget {
  final VoidCallback? onTap;
  final String? pickupLocation;
  final String? dropoffLocation;
  final bool isExpanded;
  final VoidCallback? onClose;
  final Function(Map<String, dynamic>)? onPickupSelected;
  final Function(Map<String, dynamic>)? onDropoffSelected;
  final Function(Map<String, dynamic>)? onLocationSelected;

  const LocationSearchBar({
    Key? key,
    this.onTap,
    this.pickupLocation,
    this.dropoffLocation,
    this.isExpanded = false,
    this.onClose,
    this.onPickupSelected,
    this.onDropoffSelected,
    this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulate search results
    // In a real app, you would use a geocoding service
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        _searchResults = [
          {
            'name': 'Central Park',
            'address': 'New York, NY 10022',
            'latitude': 40.7812,
            'longitude': -73.9665,
          },
          {
            'name': 'Times Square',
            'address': 'New York, NY 10036',
            'latitude': 40.7580,
            'longitude': -73.9855,
          },
          {
            'name': 'Empire State Building',
            'address': '350 5th Ave, New York, NY 10118',
            'latitude': 40.7484,
            'longitude': -73.9857,
          },
          {
            'name': 'Statue of Liberty',
            'address': 'New York, NY 10004',
            'latitude': 40.6892,
            'longitude': -74.0445,
          },
          {
            'name': 'Brooklyn Bridge',
            'address': 'Brooklyn Bridge, New York, NY 10038',
            'latitude': 40.7061,
            'longitude': -73.9969,
          },
        ].where((location) {
          return location['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
              location['address'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
        }).toList();
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isExpanded) {
      return _buildExpandedSearchBar();
    }

    return _buildCollapsedSearchBar();
  }

  Widget _buildCollapsedSearchBar() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.pickupLocation ?? 'Set pickup location',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: widget.pickupLocation == null || widget.pickupLocation == 'Set pickup location'
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.dropoffLocation != null && widget.dropoffLocation != 'Where to?')
                    const SizedBox(height: 4),
                  if (widget.dropoffLocation != null && widget.dropoffLocation != 'Where to?')
                    Text(
                      widget.dropoffLocation!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(
      begin: -0.1,
      end: 0,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildExpandedSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Set location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Pickup and dropoff
          if (widget.onPickupSelected != null && widget.onDropoffSelected != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Pickup location',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          controller: TextEditingController(text: widget.pickupLocation),
                          readOnly: true,
                          onTap: () {
                            // Clear search and show pickup options
                            setState(() {
                              _searchController.clear();
                              _searchResults = [];
                            });
                          },
                        ),
                        const Divider(),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Where to?',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          controller: TextEditingController(
                            text: widget.dropoffLocation == 'Where to?' ? '' : widget.dropoffLocation,
                          ),
                          readOnly: true,
                          onTap: () {
                            // Clear search and show dropoff options
                            setState(() {
                              _searchController.clear();
                              _searchResults = [];
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (widget.onPickupSelected != null && widget.onDropoffSelected != null)
            const Divider(),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for a location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onTap: () {
                // Request focus
                _searchFocusNode.requestFocus();
              },
            ),
          ),

          // Search results
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_searchResults.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final location = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(location['name'].toString()),
                  subtitle: Text(location['address'].toString()),
                  onTap: () {
                    // Select location
                    if (widget.onLocationSelected != null) {
                      widget.onLocationSelected!(location);
                    } else if (widget.pickupLocation == 'Set pickup location' && widget.onPickupSelected != null) {
                      widget.onPickupSelected!(location);
                    } else if (widget.onDropoffSelected != null) {
                      widget.onDropoffSelected!(location);
                    }
                  },
                );
              },
            ),
        ],
      ),
    ).animate().fadeIn().scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      curve: Curves.easeOutQuart,
    );
  }
}
