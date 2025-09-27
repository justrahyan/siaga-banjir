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
  const MainScreen({super.key});

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
    _setupFirebaseListener(); // Panggil listener saat state dimulai
  }

  @override
  void dispose() {
    _dataSubscription?.cancel(); // Hentikan listener saat widget dihancurkan
    super.dispose();
  }

  Future<void> _setupFirebaseListener() async {
    try {
      // 1. Login terlebih dahulu (seperti di kode home_page Anda)
      // Pastikan user belum login untuk menghindari error
      if (_auth.currentUser == null) {
        await _auth.signInWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'admin123',
        );
        print("✅ Login berhasil di MainScreen");
      }

      // 2. Setup listener ke path 'Sensor'
      _dataSubscription = _dbRef.child('Sensor').onValue.listen((event) {
        final data = event.snapshot.value;
        print("📡 Data Realtime DB diterima: $data");

        if (data != null && data is Map) {
          // Ambil data dan konversi ke double
          double waterLevel = ((data['WaterLevel'] ?? 0) as num).toDouble();
          double ultrasonic = ((data['Ultrasonic'] ?? 0) as num).toDouble();

          // Terapkan logika yang sama: ultrasonic aktif jika waterLevel >= 50
          double ketinggianUntukNotifikasi = (waterLevel >= 50)
              ? ultrasonic
              : 0;

          // Panggil fungsi pengecekan status untuk mengirim notifikasi
          _checkFloodStatusAndNotify(ketinggianUntukNotifikasi);

          print(
            "✅ Ketinggian untuk notifikasi: ${ketinggianUntukNotifikasi.toStringAsFixed(1)} cm",
          );
        } else {
          print("⚠️ Data Realtime DB kosong atau format salah");
        }
      });
    } catch (e) {
      print("❌ Error saat setup listener di MainScreen: $e");
    }
  }

  // Fungsi ini tetap sama, tidak perlu diubah
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

    print("Status saat ini dihitung sebagai: '$currentStatus'");

    // Kirim notifikasi HANYA jika status berubah menjadi lebih buruk
    if (currentStatus != "Aman" && currentStatus != _lastNotifiedStatus) {
      print("✅ KONDISI TERPENUHI! Memicu pengiriman notifikasi...");
      NotificationService().showNotification(title, body);
      // Simpan status terakhir yang dinotifikasi (tidak perlu setState karena tidak update UI)
      _lastNotifiedStatus = currentStatus;
    } else if (currentStatus == "Aman") {
      print("ℹ️ Kondisi Aman. Status notifikasi direset.");
      // Reset status jika sudah aman
      _lastNotifiedStatus = "Aman";
    } else {
      // --- DEBUG START ---
      print(
        "⚠️ Kondisi tidak terpenuhi. Alasan: Status masih sama ('$currentStatus') atau Aman.",
      );
      // --- DEBUG END ---
    }
  }

  final List<Widget> _screens = const [HomePage(), PetaPage(), PanduanPage()];

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
          // _buildNavItem(
          //   index: 2,
          //   label: "Riwayat",
          //   primaryIcon: 'assets/images/icon/riwayat-primary.png',
          //   secondaryIcon: 'assets/images/icon/riwayat-secondary.png',
          // ),
        ],
      ),
    );
  }
}
