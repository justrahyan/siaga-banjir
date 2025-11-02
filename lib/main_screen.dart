import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  final String selectedDeviceKey;

  const MainScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.selectedDeviceKey,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _dataSubscription;
  String? _lastNotifiedStatus;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://siaga-banjir-b73a8-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  @override
  void initState() {
    super.initState();
    _setupFirebaseListener();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupFirebaseListener() async {
    try {
      print("🚀 [INIT] Mulai setup listener Firebase...");

      if (_auth.currentUser == null) {
        print("🔑 [AUTH] Belum login, mencoba login admin...");
        await _auth.signInWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'admin123',
        );
        print("✅ [AUTH] Login Firebase berhasil di MainScreen");
      } else {
        print("ℹ️ [AUTH] Sudah login sebagai: ${_auth.currentUser!.email}");
      }

      print(
        "🎧 [DB] Mulai mendengarkan node: /Alat/${widget.selectedDeviceKey}",
      );

      // Dengarkan semua alat dalam node Alat
      _dataSubscription = _dbRef
          .child('Alat/${widget.selectedDeviceKey}/Sensor')
          .onValue
          .listen(
            (event) {
              final data = event.snapshot.value;
              print("📡 [DB] Data alat ${widget.selectedDeviceKey}: $data");

              if (data != null && data is Map) {
                double waterLevel = ((data['WaterLevel'] ?? 0) as num)
                    .toDouble();
                double ultrasonic = ((data['Ultrasonic'] ?? 0) as num)
                    .toDouble();

                _checkFloodStatusAndNotify(
                  widget.selectedDeviceKey,
                  ultrasonic,
                  waterLevel,
                );
              } else {
                print("⚠️ [DB] Data kosong atau format salah");
              }
            },
            onError: (error) {
              print("❌ [DB] Error membaca data: $error");
            },
          );

      print("✅ [LISTENER] Listener Firebase aktif!");
    } catch (e) {
      print("❌ [SETUP] Gagal setup listener: $e");
    }
  }

  void _checkFloodStatusAndNotify(
    String alatKey,
    double ultrasonic,
    double waterLevel,
  ) async {
    print("🧠 [ANALISIS-$alatKey] UL: $ultrasonic | WL: $waterLevel");

    String currentStatus;
    String title = "Peringatan Banjir!";
    String body = "";

    // === Logika status banjir (sesuai home_page.dart) ===
    if (waterLevel < 100 || ultrasonic <= 30) {
      currentStatus = "Aman";
    } else if (ultrasonic <= 70) {
      currentStatus = "Waspada";
      body =
          "Status WASPADA di $alatKey (${waterLevel.toStringAsFixed(1)} cm). Tetap siaga!";
    } else {
      currentStatus = "Bahaya";
      body =
          "Status BAHAYA di $alatKey (${waterLevel.toStringAsFixed(1)} cm). Segera evakuasi!";
    }

    print("📊 [STATUS-$alatKey] Sekarang: $currentStatus");

    // === Kirim notifikasi jika berubah ===
    if (currentStatus != "Aman" && currentStatus != _lastNotifiedStatus) {
      print("📣 [NOTIF-$alatKey] Mengirim notifikasi lokal...");
      try {
        await NotificationService().showNotification(title, body);
        print("✅ [NOTIF-$alatKey] Notifikasi berhasil dikirim!");
      } catch (e) {
        print("❌ [NOTIF-$alatKey] Gagal kirim notifikasi: $e");
      }
      _lastNotifiedStatus = currentStatus;
    } else if (currentStatus == "Aman") {
      print("ℹ️ [RESET-$alatKey] Kondisi aman, reset status notifikasi");
      _lastNotifiedStatus = "Aman";
    } else {
      print("⚠️ [SKIP-$alatKey] Tidak ada perubahan status.");
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
