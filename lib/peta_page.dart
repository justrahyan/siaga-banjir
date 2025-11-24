import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:siaga_banjir/themes/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class PetaPage extends StatefulWidget {
  const PetaPage({super.key});

  @override
  State<PetaPage> createState() => _PetaPageState();
}

class _PetaPageState extends State<PetaPage> {
  bool _isMapLoading = true;
  bool _showDetail = false;

  /// 🔧 DIUBAH: nullable, bukan late
  GoogleMapController? _controller;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://siaga-banjir-b73a8-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  LatLng? _userLocation;
  Map<String, dynamic>? _selectedAlat;
  final Map<String, Marker> _markers = {};
  StreamSubscription? _alatSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _alatSubscription?.cancel();

    /// 🔧 DIUBAH: cek null dulu
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      print("❌ Gagal mendapatkan lokasi pengguna: $e");
    }
  }

  /// 🔁 Listen data alat secara realtime
  void _listenRealtimeAlat() {
    _alatSubscription?.cancel();
    _alatSubscription = _db
        .child('Alat')
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value;
            if (data == null) {
              print(
                "⚠️ PetaPage: Tidak ada data alat di database (snapshot is null)",
              );
              if (mounted) setState(() => _markers.clear());
              return;
            }

            print("✅ PetaPage: Data diterima dari Firebase, memproses...");

            final alatMap = Map<String, dynamic>.from(data as Map);
            final Map<String, Marker> newMarkers = {};

            alatMap.forEach((key, value) {
              final alat = Map<String, dynamic>.from(value);
              if (alat['koordinat'] == null) {
                print("⚠️ Alat $key tidak punya koordinat");
                return;
              }

              final koordinat = Map<String, dynamic>.from(alat['koordinat']);
              if (koordinat['latitude'] == null ||
                  koordinat['longitude'] == null) {
                print("⚠️ Koordinat alat $key tidak lengkap");
                return;
              }

              final lat = (koordinat['latitude'] as num).toDouble();
              final lng = (koordinat['longitude'] as num).toDouble();

              print("📍 Menambahkan marker untuk $key ($lat, $lng)");

              newMarkers[key] = Marker(
                markerId: MarkerId(key),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
                infoWindow: InfoWindow(title: alat['nama_alat']),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _selectedAlat = alat;
                      _showDetail = true;
                    });
                  }
                },
              );
            });

            if (mounted) {
              setState(() {
                _markers
                  ..clear()
                  ..addAll(newMarkers);
              });
            }

            // 🔧 DIUBAH: pastikan controller tidak null & widget masih mounted
            if (_markers.isNotEmpty && mounted && _controller != null) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (!mounted || _controller == null) return;

                final bounds = _calculateBounds(
                  _markers.values.map((m) => m.position).toList(),
                );
                _controller!.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 80),
                );
              });
            }
          },
          onError: (error) {
            print("❌❌❌ PetaPage: GAGAL MENDENGARKAN DATA: $error");
          },
        );
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _refreshMap() async {
    if (!mounted) return;
    setState(() => _isMapLoading = true);
    _listenRealtimeAlat();
    if (mounted) setState(() => _isMapLoading = false);
  }

  bool _checkSolarTime() {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 6, 30);
    final evening = DateTime(now.year, now.month, now.day, 18, 0);
    return now.isAfter(morning) && now.isBefore(evening);
  }

  int _batteryLevel() {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 6, 30);
    final evening = DateTime(now.year, now.month, now.day, 18, 1);
    if (now.isAfter(evening) || now.isBefore(morning)) {
      final diff = now.difference(evening).inHours;
      int p = 100 - diff * 5;
      return p.clamp(0, 100);
    } else {
      return 100;
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _controller = controller; // 🔧 simpan controller

    try {
      if (_auth.currentUser == null) {
        print("🔐 PetaPage: Belum login, mencoba login admin...");
        await _auth.signInWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'admin123',
        );
        print("✅ PetaPage: Login admin berhasil.");
      } else {
        print("👍 PetaPage: Pengguna sudah login.");
      }

      _listenRealtimeAlat();
    } catch (e) {
      print("❌❌❌ PetaPage: GAGAL login atau inisialisasi: $e");
    }

    if (mounted) {
      setState(() => _isMapLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _userLocation ?? const LatLng(-5.1477, 119.4327);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Peta Lokasi",
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black26,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh, color: AppColors.primary),
        //     onPressed: _refreshMap,
        //   ),
        // ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 12),
            myLocationEnabled: true,
            markers: _markers.values.toSet(),
            onMapCreated: _onMapCreated,
            onTap: (_) => setState(() => _showDetail = false),
          ),
          if (_isMapLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Memuat peta...",
                    style: TextStyle(color: AppColors.text, fontSize: 12),
                  ),
                ],
              ),
            ),
          if (_showDetail && _selectedAlat != null) _buildDetailCard(),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    final alat = _selectedAlat!;
    final isSolar = _checkSolarTime();
    final battery = _batteryLevel();

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/prototype.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 8),
              Text(
                alat['nama_alat'] ?? "Tidak diketahui",
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    // 🔧 struktur di DB: koneksi ada di root alat, bukan di Sensor
                    alat['koneksi'] == true ? Icons.wifi : Icons.wifi_off,
                    color: alat['koneksi'] == true
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    alat['koneksi'] == true ? 'Online' : 'Offline',
                    style: GoogleFonts.quicksand(
                      color: alat['koneksi'] == true
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSolar ? Icons.solar_power : Icons.battery_charging_full,
                    color: isSolar ? Colors.orangeAccent : Colors.blueAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSolar ? 'Solar Panel' : 'Baterai',
                    style: GoogleFonts.quicksand(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isSolar)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        "$battery%",
                        style: GoogleFonts.quicksand(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _showDetail = false),
                child: const Text(
                  "Tutup",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
