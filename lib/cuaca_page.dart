import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'themes/colors.dart';

class CuacaCard extends StatelessWidget {
  final String icon;
  final String suhu;
  final String kondisi;
  final String angin;
  final String kelembapan;
  final String waktu;

  const CuacaCard({
    super.key,
    required this.icon,
    required this.suhu,
    required this.kondisi,
    required this.angin,
    required this.kelembapan,
    required this.waktu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            waktu,
            style: GoogleFonts.quicksand(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Image.asset(icon, width: 48, height: 48),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$suhu°C",
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    kondisi,
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.air, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    angin,
                    style: GoogleFonts.quicksand(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.water_drop, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    "$kelembapan%",
                    style: GoogleFonts.quicksand(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CuacaSection extends StatefulWidget {
  const CuacaSection({super.key});

  @override
  State<CuacaSection> createState() => _CuacaSectionState();
}

class _CuacaSectionState extends State<CuacaSection> {
  List<dynamic> prakiraan = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getLocationAndFetch();
  }

  Future<void> getLocationAndFetch() async {
    try {
      // Minta izin lokasi
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("❌ Lokasi ditolak user");
        setState(() {
          loading = false;
        });
        return;
      }

      // Ambil posisi user
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lon = position.longitude;

      print("📍 Lokasi user: lat=$lat, lon=$lon");

      // API BMKG cuaca by lat/lon
      final url =
          "https://api.bmkg.go.id/publik/prakiraan-cuaca?lat=$lat&lon=$lon";
      print("🔗 Request ke: $url");

      final res = await http.get(Uri.parse(url));
      print("📡 Status code: ${res.statusCode}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("📦 Response BMKG: $data");

        setState(() {
          prakiraan = data["data"] ?? [];
          print("✅ Jumlah data prakiraan: ${prakiraan.length}");
          loading = false;
        });
      } else {
        print("❌ Gagal fetch BMKG: ${res.body}");
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print("⚠️ Error fetchCuaca: $e");
      setState(() {
        loading = false;
      });
    }
  }

  String getIcon(String desc) {
    if (desc.contains("Hujan")) return "assets/images/icon/cuaca/rain.png";
    if (desc.contains("Cerah")) return "assets/images/icon/cuaca/sunny.png";
    if (desc.contains("Berawan")) return "assets/images/icon/cuaca/cloudy.png";
    if (desc.contains("Badai")) return "assets/images/icon/cuaca/thunder.png";
    return "assets/images/icon/cuaca/cloud_and_rainny.png";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : prakiraan.isEmpty
          ? const Center(child: Text("Data cuaca tidak tersedia"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: prakiraan.length,
              itemBuilder: (context, index) {
                final item = prakiraan[index];
                return CuacaCard(
                  icon: getIcon(item["weather_desc"] ?? ""),
                  suhu: item["t"].toString(),
                  kondisi: item["weather_desc"] ?? "",
                  angin: "${item["ws"]} km/h",
                  kelembapan: item["hu"].toString(),
                  waktu: item["local_datetime"].toString(),
                );
              },
            ),
    );
  }
}
