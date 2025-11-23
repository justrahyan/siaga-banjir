import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../themes/colors.dart';
import 'package:intl/intl.dart';

class CuacaCard extends StatelessWidget {
  final String icon;
  final String suhu;
  final String kondisi;
  final String angin;
  final String kelembapan;
  final String waktu;
  final bool isToday;

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
              Image.network(
                icon,
                width: 84,
                height: 84,
                errorBuilder: (ctx, err, stack) =>
                    const Icon(Icons.cloud, color: Colors.white, size: 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
              ),
            ],
          ),
          const Spacer(),
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
    );
  }
}

class CuacaSection extends StatefulWidget {
  // final double latitude;
  // final double longitude;
  final String kodeWilayah;
  const CuacaSection({super.key, required this.kodeWilayah});

  // const CuacaSection({
  //   super.key,
  //   required this.latitude,
  //   required this.longitude,
  // });

  @override
  State<CuacaSection> createState() => _CuacaSectionState();
}

class _CuacaSectionState extends State<CuacaSection> {
  List<dynamic> prakiraan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCuaca();
  }

  // 🔹 Ganti IP ini sesuai IP laptop kamu (lihat di cmd: ipconfig)
  String getBaseUrl() {
    if (Platform.isAndroid) {
      return "http://192.168.1.3:5000"; // ← ganti sesuai IP laptop kamu
    } else {
      return "http://10.0.2.2:5000"; // untuk emulator
    }
  }

  Future<void> fetchCuaca() async {
    final url =
        "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=${widget.kodeWilayah}";
    print("📡 Fetching from: $url");

    try {
      final res = await http.get(Uri.parse(url));
      print("📥 Status Code: ${res.statusCode}");

      if (res.statusCode == 200) {
        print("📥 Response Body: ${res.body.substring(0, 200)}...");

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
          setState(() {
            prakiraan = extracted;
          });
          print("🌤️ Jumlah data cuaca: ${prakiraan.length}");
        } else {
          print("❌ Error: status ${res.statusCode}, body=${res.body}");
        }
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

  // Future<void> fetchCuacaFromServer() async {
  //   print("🌤️ [DEBUG] Mengambil cuaca dari Flask server...");

  //   final url =
  //       "${getBaseUrl()}/prediksi?lat=${widget.latitude}&lon=${widget.longitude}";
  //   print("🛰️ [DEBUG] URL: $url");

  //   try {
  //     final res = await http.post(
  //       Uri.parse(url),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode({"lat": widget.latitude, "lon": widget.longitude}),
  //     );

  //     if (!mounted) return; // ⬅️ tambahkan ini

  //     if (res.statusCode == 200) {
  //       final body = jsonDecode(res.body);
  //       final List<dynamic> data = body["data"] ?? [];

  //       if (!mounted) return; // ⬅️ tambahkan ini juga
  //       setState(() {
  //         prakiraan = data;
  //         _isLoading = false;
  //       });

  //       print("✅ [DEBUG] Berhasil ambil ${data.length} item cuaca");
  //     } else {
  //       if (!mounted) return;
  //       print("❌ [DEBUG] Gagal ambil cuaca: ${res.body}");
  //       setState(() => _isLoading = false);
  //     }
  //   } catch (e) {
  //     if (!mounted) return; // ⬅️ dan ini
  //     print("🔥 [DEBUG] Error ambil cuaca: $e");
  //     setState(() => _isLoading = false);
  //   }
  // }

  // String getIcon(String desc) {
  //   desc = desc.toLowerCase();
  //   if (desc.contains("hujan"))
  //     return "https://openweathermap.org/img/wn/10d@2x.png";
  //   if (desc.contains("cerah"))
  //     return "https://openweathermap.org/img/wn/01d@2x.png";
  //   if (desc.contains("berawan"))
  //     return "https://openweathermap.org/img/wn/03d@2x.png";
  //   return "https://openweathermap.org/img/wn/04d@2x.png";
  // }

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
            SizedBox(width: 4),
            Text("BMKG", style: TextStyle(fontSize: 10, color: AppColors.text)),
          ],
        ),
      ],
    );
  }
}
