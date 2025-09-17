import 'dart:convert';
import 'package:flutter/material.dart';
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
  final bool isToday; // 🔥 tambah flag hari ini

  const CuacaCard({
    super.key,
    required this.icon,
    required this.suhu,
    required this.kondisi,
    required this.angin,
    required this.kelembapan,
    required this.waktu,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary : Colors.grey[800],
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
              Image.asset(icon, width: 84, height: 84),
              const SizedBox(width: 12),
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
  final String kodeWilayah; // contoh: "31.71.03.1001"

  const CuacaSection({super.key, required this.kodeWilayah});

  @override
  State<CuacaSection> createState() => _CuacaSectionState();
}

class _CuacaSectionState extends State<CuacaSection> {
  List<dynamic> prakiraan = [];

  @override
  void initState() {
    super.initState();
    fetchCuaca();
  }

  Future<void> fetchCuaca() async {
    final url =
        "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=${widget.kodeWilayah}";
    print("📡 Fetching from: $url");

    try {
      final res = await http.get(Uri.parse(url));
      print("📥 Status Code: ${res.statusCode}"); // Debugging status

      if (res.statusCode == 200) {
        print("📥 Response Body: ${res.body.substring(0, 200)}...");
        // hanya tampilkan 200 karakter pertama biar ga kepanjangan

        final data = jsonDecode(res.body);
        print("✅ Parsed JSON: $data");

        final List rawData = data["data"] ?? [];
        List<dynamic> extracted = [];

        if (rawData.isNotEmpty && rawData[0]["cuaca"] != null) {
          // Flatten biar gampang dipakai di ListView
          for (var entry in rawData[0]["cuaca"]) {
            if (entry is List && entry.isNotEmpty) {
              extracted.add(entry[0]);
            }
          }
        }

        setState(() {
          prakiraan = extracted;
        });

        print("🌤️ Jumlah data cuaca: ${prakiraan.length}");
      } else {
        print("❌ Error: status ${res.statusCode}, body=${res.body}");
      }
    } catch (e) {
      print("🔥 Exception in fetchCuaca: $e");
    }
  }

  String getIcon(String desc) {
    if (desc.contains("Hujan")) return "assets/images/icon/cuaca/rain.png";
    if (desc.contains("Cerah")) return "assets/images/icon/cuaca/sunny.png";
    if (desc.contains("Berawan")) return "assets/images/icon/cuaca/cloudy.png";
    if (desc.contains("Badai")) {
      return "assets/images/icon/cuaca/thunder.png";
    }
    return "assets/images/icon/cuaca/cloud_and_rainny.png";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Prakiraan Cuaca",
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: prakiraan.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                )
              : PageView.builder(
                  controller: PageController(viewportFraction: 0.95),
                  itemCount: prakiraan.length,
                  itemBuilder: (context, index) {
                    final item = prakiraan[index];
                    final waktu = item["local_datetime"].toString();

                    return CuacaCard(
                      icon: getIcon(item["weather_desc"] ?? ""),
                      suhu: item["t"].toString(),
                      kondisi: item["weather_desc"] ?? "",
                      angin: "${item["ws"]} km/h",
                      kelembapan: item["hu"].toString(),
                      waktu: waktu,
                      isToday: index == 0, // card pertama dianggap hari ini
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              "Sumber: ",
              style: TextStyle(fontSize: 10, color: AppColors.text),
            ),
            SizedBox(width: 4),
            SizedBox(
              height: 16,
              child: Image.asset("assets/images/logo/logo-bmkg.png"),
            ),
          ],
        ),
      ],
    );
  }
}
