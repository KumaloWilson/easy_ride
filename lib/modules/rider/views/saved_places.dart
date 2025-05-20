import 'package:easy_ride/models/location_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_ride/core/theme/app_theme.dart';
import 'package:easy_ride/modules/rider/controllers/rider_controller.dart';
import 'package:easy_ride/modules/rider/models/saved_location_model.dart';
import 'package:easy_ride/core/widgets/animated_button.dart';

class SavedPlacesView extends StatelessWidget {
  final RiderController controller = Get.find<RiderController>();

  SavedPlacesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPlaceDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingSavedLocations.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.savedLocations.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildSavedPlacesList(context);
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved places yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your frequent destinations for quick access',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AnimatedButton(
            onPressed: () => _showAddPlaceDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add a place',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPlacesList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Home and Work section
        _buildHomeWorkSection(context),
        const SizedBox(height: 24),
        // Other saved places
        _buildOtherPlacesSection(context),
      ],
    );
  }

  Widget _buildHomeWorkSection(BuildContext context) {
    final homeLocation = controller.savedLocations.firstWhereOrNull((loc) => loc.type == 'home');
    final workLocation = controller.savedLocations.firstWhereOrNull((loc) => loc.type == 'work');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home & Work',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Home location
        _buildHomeWorkCard(
          context,
          LocationType.home,
          'Home',
          Icons.home,
          homeLocation,
        ),
        const SizedBox(height: 16),
        // Work location
        _buildHomeWorkCard(
          context,
          LocationType.work,
          'Work',
          Icons.work,
          workLocation,
        ),
      ],
    );
  }

  Widget _buildHomeWorkCard(
      BuildContext context,
      LocationType type,
      String title,
      IconData icon,
      SavedLocationModel? location,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: location != null ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[200],
          child: Icon(
            icon,
            color: location != null ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: location != null
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              location.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        )
            : const Text('Not set'),
        trailing: location != null
            ? IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditPlaceDialog(context, location),
        )
            : TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          onPressed: () => _showAddPlaceDialog(context, type: type),
        ),
      ),
    );
  }

  Widget _buildOtherPlacesSection(BuildContext context) {
    final otherLocations = controller.savedLocations
        .where((loc) => loc.type != 'home' && loc.type != 'work')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Other Places',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (otherLocations.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
                onPressed: () => _showAddPlaceDialog(context),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (otherLocations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.star_border,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No other places saved yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add a place'),
                    onPressed: () => _showAddPlaceDialog(context),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: otherLocations.length,
            itemBuilder: (context, index) {
              final location = otherLocations[index];
              return _buildSavedPlaceItem(context, location);
            },
          ),
      ],
    );
  }

  Widget _buildSavedPlaceItem(BuildContext context, SavedLocationModel location) {
    IconData iconData;
    switch (location.type) {
      case 'favorite':
        iconData = Icons.favorite;
        break;
      case 'recent':
        iconData = Icons.history;
        break;
      default:
        iconData = Icons.location_on;
    }

    return Dismissible(
      key: Key(location.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Icon(iconData, color: Colors.black87),
          ),
          title: Text(
            location.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            location.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditPlaceDialog(context, location),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
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

                  if (confirm == true) {
                    controller.deleteLocation(location.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${location.name} deleted')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPlaceDialog(BuildContext context, {LocationType? type}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    LocationType selectedType = type ?? LocationType.favorite;

    if (type == 'home') {
      nameController.text = 'Home';
    } else if (type == 'work') {
      nameController.text = 'Work';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add ${type != null ? type.toString().split('.').last.capitalize! : 'New'} Place'),
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
                    readOnly: type == 'home' || type == 'work',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter address',
                    ),
                  ),
                  if (type == null) ...[
                    const SizedBox(height: 16),
                    const Text('Place Type:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTypeChip(
                            context, LocationType.favorite, 'Favorite', Icons.favorite,
                            selectedType, (newType) => setState(() => selectedType = newType)
                        ),
                        _buildTypeChip(
                            context, LocationType.favorite, 'Recent', Icons.history,
                            selectedType, (newType) => setState(() => selectedType = newType)
                        ),
                      ],
                    ),
                  ],
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

  void _showEditPlaceDialog(BuildContext context, SavedLocationModel location) {
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
                    readOnly: location.type == 'home' || location.type == 'work',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                    ),
                  ),
                  if (location.type != 'home' && location.type != 'work') ...[
                    const SizedBox(height: 16),
                    const Text('Place Type:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTypeChip(
                            context, LocationType.favorite, 'Favorite', Icons.favorite,
                            selectedType, (newType) => setState(() => selectedType = newType)
                        ),
                        _buildTypeChip(
                            context, LocationType.recent, 'Recent', Icons.history,
                            selectedType, (newType) => setState(() => selectedType = newType)
                        ),
                      ],
                    ),
                  ],
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
                    'type': location.type == LocationType.home || location.type == LocationType.work
                        ? location.type
                        : selectedType,
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
