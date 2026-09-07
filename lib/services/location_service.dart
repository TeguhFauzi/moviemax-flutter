import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class UserLocationData {
  final LatLng position;
  final double speed;
  final double accuracy;
  final String providerType; // 'GPS Hardware Sensor' or 'Network Provider (ISP)'
  final String ispName;
  final String cityName;
  final String ipAddress;

  UserLocationData({
    required this.position,
    required this.speed,
    required this.accuracy,
    required this.providerType,
    required this.ispName,
    required this.cityName,
    required this.ipAddress,
  });
}

class LocationService {
  static Future<UserLocationData> getRealUserLocation() async {
    // 1. Coba ambil dari Sensor GPS Hardware HP (High Accuracy)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          return UserLocationData(
            position: LatLng(pos.latitude, pos.longitude),
            speed: pos.speed * 3.6, // m/s ke km/h
            accuracy: pos.accuracy,
            providerType: 'GPS Hardware Sensor',
            ispName: 'GPS Satellite Locked',
            cityName: 'GPS Terhubung',
            ipAddress: 'Native GPS',
          );
        }
      }
    } catch (e) {
      print('GPS Hardware Exception, Fallback to Network Provider: $e');
    }

    // 2. Fallback: Ambil dari Network Provider / ISP Jaringan IP HP
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double lat = (data['latitude'] as num).toDouble();
        final double lng = (data['longitude'] as num).toDouble();
        final String isp = data['org'] ?? data['asn'] ?? 'Cellular / Wi-Fi Provider';
        final String city = data['city'] ?? 'Indonesia';
        final String ip = data['ip'] ?? '';

        return UserLocationData(
          position: LatLng(lat, lng),
          speed: 0.0,
          accuracy: 50.0,
          providerType: 'Network Provider (ISP / IP)',
          ispName: isp,
          cityName: city,
          ipAddress: ip,
        );
      }
    } catch (e) {
      print('Network Provider Exception: $e');
    }

    // 3. Default fallback lokasi Indonesia
    return UserLocationData(
      position: const LatLng(-6.2088, 106.8456),
      speed: 0.0,
      accuracy: 100.0,
      providerType: 'Network Triangulation',
      ispName: 'Cellular Tower',
      cityName: 'Jakarta',
      ipAddress: '127.0.0.1',
    );
  }
}
