import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/rider_controller.dart';

class RiderMapsTab extends StatelessWidget {
  final RiderController controller = Get.find<RiderController>();

  RiderMapsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final markers = controller.markers;
      final polylines = controller.polylines;
      final currentPos = controller.currentLocation.value;
      final initialPos = controller.initialCameraPosition.value;

      return GoogleMap(
        initialCameraPosition: initialPos,
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
        onMapCreated: (GoogleMapController mapController) {
          controller.mapController.value = mapController;
          controller.onMapCreated(mapController);

          // Ensure we center on user location after map is created
          if (currentPos.latitude != 0 && currentPos.longitude != 0) {
            Future.delayed(Duration(milliseconds: 500), () {
              mapController.animateCamera(
                CameraUpdate.newLatLngZoom(currentPos, 15),
              );
            });
          }
        },
      );
    });
  }
}
