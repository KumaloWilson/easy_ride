import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/location_model.dart';
import '../controllers/rider_controller.dart';
import '../models/saved_location_model.dart';

class SavedLocationsList extends StatelessWidget {
  final Function(SavedLocationModel) onLocationSelected;
  final RiderController controller = Get.find<RiderController>();

  SavedLocationsList({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final savedLocations = controller.savedLocations;
      
      if (savedLocations.isEmpty) {
        return _buildEmptyState(context);
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Saved Locations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedLocations.length,
            itemBuilder: (context, index) {
              final location = savedLocations[index];
              return _buildLocationItem(context, location);
            },
          ),
          const SizedBox(height: 8),
          _buildAddLocationButton(context),
        ],
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.location_off,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                'No saved locations',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Save your frequent destinations',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAddLocationButton(context),
      ],
    );
  }

  Widget _buildLocationItem(BuildContext context, SavedLocationModel location) {
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
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(
          iconData,
          color: Colors.black87,
        ),
      ),
      title: Text(
        location.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        location.address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onLocationSelected(location),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showLocationOptions(context, location),
      ),
    );
  }

  Widget _buildAddLocationButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: OutlinedButton.icon(
        onPressed: () => _showAddLocationDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add New Location'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showLocationOptions(BuildContext context, SavedLocationModel location) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Location'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditLocationDialog(context, location);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Location', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, location);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    LocationType selectedType = LocationType.favorite;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
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
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location Type:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildTypeChip(
                              context,
                              LocationType.home,
                              'Home',
                              Icons.home,
                              selectedType,
                              (type) => setState(() => selectedType = type),
                            ),
                            _buildTypeChip(
                              context,
                              LocationType.work,
                              'Work',
                              Icons.work,
                              selectedType,
                              (type) => setState(() => selectedType = type),
                            ),
                            _buildTypeChip(
                              context,
                              LocationType.favorite,
                              'Favorite',
                              Icons.favorite,
                              selectedType,
                              (type) => setState(() => selectedType = type),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please fill in all fields',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                
                // In a real app, you would geocode the address to get coordinates
                // For this example, we'll use a placeholder location
                final location = SavedLocationModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  latitude: 37.7749, // Placeholder
                  longitude: -122.4194, // Placeholder
                  type: selectedType,
                );
                
                await controller.saveLocation(
                  LocationModel(
                    name: nameController.text.trim(),
                    address: addressController.text.trim(),
                    latitude: 37.7749, // Placeholder
                    longitude: -122.4194, // Placeholder
                    type: selectedType,

                  )
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditLocationDialog(BuildContext context, SavedLocationModel location) {
    final TextEditingController nameController = TextEditingController(text: location.name);
    final TextEditingController addressController = TextEditingController(text: location.address);
    LocationType selectedType = location.type;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
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
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location Type:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildTypeChip(
                              context,
                              LocationType.home,
                              'Home',
                              Icons.home,
                              selectedType,
                              (type) => setState(() => selectedType = type),
                            ),
                            _buildTypeChip(
                              context,
                              LocationType.work,
                              'Work',
                              Icons.work,
                              selectedType,
                              (type) => setState(() => selectedType = type),
                            ),
                            _buildTypeChip(
                              context,
                              LocationType.favorite,
                              'Favorite',
                              Icons.favorite,
                              selectedType,
                              (type) => setState(() => selectedType = type),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please fill in all fields',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                
                final updatedLocation = SavedLocationModel(
                  id: location.id,
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  latitude: location.latitude,
                  longitude: location.longitude,
                  type: selectedType,
                );
                
                await controller.updateLocation(updatedLocation);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, SavedLocationModel location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Location'),
          content: Text(
            'Are you sure you want to delete "${location.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.deleteLocation(location.id);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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
          Text(label),
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
