import 'package:geolocator/geolocator.dart';

import '../core/app_config.dart';

class ReducedLocation {
  const ReducedLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double accuracy;

  String get apiValue =>
      '${latitude.toStringAsFixed(AppConfig.reducedLocationDecimals)},'
      '${longitude.toStringAsFixed(AppConfig.reducedLocationDecimals)}';
}

class LocationService {
  Future<ReducedLocation?> currentReducedLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
    double round(double v) {
      final factor = switch (AppConfig.reducedLocationDecimals) {
        0 => 1.0,
        1 => 10.0,
        2 => 100.0,
        _ => 1000.0,
      };
      return (v * factor).round() / factor;
    }

    return ReducedLocation(
      latitude: round(p.latitude),
      longitude: round(p.longitude),
      accuracy: p.accuracy,
    );
  }
}
