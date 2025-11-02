import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/services/notification_service.dart';
import 'package:siaga_banjir/themes/colors.dart';
import 'home_page.dart';
import 'panduan_page.dart';
import 'peta_page.dart';

class MainScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MainScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _dataSubscription;
  String? _lastNotifiedStatus;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _setupFirebaseListener(); // 🔹 Jalankan listener sensor
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupFirebaseListener() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'admin123',
        );
        print("✅ Login Firebase berhasil di MainScreen");
      }

      // 🔹 Dengarkan data sensor dari Firebase
      _dataSubscription = _dbRef.child('Sensor').onValue.listen((event) {
        final data = event.snapshot.value;
        print("📡 Data Realtime DB diterima: $data");

        if (data != null && data is Map) {
          double waterLevel = ((data['WaterLevel'] ?? 0) as num).toDouble();
          double ultrasonic = ((data['Ultrasonic'] ?? 0) as num).toDouble();

          double ketinggianUntukNotifikasi = (waterLevel >= 50)
              ? ultrasonic
              : 0;

          _checkFloodStatusAndNotify(ketinggianUntukNotifikasi);

          print(
            "✅ Ketinggian untuk notifikasi: ${ketinggianUntukNotifikasi.toStringAsFixed(1)} cm",
          );
        } else {
          print("⚠️ Data Realtime DB kosong atau format salah");
        }
      });
    } catch (e) {
      print("❌ Error setup listener di MainScreen: $e");
    }
  }

  void _checkFloodStatusAndNotify(double level) {
    print(
      "--- Menganalisa Level: $level | Status Notif Terakhir: $_lastNotifiedStatus ---",
    );

    String currentStatus;
    String title = "Peringatan Banjir!";
    String body = "";

    if (level >= 100) {
      currentStatus = "Bahaya";
      body =
          "Status ketinggian air BAHAYA (${level.toStringAsFixed(1)} cm). Segera evakuasi diri!";
    } else if (level >= 50) {
      currentStatus = "Waspada";
      body =
          "Status ketinggian air WASPADA (${level.toStringAsFixed(1)} cm). Siapkan diri untuk kemungkinan terburuk.";
    } else {
      currentStatus = "Aman";
    }

    print("Status saat ini: '$currentStatus'");

    if (currentStatus != "Aman" && currentStatus != _lastNotifiedStatus) {
      print("✅ Notifikasi dikirim!");
      NotificationService().showNotification(title, body);
      _lastNotifiedStatus = currentStatus;
    } else if (currentStatus == "Aman") {
      print("ℹ️ Kondisi Aman, reset status notifikasi");
      _lastNotifiedStatus = "Aman";
    } else {
      print("⚠️ Tidak ada perubahan status, notifikasi tidak dikirim.");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildNavItem({
    required int index,
    required String label,
    required String primaryIcon,
    required String secondaryIcon,
  }) {
    final bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Center(
        child: Image.asset(
          isSelected ? primaryIcon : secondaryIcon,
          width: 28,
          height: 28,
        ),
      ),
      activeIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(primaryIcon, width: 28, height: 28),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      label: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Daftar halaman, HomePage menerima lokasi dari SplashScreen
    final List<Widget> _screens = [
      HomePage(latitude: widget.latitude, longitude: widget.longitude),
      const PetaPage(),
      const PanduanPage(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        selectedLabelStyle: GoogleFonts.quicksand(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: GoogleFonts.quicksand(fontSize: 12),
        items: [
          _buildNavItem(
            index: 0,
            label: "Beranda",
            primaryIcon: 'assets/images/icon/beranda-primary.png',
            secondaryIcon: 'assets/images/icon/beranda-secondary.png',
          ),
          _buildNavItem(
            index: 1,
            label: "Peta",
            primaryIcon: 'assets/images/icon/peta-primary.png',
            secondaryIcon: 'assets/images/icon/peta-secondary.png',
          ),
          _buildNavItem(
            index: 2,
            label: "Panduan",
            primaryIcon: 'assets/images/icon/panduan-primary.png',
            secondaryIcon: 'assets/images/icon/panduan-secondary.png',
          ),
        ],
      ),
    );
  }
}
