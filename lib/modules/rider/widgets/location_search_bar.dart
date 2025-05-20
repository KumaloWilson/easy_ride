import 'package:flutter/material.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:easy_ride/modules/rider/controllers/rider_controller.dart';
import 'package:easy_ride/models/location_model.dart';

import '../models/saved_location_model.dart';

class LocationSearchBar extends StatefulWidget {
  final VoidCallback? onTap;
  final String? pickupLocation;
  final String? dropoffLocation;
  final bool isExpanded;
  final VoidCallback? onClose;
  final Function(Map<String, dynamic>)? onPickupSelected;
  final Function(Map<String, dynamic>)? onDropoffSelected;
  final Function(Map<String, dynamic>)? onLocationSelected;
  final bool isPickupMode;

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
    this.isPickupMode = false,
  }) : super(key: key);

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final RiderController _riderController = Get.find<RiderController>();
  List<LocationModel> _searchResults = [];
  bool _isSearching = false;
  bool _showRecentSearches = false;

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
        _showRecentSearches = true;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showRecentSearches = false;
    });

    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _riderController.searchPlaces(query);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searchResults = [];
        _isSearching = false;
      });

      print('Error searching for places: $e');
    }
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
                Text(
                  widget.isPickupMode ? 'Set pickup location' : 'Set destination',
                  style: const TextStyle(
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
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                              _searchResults = [];
                              _showRecentSearches = true;
                            });
                            // Set to pickup mode
                            if (widget.isPickupMode == false && widget.onClose != null) {
                              widget.onClose!();
                              // Reopen in pickup mode
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (widget.onTap != null) widget.onTap!();
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.pickupLocation ?? 'Set pickup location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: widget.isPickupMode ? AppTheme.primaryColor : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isPickupMode)
                                  const Icon(Icons.edit, size: 16, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                              _searchResults = [];
                              _showRecentSearches = true;
                            });
                            // Set to dropoff mode
                            if (widget.isPickupMode == true && widget.onClose != null) {
                              widget.onClose!();
                              // Reopen in dropoff mode
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (widget.onTap != null) widget.onTap!();
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.dropoffLocation ?? 'Where to?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: !widget.isPickupMode ? AppTheme.primaryColor : Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!widget.isPickupMode)
                                  const Icon(Icons.edit, size: 16, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
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
                hintText: widget.isPickupMode ? 'Search for pickup location' : 'Search for destination',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _showRecentSearches = true;
                    });
                  },
                )
                    : null,
              ),
              onTap: () {
                // Request focus
                _searchFocusNode.requestFocus();
                setState(() {
                  _showRecentSearches = true;
                });
              },
            ),
          ),

          // Current location option
          if (widget.isPickupMode)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
              title: const Text('Use current location'),
              onTap: () async {
                await _riderController.getCurrentLocation();
                if (widget.onPickupSelected != null && _riderController.pickupLocation.value != null) {
                  widget.onPickupSelected!(_riderController.pickupLocation.value!.toMap());
                }
                if (widget.onClose != null) widget.onClose!();
              },
            ),

          // Saved locations
          if (_showRecentSearches && _searchController.text.isEmpty)
            _buildSavedLocations(),

          // Search results
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_searchResults.isNotEmpty)
            _buildSearchResults(),
        ],
      ),
    ).animate().fadeIn().scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildSavedLocations() {
    return Obx(() {
      final savedLocations = _riderController.savedLocations;

      if (savedLocations.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No saved locations yet'),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Saved Places',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedLocations.length > 5 ? 5 : savedLocations.length,
            itemBuilder: (context, index) {
              final location = savedLocations[index];

              IconData iconData;
              switch (location.type) {
                case LocationType.home:
                  iconData = Icons.home;
                  break;
                case LocationType.work:
                  iconData = Icons.work;
                  break;
                case LocationType.favorite:
                  iconData = Icons.favorite;
                  break;
                default:
                  iconData = Icons.location_on;
              }

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData),
                ),
                title: Text(location.name),
                subtitle: Text(
                  location.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  final locationMap = {
                    'name': location.name,
                    'address': location.address,
                    'latitude': location.latitude,
                    'longitude': location.longitude,
                  };

                  if (widget.isPickupMode && widget.onPickupSelected != null) {
                    widget.onPickupSelected!(locationMap);
                  } else if (!widget.isPickupMode && widget.onDropoffSelected != null) {
                    widget.onDropoffSelected!(locationMap);
                  } else if (widget.onLocationSelected != null) {
                    widget.onLocationSelected!(locationMap);
                  }

                  if (widget.onClose != null) widget.onClose!();
                },
              );
            },
          ),
          TextButton(
            onPressed: () {
              Get.to(() => SavedPlacesScreen());
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Manage saved places'),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(location.name),
          subtitle: Text(
            location.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            final locationMap = location.toMap();

            if (widget.isPickupMode && widget.onPickupSelected != null) {
              widget.onPickupSelected!(locationMap);
            } else if (!widget.isPickupMode && widget.onDropoffSelected != null) {
              widget.onDropoffSelected!(locationMap);
            } else if (widget.onLocationSelected != null) {
              widget.onLocationSelected!(locationMap);
            }

            if (widget.onClose != null) widget.onClose!();
          },
        );
      },
    );
  }
}

