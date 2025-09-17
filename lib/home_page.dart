import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/cuaca_page.dart';
import 'package:siaga_banjir/themes/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // cek apakah GPS nyala
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception("GPS tidak aktif");
  }

  // cek izin
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

  // ambil posisi sekarang
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

class _HomePageState extends State<HomePage> {
  final String _locationName = 'Jembatan Kembar Gowa';
  final String _connectionStatus = 'Online';
  final int _batteryPercentage = 86;

  // Dummy Sumber Daya
  final int dummyHour = 16;

  // final String _powerSource =
  //     DateTime.now().hour >= 6 && DateTime.now().hour < 18
  //     ? 'Solar Panel'
  //     : 'Baterai';

  // final String _powerImage =
  //     DateTime.now().hour >= 6 && DateTime.now().hour < 18
  //     ? 'assets/images/solar-panel.png'
  //     : 'assets/images/battery.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildWaterLevelCard(
                        level: "50 cm",
                        description: "Air Stabil",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        status: "Bahaya",
                        lastUpdated: "2 menit yang lalu",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CuacaSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    final String _powerSource = dummyHour >= 6 && dummyHour < 18
        ? 'Solar Panel'
        : 'Baterai';

    final String _powerImage = dummyHour >= 6 && dummyHour < 18
        ? 'assets/images/solar-panel.png'
        : 'assets/images/battery.png';
    return Container(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
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
          scale: 1,
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
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Siaga Banjir',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
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
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                _locationName,
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '$_batteryPercentage%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    title,
                    style: GoogleFonts.quicksand(
                      color: AppColors.text,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    value,
                    style: GoogleFonts.quicksand(
                      color: valueColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
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

  Widget _buildWaterLevelCard({
    required String level,
    required String description,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ketinggian Air,",
            style: GoogleFonts.quicksand(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                level,
                style: GoogleFonts.quicksand(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(width: 6),
              Icon(getArrowIcon("stabil"), size: 16, color: AppColors.text),
            ],
          ),

          const Spacer(),
          Text(
            description,
            style: GoogleFonts.quicksand(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  IconData getArrowIcon(String status) {
    switch (status.toLowerCase()) {
      case "naik":
        return Icons.north;
      case "stabil":
        return Icons.east;
      case "turun":
        return Icons.south;
      default:
        return Icons.help_outline;
    }
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: GoogleFonts.quicksand(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            "Diperbarui $lastUpdated",
            style: GoogleFonts.quicksand(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
