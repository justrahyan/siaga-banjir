import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:siaga_banjir/home_page.dart';
import 'themes/colors.dart';

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
  Map<String, dynamic>? cuaca;

  @override
  void initState() {
    super.initState();
    getCurrentLocation().then((pos) {
      fetchCuaca(pos.latitude, pos.longitude);
    });
  }

  Future<void> fetchCuaca(double lat, double lon) async {
    const apiKey = "bb2dd84ca2541574dac0faffefcb4e45";
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          cuaca = data;
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
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
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
                      waktu: DateTime.now().toLocal().toString(),
                      isToday: true,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              "Sumber: ",
              style: TextStyle(fontSize: 10, color: AppColors.text),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 24,
              child: Image.asset("assets/images/logo/logo-openweathermap.png"),
            ),
          ],
        ),
      ],
    );
  }
}
