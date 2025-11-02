import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/main_screen.dart';
import 'package:siaga_banjir/themes/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 🔔

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin(); // 🔔

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      print("🚀 Memulai inisialisasi aplikasi...");

      // 🔔 Minta izin notifikasi (Android 13+ wajib)
      await _requestNotificationPermission();

      // 🧭 Cek dan minta izin lokasi
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showPermissionDialog();
        return;
      }

      // 🌍 Ambil lokasi pengguna
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lon = position.longitude;
      print("📍 Lokasi pengguna: ($lat, $lon)");

      // 🌦️ Kirim ke server Flask untuk prediksi cuaca
      final response = await http.post(
        Uri.parse("http://<IP_SERVER>:5000/prediksi"), // 🔧 ganti IP_SERVER
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"lat": lat, "lon": lon}),
      );

      print("🌦️ Response server: ${response.statusCode}");

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              latitude: lat,
              longitude: lon,
              selectedDeviceKey: 'alat1',
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Error in SplashScreen: $e");

      // 🧭 Jika gagal ambil lokasi, pakai default koordinat
      double defaultLat = -5.1767;
      double defaultLon = 119.4286;

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              latitude: defaultLat,
              longitude: defaultLon,
              selectedDeviceKey: 'alat1',
            ),
          ),
        );
      }
    }
  }

  // 🔔 Fungsi minta izin notifikasi
  Future<void> _requestNotificationPermission() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final bool? granted = await androidImplementation
        ?.requestNotificationsPermission();
    print("🔔 Izin notifikasi: ${granted == true ? 'DISETUJUI' : 'DITOLAK'}");
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Izin Lokasi Diperlukan"),
        content: const Text(
          "Aplikasi memerlukan izin lokasi untuk menampilkan data cuaca dan peta. "
          "Aktifkan izin lokasi melalui pengaturan perangkat Anda.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text("Buka Pengaturan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo/white.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            Text(
              'Siaga Banjir',
              style: GoogleFonts.quicksand(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sistem Peringatan Dini Banjir',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
