import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_toggles.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../providers/call_provider.dart';
import '../services/firebase_call_service.dart';

class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  final MapController _mapController = MapController();
  final FirebaseService _firebaseService = FirebaseService();

  UserLocationData? _amrhdlaData;
  UserLocationData? _tfauzyyData;
  bool _isLoadingLocation = true;
  Timer? _locationTimer;
  double _zoomLevel = 14.0;
  bool _hasInitialCentered = false;
  String? _selectedMapTileStyle = 'Satellite';

  static const Map<String, String> _tileUrls = {
    'Street': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'Dark':
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    'Satellite':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };

  @override
  void initState() {
    super.initState();
    _fetchRealUserLocation();
    _startRealtimeLocationStream();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRealUserLocation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userName;
    final partnerUser = currentUser == 'amrhdla' ? 'tfauzyy' : 'amrhdla';

    final realData = await LocationService.getRealUserLocation();

    await _firebaseService.syncUserLocation(
      currentUser,
      realData.position.latitude,
      realData.position.longitude,
      realData.ispName,
      realData.cityName,
    );

    final partnerSaved = await _firebaseService.getUserLocation(partnerUser);

    UserLocationData partnerData;
    if (partnerSaved != null) {
      partnerData = UserLocationData(
        position: LatLng(partnerSaved['lat'] as double, partnerSaved['lng'] as double),
        speed: 0.0,
        accuracy: realData.accuracy,
        providerType: realData.providerType,
        ispName: partnerSaved['isp'] ?? realData.ispName,
        cityName: partnerSaved['city'] ?? realData.cityName,
        ipAddress: realData.ipAddress,
      );
    } else {
      partnerData = realData;
    }

    if (mounted) {
      setState(() {
        if (currentUser == 'amrhdla') {
          _amrhdlaData = realData;
          _tfauzyyData = partnerData;
        } else {
          _tfauzyyData = realData;
          _amrhdlaData = partnerData;
        }
        _isLoadingLocation = false;
      });

      if (!_hasInitialCentered) {
        _hasInitialCentered = true;
        _mapController.move(realData.position, _zoomLevel);
      }
    }
  }

  void _startRealtimeLocationStream() {
    _locationTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) return;
      await _fetchRealUserLocation();
    });
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) * cos(p2.latitude * p) * (1 - cos((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _zoomIn() {
    setState(() => _zoomLevel = min(_zoomLevel + 1.0, 18.0));
    _mapController.move(_mapController.camera.center, _zoomLevel);
  }

  void _zoomOut() {
    setState(() => _zoomLevel = max(_zoomLevel - 1.0, 4.0));
    _mapController.move(_mapController.camera.center, _zoomLevel);
  }

  void _focusTo(LatLng target) {
    _mapController.move(target, 15.5);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final currentUser = authProvider.userName;
    final activeTileStyle = _selectedMapTileStyle ?? 'Satellite';

    if (_isLoadingLocation || _amrhdlaData == null || _tfauzyyData == null) {
      return Scaffold(
        backgroundColor: settings.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: settings.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Mendeteksi Sensor GPS & Provider Jaringan HP...',
                style: TextStyle(color: settings.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    final amrPos = _amrhdlaData!.position;
    final tfaPos = _tfauzyyData!.position;
    final liveDistance = _calculateDistanceKm(amrPos, tfaPos);
    final myData = currentUser == 'amrhdla' ? _amrhdlaData! : _tfauzyyData!;

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: settings.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.gps_fixed_rounded, color: settings.accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                settings.tr('map_screen_title'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: settings.textPrimaryColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location_rounded, color: settings.primaryColor),
            tooltip: settings.tr('map_my_location'),
            onPressed: () => _fetchRealUserLocation(),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.layers_rounded, color: settings.textPrimaryColor),
            color: settings.surfaceColor,
            onSelected: (style) => setState(() => _selectedMapTileStyle = style),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Street', child: Text('🗺️ Standard Street', style: TextStyle(color: settings.textPrimaryColor))),
              PopupMenuItem(value: 'Dark', child: Text('🌙 Esri Dark Gray', style: TextStyle(color: settings.textPrimaryColor))),
              PopupMenuItem(value: 'Satellite', child: Text('🛰️ Satellite View', style: TextStyle(color: settings.textPrimaryColor))),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SettingsToggles(compact: true),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Tile Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: myData.position,
              initialZoom: _zoomLevel,
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrls[activeTileStyle]!,
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.moviemax_flutter',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [amrPos, tfaPos],
                    color: settings.primaryColor,
                    strokeWidth: 3.5,
                    isDotted: true,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Marker amrhdla
                  Marker(
                    point: amrPos,
                    width: 90,
                    height: 90,
                    child: GestureDetector(
                      onTap: () => _showLocationDetailModal('amrhdla', _amrhdlaData!, settings),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: settings.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                            ),
                            child: Text(
                              'amrhdla ${currentUser == 'amrhdla' ? '(Saya)' : ''}',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: settings.primaryColor,
                            child: const Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Marker tfauzyy
                  Marker(
                    point: tfaPos,
                    width: 90,
                    height: 90,
                    child: GestureDetector(
                      onTap: () => _showLocationDetailModal('tfauzyy', _tfauzyyData!, settings),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: settings.accentColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                            ),
                            child: Text(
                              'tfauzyy ${currentUser == 'tfauzyy' ? '(Saya)' : ''}',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: settings.accentColor,
                            child: const Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Provider Metadata & Live Distance Floating Header (Top)
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: settings.surfaceColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: settings.cardBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: settings.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.cell_tower_rounded, color: settings.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Provider: ${myData.ispName}',
                              style: GoogleFonts.outfit(
                                color: settings.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Sumber: ${myData.providerType} • ${myData.cityName}',
                              style: GoogleFonts.inter(
                                color: settings.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: settings.cardBorderColor, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        settings.tr('distance_between'),
                        style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 12),
                      ),
                      Text(
                        '${liveDistance.toStringAsFixed(2)} km',
                        style: GoogleFonts.outfit(
                          color: settings.warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Zoom Controls (Right)
          Positioned(
            right: 14,
            top: 130,
            child: Column(
              children: [
                _buildMapButton(icon: Icons.add_rounded, tooltip: 'Zoom In', onTap: _zoomIn, settings: settings),
                const SizedBox(height: 8),
                _buildMapButton(icon: Icons.remove_rounded, tooltip: 'Zoom Out', onTap: _zoomOut, settings: settings),
                const SizedBox(height: 8),
                _buildMapButton(icon: Icons.my_location_rounded, tooltip: settings.tr('map_my_location'), onTap: () => _focusTo(myData.position), settings: settings),
              ],
            ),
          ),

          // Quick Focus Navigation Buttons (Bottom)
          Positioned(
            bottom: 16,
            left: 14,
            right: 14,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _focusTo(amrPos),
                    icon: const Icon(Icons.location_on_rounded, size: 16, color: Colors.white),
                    label: Text(
                      settings.tr('focus_amrhdla'),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: settings.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _focusTo(tfaPos),
                    icon: const Icon(Icons.location_on_rounded, size: 16, color: Colors.white),
                    label: Text(
                      settings.tr('focus_tfauzyy'),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: settings.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required SettingsProvider settings,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: settings.surfaceColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: settings.cardBorderColor),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: IconButton(
        icon: Icon(icon, color: settings.textPrimaryColor, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  void _showLocationDetailModal(String username, UserLocationData data, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: settings.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: username == 'amrhdla' ? settings.primaryColor : settings.accentColor,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.outfit(color: settings.textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Kota/Wilayah: ${data.cityName}',
                      style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Deteksi Sumber', data.providerType, Icons.sensors, settings),
            const SizedBox(height: 10),
            _buildDetailRow('Nama Provider/ISP', data.ispName, Icons.cell_tower, settings),
            const SizedBox(height: 10),
            _buildDetailRow('Koordinat Real GPS', '${data.position.latitude.toStringAsFixed(5)}, ${data.position.longitude.toStringAsFixed(5)}', Icons.my_location, settings),
            const SizedBox(height: 10),
            _buildDetailRow('Akurasi Posisi', '${data.accuracy.toStringAsFixed(0)} meter', Icons.verified, settings),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final callProvider = Provider.of<CallProvider>(context, listen: false);
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      callProvider.startCall(caller: authProvider.userName, receiver: username, type: CallType.voice);
                    },
                    icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                    label: Text('Voice Call', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final callProvider = Provider.of<CallProvider>(context, listen: false);
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      callProvider.startCall(caller: authProvider.userName, receiver: username, type: CallType.video);
                    },
                    icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                    label: Text('Video Call', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: settings.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String val, IconData icon, SettingsProvider settings) {
    return Row(
      children: [
        Icon(icon, color: settings.primaryColor, size: 18),
        const SizedBox(width: 10),
        Text('$title: ', style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 13)),
        Expanded(
          child: Text(
            val,
            style: GoogleFonts.inter(color: settings.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