class SavedPlacesScreen extends StatelessWidget {
  final RiderController controller = Get.find<RiderController>();

  SavedPlacesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLocationDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingSavedLocations.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.savedLocations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No saved places yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your favorite places for quick access',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddLocationDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a place'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.savedLocations.length,
          itemBuilder: (context, index) {
            final location = controller.savedLocations[index];

            IconData iconData;
            switch (location.type) {
              case 'home':
                iconData = Icons.home;
                break;
              case 'work':
                iconData = Icons.work;
                break;
              case 'favorite':
                iconData = Icons.favorite;
                break;
              default:
                iconData = Icons.location_on;
            }

            return Dismissible(
              key: Key(location.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Saved Place'),
                    content: Text('Are you sure you want to delete "${location.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                controller.deleteLocation(location.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${location.name} deleted')),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(iconData, color: Colors.black87),
                ),
                title: Text(location.name),
                subtitle: Text(
                  location.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditLocationDialog(context, location),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    LocationType selectedType = LocationType.favorite;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Place'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Home, Work, Gym',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter address',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Place Type:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildTypeChip(
                          context, LocationType.home, 'Home', Icons.home,
                          selectedType, (type) => setState(() => selectedType = type)
                      ),
                      _buildTypeChip(
                          context, LocationType.work, 'Work', Icons.work,
                          selectedType, (type) => setState(() => selectedType = type)
                      ),
                      _buildTypeChip(
                          context, LocationType.favorite, 'Favorite', Icons.favorite,
                          selectedType, (type) => setState(() => selectedType = type)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty ||
                      addressController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields')),
                    );
                    return;
                  }



                  final location = LocationModel(
                    name: nameController.text.trim(),
                    address: addressController.text.trim(),
                    latitude: controller.currentLocation.value.latitude,
                    longitude: controller.currentLocation.value.longitude,
                    type: selectedType,
                  );

                  controller.saveLocation(location);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, dynamic location) {
    final TextEditingController nameController = TextEditingController(text: location.name);
    final TextEditingController addressController = TextEditingController(text: location.address);
    LocationType selectedType = location.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Saved Place'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Place Type:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildTypeChip(
                          context, LocationType.home, 'Home', Icons.home,
                          selectedType, (type) => setState(() => selectedType = type)
                      ),
                      _buildTypeChip(
                          context, LocationType.work, 'Work', Icons.work,
                          selectedType, (type) => setState(() => selectedType = type)
                      ),
                      _buildTypeChip(
                          context, LocationType.favorite, 'Favorite', Icons.favorite,
                          selectedType, (type) => setState(() => selectedType = type)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty ||
                      addressController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields')),
                    );
                    return;
                  }

                  final updatedLocation = {
                    'id': location.id,
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'latitude': location.latitude,
                    'longitude': location.longitude,
                    'type': selectedType,
                  };

                  controller.updateLocation(
                    SavedLocationModel.fromMap(updatedLocation, location.id),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(
      BuildContext context,
      LocationType type,
      String label,
      IconData icon,
      LocationType selectedType,
      Function(LocationType) onSelected,
      ) {
    final isSelected = type == selectedType;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 4),
          Text(label.toString().split('.').last),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(type);
        }
      },
    );
  }
}
