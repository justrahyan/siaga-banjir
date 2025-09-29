import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:siaga_banjir/components/bottom_sheet.dart';
import 'package:siaga_banjir/components/cuaca_card.dart';
import 'package:siaga_banjir/themes/colors.dart';

// 🛰️ Ambil lokasi pengguna
Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw Exception("GPS tidak aktif");

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception("Izin lokasi ditolak");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception("Izin lokasi permanen ditolak");
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _locationName = 'Jembatan Kembar Gowa';
  final String _connectionStatus = 'Online';
  final int _batteryPercentage = 43;
  final int dummyHour = 12;

  // --- Variabel Sensor ---
  double? _waterLevel;
  double? _ultrasonic;
  bool _isLoading = true;
  String _lastUpdated = "Menunggu data...";
  double? _previousWaterLevel;

  // --- Firebase ---
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://siaga-banjir-b73a8-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  StreamSubscription? _sensorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: 'admin@gmail.com',
        password: 'admin123',
      );
      print("✅ Firebase login berhasil");

      final dbRef = _database;

      _sensorSubscription = dbRef.child('Sensor').onValue.listen((event) {
        final data = event.snapshot.value;
        print("📡 Data diterima: $data");

        if (data != null && data is Map) {
          double waterLevel = ((data['WaterLevel'] ?? 0) as num).toDouble();
          double ultrasonic = ((data['Ultrasonic'] ?? 0) as num).toDouble();

          if (ultrasonic < 0) ultrasonic = 0;

          // Ultrasonic aktif hanya jika waterLevel >= 50
          double ketinggian = (waterLevel >= 50) ? ultrasonic : 0;

          setState(() {
            _waterLevel = waterLevel;
            _ultrasonic = ketinggian;
            _lastUpdated = "Baru saja diperbarui";
            _isLoading = false;
          });

          print(
            "✅ WaterLevel: $_waterLevel cm | Ultrasonic: $_ultrasonic cm (aktif jika >=50)",
          );
        } else {
          print("⚠️ Data kosong atau format salah");
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      print("❌ Firebase error: $e");
      setState(() => _isLoading = false);
    }
  }

  String getTrend(double? currentLevel) {
    if (currentLevel == null) return "stabil";
    String trend = "stabil";
    if (_previousWaterLevel != null) {
      if (currentLevel > _previousWaterLevel! + 0.1) trend = "naik";
      if (currentLevel < _previousWaterLevel! - 0.1) trend = "turun";
    }
    _previousWaterLevel = currentLevel;
    return trend;
  }

  String getFloodStatus(double? ultrasonic, double? waterLevel) {
    if (ultrasonic == null || waterLevel == null) return "Tidak Diketahui";

    // 🔹 Jika waterLevel < 100 → sensor ultrasonic belum dipakai
    if (waterLevel < 100) {
      ultrasonic = 0;
      return "Aman";
    }

    // 🔹 Jika waterLevel >= 100 → cek ultrasonic
    if (ultrasonic >= 0 && ultrasonic <= 30) {
      return "Aman";
    } else if (ultrasonic > 30 && ultrasonic <= 70) {
      return "Waspada";
    } else if (ultrasonic > 70) {
      return "Bahaya";
    }

    return "Tidak Diketahui";
  }

  IconData getArrowIcon(String trend) {
    switch (trend) {
      case "naik":
        return Icons.north;
      case "turun":
        return Icons.south;
      default:
        return Icons.east;
    }
  }

  double getResponsiveSize(
    BuildContext context,
    double small,
    double medium,
    double large,
  ) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 320) return small;
    if (width <= 480) return medium;
    return large;
  }

  @override
  Widget build(BuildContext context) {
    final String currentTrend = getTrend(_ultrasonic);
    final String currentStatus = getFloodStatus(_ultrasonic, _waterLevel);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isLoading
                    ? Row(
                        children: [
                          Expanded(child: _buildLoadingCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildLoadingCard()),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildWaterLevelCard(
                              level:
                                  "${_ultrasonic?.toStringAsFixed(1) ?? '--'} cm",
                              trend: currentTrend,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatusCard(
                              status: currentStatus,
                              lastUpdated: _lastUpdated,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // child: CuacaSection(), // Openweathermap
                child: CuacaSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildWaterLevelCard({required String level, required String trend}) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ketinggian Air,",
            style: GoogleFonts.quicksand(
              fontSize: getResponsiveSize(context, 12, 14, 16),
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    level,
                    overflow:
                        TextOverflow.ellipsis, // ⬅️ biar angka panjang dipotong
                    style: GoogleFonts.quicksand(
                      fontSize: getResponsiveSize(context, 22, 24, 26),
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                getArrowIcon(trend),
                size: getResponsiveSize(
                  context,
                  14,
                  16,
                  18,
                ), // ⬅️ ikut responsive
                color: AppColors.text,
              ),
            ],
          ),

          const Spacer(),
          Text(
            "Tren air: $trend",
            style: GoogleFonts.quicksand(
              fontSize: getResponsiveSize(context, 10, 12, 14),
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String status,
    required String lastUpdated,
  }) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case "Aman":
        bgColor = AppColors.bgAman;
        textColor = AppColors.textAman;
        break;
      case "Waspada":
        bgColor = AppColors.bgWaspada;
        textColor = AppColors.textWaspada;
        break;
      case "Bahaya":
        bgColor = AppColors.bgBahaya;
        textColor = AppColors.textBahaya;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
    }
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: GoogleFonts.quicksand(
              fontSize: getResponsiveSize(context, 22, 24, 26),
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            "Diperbarui $lastUpdated",
            style: GoogleFonts.quicksand(
              fontSize: getResponsiveSize(context, 10, 12, 14),
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String _powerSource = dummyHour >= 6 && dummyHour < 18
        ? 'Solar Panel'
        : 'Baterai';
    final String _powerImage = dummyHour >= 6 && dummyHour < 18
        ? 'assets/images/solar-panel.png'
        : 'assets/images/battery.png';

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/pattern.png'),
          fit: BoxFit.none,
          alignment: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo/white.png',
                width: 38,
                height: 38,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang di',
                    style: GoogleFonts.quicksand(
                      color: Colors.white70,
                      fontSize: getResponsiveSize(context, 12, 14, 16),
                    ),
                  ),
                  Text(
                    'Siaga Banjir',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: getResponsiveSize(context, 12, 14, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Lokasi',
            style: GoogleFonts.quicksand(
              color: Colors.white70,
              fontSize: getResponsiveSize(context, 12, 14, 16),
            ),
          ),
          Row(
            children: [
              Text(
                _locationName,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: getResponsiveSize(context, 14, 16, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '$_batteryPercentage%',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: getResponsiveSize(context, 10, 12, 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDeviceStatusCard(
                  title: 'Status Koneksi,',
                  value: _connectionStatus,
                  imagePath: 'assets/images/internet.png',
                  valueColor: AppColors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDeviceStatusCard(
                  title: 'Sumber Daya,',
                  value: _powerSource,
                  imagePath: _powerImage,
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                showDeviceDetail(
                  context,
                  connectionStatus: _connectionStatus,
                  powerSource: _powerSource,
                  batteryPercentage: _batteryPercentage,
                );
              },
              child: Text(
                "Lihat Detail",
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard({
    required String title,
    required String value,
    required String imagePath,
    required Color valueColor,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
              top: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    color: AppColors.text,
                    fontSize: getResponsiveSize(context, 12, 14, 16),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  child: Text(
                    value,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.quicksand(
                      color: valueColor,
                      fontSize: getResponsiveSize(context, 16, 18, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
