import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng selectedLocation = const LatLng(13.0827, 80.2707); // default (Chennai)

  Future<String> getAddressFromLatLng(LatLng position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark place = placemarks.first;

    return "${place.street}, ${place.locality}, ${place.administrativeArea}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation,
              zoom: 14,
            ),
            onTap: (position) {
              setState(() {
                selectedLocation = position;
              });
            },
            markers: {
              Marker(
                markerId: const MarkerId("selected"),
                position: selectedLocation,
              ),
            },
          ),

          /// CONFIRM BUTTON
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                String address =
                    await getAddressFromLatLng(selectedLocation);

                Navigator.pop(context, address);
              },
              child: const Text("Confirm Location"),
            ),
          ),
        ],
      ),
    );
  }
}
