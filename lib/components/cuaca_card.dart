import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:siaga_banjir/home_page.dart';
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
              // Image.asset(icon, width: 84, height: 84),
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
  // final String kodeWilayah;
  // const CuacaSection({super.key, required this.kodeWilayah});
  const CuacaSection({super.key});

  @override
  State<CuacaSection> createState() => _CuacaSectionState();
}

class _CuacaSectionState extends State<CuacaSection> {
  Map<String, dynamic>? cuaca; // ini utk Open Weather Map
  List<dynamic> prakiraan = []; // ini utk BMKG

  @override
  void initState() {
    super.initState();
    getCurrentLocation().then((pos) {
      fetchCuaca(pos.latitude, pos.longitude);
    });
    // fetchCuaca(-5.167971, 119.433536);
    // fetchCuaca();
  }

  // double lat, double lon utk argumen fetchCuaca
  Future<void> fetchCuaca(double lat, double lon) async {
    const apiKey = "bb2dd84ca2541574dac0faffefcb4e45";
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id";

    // final url =
    //     "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=${widget.kodeWilayah}";
    print("URL: $url");
    // print("Latitude:" + lat.toString());
    // print("Longitude:" + lon.toString());

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
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
          cuaca = data;
          prakiraan = extracted;
        });
      } else {
        print("❌ Error: ${res.body}");
      }
    } catch (e) {
      print("🔥 Exception: $e");
    }
  }

  String getIconUrl(String iconCode) {
    return "https://openweathermap.org/img/wn/$iconCode@2x.png";
  }

  String getIcon(String desc) {
    if (desc.contains("Hujan")) return "assets/images/icon/cuaca/rain.png";
    if (desc.contains("Cerah")) return "assets/images/icon/cuaca/sunny.png";
    if (desc.contains("Berawan")) return "assets/images/icon/cuaca/cloudy.png";
    if (desc.contains("Badai")) return "assets/images/icon/cuaca/thunder.png";
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
          child: cuaca == null
              ? const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Memuat data cuaca...",
                        style: TextStyle(color: AppColors.text, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : PageView(
                  controller: PageController(viewportFraction: 0.95),
                  children: [
                    CuacaCard(
                      icon: getIconUrl(cuaca!["weather"][0]["icon"]),
                      suhu: cuaca!["main"]["temp"].toString(),
                      kondisi: cuaca!["weather"][0]["description"],
                      angin: "${cuaca!["wind"]["speed"]} m/s",
                      kelembapan: cuaca!["main"]["humidity"].toString(),
                      waktu: DateFormat(
                        "dd MMMM yyyy",
                        "id_ID",
                      ).format(DateTime.now()),
                      isToday: true,
                    ),
                  ],
                ),
        ),
        // SizedBox(
        //   height: 200,
        //   child: prakiraan.isEmpty
        //       ? const Center(
        //           child: CircularProgressIndicator(
        //             valueColor: AlwaysStoppedAnimation(AppColors.primary),
        //           ),
        //         )
        //       : PageView.builder(
        //           controller: PageController(viewportFraction: 0.95),
        //           itemCount: prakiraan.length,
        //           itemBuilder: (context, index) {
        //             final item = prakiraan[index];
        //             final waktu = item["local_datetime"].toString();

        //             return CuacaCard(
        //               icon: getIcon(item["weather_desc"] ?? ""),
        //               suhu: item["t"].toString(),
        //               kondisi: item["weather_desc"] ?? "",
        //               angin: "${item["ws"]} km/h",
        //               kelembapan: item["hu"].toString(),
        //               waktu: waktu,
        //               isToday: index == 0, // card pertama dianggap hari ini
        //             );
        //           },
        //         ),
        // ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              "Sumber: ",
              style: TextStyle(fontSize: 10, color: AppColors.text),
            ),
            const SizedBox(width: 4),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  child: Image.asset(
                    "assets/images/logo/logo-openweathermap.png",
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Open Weather Map',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // SizedBox(
                //   height: 24,
                //   child: Image.asset("assets/images/logo/logo-bmkg.png"),
                // ),
                // SizedBox(width: 8),
                // Text(
                //   'BMKG',
                //   style: GoogleFonts.quicksand(
                //     fontSize: 12,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
      ],
    );
  }
}
