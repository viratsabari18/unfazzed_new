import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestMap extends StatefulWidget {
  const TestMap({super.key});

  @override
  State<TestMap> createState() => _TestMapState();
}

class _TestMapState extends State<TestMap> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    debugPrint("TEST MAP SCREEN BUILDING");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Maps Test"),
      ),
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(12.9716, 77.5946),
            zoom: 14,
          ),

          mapType: MapType.normal,

          myLocationEnabled: false,
          myLocationButtonEnabled: false,

          zoomControlsEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: true,

          markers: {
            const Marker(
              markerId: MarkerId("test"),
              position: LatLng(12.9716, 77.5946),
            ),
          },

          onMapCreated: (GoogleMapController controller) {
            debugPrint("GOOGLE MAP CREATED SUCCESSFULLY");

            _controller = controller;

            debugPrint("CONTROLLER: $_controller");
          },

          onCameraMove: (position) {
            debugPrint(
              "CAMERA MOVING: ${position.target.latitude}, "
              "${position.target.longitude}",
            );
          },

          onCameraIdle: () {
            debugPrint("CAMERA IDLE");
          },
        ),
      ),
    );
  }
}