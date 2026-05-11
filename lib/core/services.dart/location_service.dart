import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

Future<String?> getCurrentLocationAddress() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }

  if (permission == LocationPermission.deniedForever) return null;

  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude, position.longitude);

  Placemark place = placemarks.first;

  return "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
}
