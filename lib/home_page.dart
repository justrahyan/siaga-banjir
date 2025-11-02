import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:siaga_banjir/components/bottom_sheet.dart';
import 'package:siaga_banjir/components/cuaca_card.dart';
import 'package:siaga_banjir/themes/colors.dart';
import 'package:intl/intl.dart';

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
  final double latitude;
  final double longitude;

  const HomePage({super.key, required this.latitude, required this.longitude});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://siaga-banjir-b73a8-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  StreamSubscription? _alatSubscription;

  // === Variabel Data ===
  final Map<String, String> _deviceList = {};
  String? _selectedDeviceKey;
  String? _deviceName;
  bool? _isConnected;
  bool? _isSolarPower;
  double? _waterLevel;
  double? _ultrasonic;
  double? _previousWaterLevel;
  String _lastUpdated = "Menunggu data...";
  bool _isLoading = true;
  int _batteryPercentage = 100;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  @override
  void dispose() {
    _alatSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    try {
      // 1. Login (Sama seperti sebelumnya)
      if (_auth.currentUser == null) {
        await _auth.signInWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'admin123',
        );
      }
      print("✅ Firebase login berhasil");

      // 2. Ambil DAFTAR SEMUA ALAT (hanya sekali)
      final deviceListSnapshot = await _database.child('Alat').once();
      if (deviceListSnapshot.snapshot.value == null) {
        print("❌ Tidak ada data 'Alat' ditemukan");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 3. Proses daftar alat
      final allAlatData = Map<String, dynamic>.from(
        deviceListSnapshot.snapshot.value as Map,
      );
      _deviceList.clear();
      allAlatData.forEach((key, value) {
        final alatData = Map<String, dynamic>.from(value);
        final namaAlat = alatData['nama_alat'] as String?;
        if (namaAlat != null) {
          _deviceList[key] = namaAlat; // key: "alat1", value: "SiTanda"
        }
      });

      if (_deviceList.isEmpty) {
        print("❌ Tidak ada alat yang memiliki 'nama_alat'");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 4. Set alat pertama sebagai default
      setState(() {
        _selectedDeviceKey = _deviceList.keys.first;
        _isLoading = true; // Set loading true untuk ambil data alat pertama
      });

      // 5. Mulai dengarkan data alat yang dipilih
      _listenToDevice(_selectedDeviceKey!);
    } catch (e) {
      print("❌ Firebase error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToDevice(String deviceKey) {
    // Hentikan listener lama
    _alatSubscription?.cancel();
    print("🎧 Mulai mendengarkan data untuk $deviceKey...");

    _alatSubscription = _database
        .child('Alat/$deviceKey')
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value as Map?;
            if (data == null) {
              if (mounted) setState(() => _isLoading = false);
              return;
            }

            final sensor = data['Sensor'] as Map?;
            final double waterLevel = ((sensor?['WaterLevel'] ?? 0) as num)
                .toDouble();
            final double ultrasonic = ((sensor?['Ultrasonic'] ?? 0) as num)
                .toDouble();

            final now = DateTime.now();
            final currentTime = DateFormat('HH:mm').format(now);
            final bool isSolar = _checkSolarTime(currentTime);

            final dynamic koneksiData = data['koneksi'];
            final bool isKoneksiOn =
                (koneksiData == true || koneksiData == 'true');
            if (mounted) {
              setState(() {
                _deviceName = data['nama_alat'];
                _isConnected =
                    (data['koneksi'] == true || data['koneksi'] == 'true');
                _isSolarPower = isSolar;
                _waterLevel = waterLevel;
                _ultrasonic = ultrasonic;
                _batteryPercentage = getBatteryLevel();
                _lastUpdated = "Baru saja diperbarui";
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            print("❌ Error mendengarkan $deviceKey: $error");
            if (mounted) setState(() => _isLoading = false);
          },
        );
  }

  // 🔆 Cek waktu untuk sumber daya
  bool _checkSolarTime(String currentTime) {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 6, 30);
    final evening = DateTime(now.year, now.month, now.day, 18, 0);
    return now.isAfter(morning) && now.isBefore(evening);
  }

  // 🔋 Hitung level baterai (malam berkurang tiap jam)
  int getBatteryLevel() {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 6, 30);
    final evening = DateTime(now.year, now.month, now.day, 18, 1);
    if (now.isAfter(evening) || now.isBefore(morning)) {
      DateTime startDischarge = now.isAfter(evening)
          ? evening
          : DateTime(now.year, now.month, now.day - 1, 18, 1);
      int hoursPassed = now.difference(startDischarge).inHours;
      int percentage = 100 - (hoursPassed * 5);
      return percentage.clamp(0, 100);
    } else {
      return 100;
    }
  }

  // 🌊 Status banjir berdasarkan sensor
  String getFloodStatus(double? ultrasonic, double? waterLevel) {
    if (ultrasonic == null || waterLevel == null) return "Tidak Diketahui";
    if (waterLevel < 100) return "Aman";
    if (ultrasonic <= 30) return "Aman";
    if (ultrasonic <= 70) return "Waspada";
    return "Bahaya";
  }

  // 📈 Cek tren air
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

  // 📱 Responsive ukuran font
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
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CuacaSection(
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                ),
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

  // 💧 Card Ketinggian Air
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
                size: getResponsiveSize(context, 14, 16, 18),
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

  // 🌧️ Card Status Banjir
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

  // 🧭 Header Utama
  Widget _buildHeader() {
    final String _powerSource = _isSolarPower == true
        ? 'Solar Panel'
        : 'Baterai';
    final String _powerImage = _isSolarPower == true
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
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Siaga Banjir',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Nama Alat',
            style: GoogleFonts.quicksand(color: Colors.white70),
          ),
          Row(
            children: [
              if (_deviceList.isNotEmpty && _selectedDeviceKey != null)
                PopupMenuButton<String>(
                  // Ini adalah tampilan widget (Teks + Ikon)
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        // Tampilkan nama alat yg dipilih, atau "Memuat..."
                        _deviceName ??
                            _deviceList[_selectedDeviceKey] ??
                            'Memuat...',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                  // Ini adalah daftar item di menu dropdown
                  itemBuilder: (BuildContext context) {
                    return _deviceList.entries.map((entry) {
                      return PopupMenuItem<String>(
                        value: entry.key, // "alat1"
                        child: Text(
                          entry.value, // "SiTanda"
                          style: GoogleFonts.quicksand(),
                        ),
                      );
                    }).toList();
                  },
                  // Aksi saat item dipilih
                  onSelected: (String newKey) {
                    if (newKey != _selectedDeviceKey) {
                      setState(() {
                        _isLoading = true;
                        _selectedDeviceKey = newKey;
                        _deviceName = 'Tidak diketahui';
                        _isConnected = false;
                        _waterLevel = null;
                        _ultrasonic = null;
                      });
                      _listenToDevice(newKey);
                    }
                  },
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              // Tampilkan placeholder jika masih loading atau tidak ada alat
              else
                Text(
                  _isLoading ? 'Memuat alat...' : '-',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              const Spacer(),
              if (_isSolarPower == false)
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
                  title: 'Status Koneksi',
                  value: _isConnected == true ? 'Online' : 'Offline',
                  imagePath: 'assets/images/internet.png',
                  valueColor: _isConnected == true
                      ? AppColors.green
                      : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDeviceStatusCard(
                  title: 'Sumber Daya',
                  value: _powerSource,
                  imagePath: _powerImage,
                  valueColor: _isSolarPower == true
                      ? AppColors.primary
                      : AppColors.orange,
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
                  connectionStatus: _isConnected == true ? 'Online' : 'Offline',
                  powerSource: _powerSource,
                  batteryPercentage: _batteryPercentage,
                  deviceName: _deviceName ?? '-',
                );
              },
              child: Text(
                "Lihat Detail",
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.quicksand(color: AppColors.text),
                ),
                Text(
                  value,
                  style: GoogleFonts.quicksand(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
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
