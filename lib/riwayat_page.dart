import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/themes/colors.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  // contoh data dummy riwayat
  final List<Map<String, String>> riwayat = const [
    {
      "tanggal": "18 Sep 2025",
      "judul": "Alat Pemantau Online",
      "deskripsi": "Alat berhasil terhubung kembali setelah offline.",
    },
    {
      "tanggal": "17 Sep 2025",
      "judul": "Baterai Rendah",
      "deskripsi": "Baterai perangkat turun di bawah 20%.",
    },
    {
      "tanggal": "15 Sep 2025",
      "judul": "Gangguan Koneksi",
      "deskripsi": "Alat tidak merespon selama 2 jam.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Riwayat",
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.2),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: riwayat.length,
        itemBuilder: (context, index) {
          final item = riwayat[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: Text(
                item["judul"]!,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "${item["tanggal"]} • ${item["deskripsi"]}",
                style: GoogleFonts.quicksand(fontSize: 13),
              ),
            ),
          );
        },
      ),
    );
  }
}
