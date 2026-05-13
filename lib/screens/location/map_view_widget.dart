import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewWidget extends StatefulWidget {
  final Function(GoogleMapController) onMapCreated;
  final Function(CameraPosition) onCameraMove;
  final VoidCallback onCameraIdle;
  final LatLng initialLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const MapViewWidget({
    super.key,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraIdle,
    required this.initialLocation,
    this.markers = const {},
    this.polylines = const {},
  });

  @override
  State<MapViewWidget> createState() => MapViewWidgetState();
}

class MapViewWidgetState extends State<MapViewWidget> {
  late GoogleMapController _mapController;
  bool _isMapReady = false;

  // Public method to animate camera
  Future<void> animateTo(LatLng target, {double zoom = 18.0}) async {
    if (_isMapReady) {
      await _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    }
  }

  // Public method to update map style
  Future<void> setMapStyle(String mapStyle) async {
    if (_isMapReady) {
      await _mapController.setMapStyle(mapStyle);
    }
  }

  // Public method to move camera with custom zoom
  Future<void> moveCamera(LatLng target, double zoom) async {
    if (_isMapReady) {
      await _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
   
      initialCameraPosition: CameraPosition(
        target: widget.initialLocation,
        zoom: 15.5,
      ),
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomGesturesEnabled: true,
      zoomControlsEnabled: false,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      compassEnabled: false,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: false,
      trafficEnabled: false,
    padding: EdgeInsets.zero,  
      markers: widget.markers,
      polylines: widget.polylines,
      onMapCreated: (controller) async {
        _mapController = controller;
        _isMapReady = true;
        widget.onMapCreated(controller);
      },
      onCameraMove: (position) {
        widget.onCameraMove(position);
      },
      onCameraIdle: () {
        widget.onCameraIdle();
      },
    );
  }
}