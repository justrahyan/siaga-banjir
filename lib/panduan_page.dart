import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/themes/colors.dart';

class PanduanPage extends StatelessWidget {
  const PanduanPage({super.key});

  // Dummy data untuk panduan
  final List<Map<String, String>> sebelum = const [
    {
      "title": "Simpan Dokumen Penting",
      "content":
          "Letakkan dokumen seperti KTP, KK, dan ijazah di tempat tahan air agar tetap aman saat banjir.",
    },
    {
      "title": "Siapkan Tas Darurat",
      "content":
          "Isi dengan pakaian, makanan instan, air minum, obat-obatan, senter, dan baterai cadangan.",
    },
    {
      "title": "Periksa Saluran Air",
      "content":
          "Pastikan selokan dan drainase sekitar rumah tidak tersumbat agar air dapat mengalir dengan lancar.",
    },
  ];

  final List<Map<String, String>> saat = const [
    {
      "title": "Matikan Listrik",
      "content":
          "Segera matikan aliran listrik di rumah untuk mencegah korsleting dan bahaya kebakaran.",
    },
    {
      "title": "Cari Tempat Aman",
      "content":
          "Segera menuju tempat lebih tinggi atau posko pengungsian jika banjir semakin tinggi.",
    },
    {
      "title": "Hindari Air Deras",
      "content":
          "Jangan berjalan atau berkendara di arus banjir yang deras karena sangat berbahaya.",
    },
  ];

  final List<Map<String, String>> setelah = const [
    {
      "title": "Gunakan APD",
      "content":
          "Saat membersihkan rumah gunakan sarung tangan, sepatu bot, dan masker untuk menghindari penyakit.",
    },
    {
      "title": "Periksa Instalasi Listrik",
      "content":
          "Jangan menyalakan listrik sebelum diperiksa oleh petugas PLN untuk memastikan keamanan.",
    },
    {
      "title": "Periksa Kesehatan",
      "content":
          "Jika mengalami gejala penyakit seperti diare, demam, atau gatal-gatal, segera ke fasilitas kesehatan.",
    },
  ];

  Widget buildCard(
    BuildContext context,
    String title,
    String desc,
    String fullContent,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PanduanDetailPage(title: title, content: fullContent),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gabungan semua artikel
    final semua = [...sebelum, ...saat, ...setelah];

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            "Panduan Banjir",
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          shadowColor: Colors.black26,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: "Semua"),
              Tab(text: "Sebelum"),
              Tab(text: "Saat"),
              Tab(text: "Setelah"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Semua
            ListView(
              children: semua
                  .map(
                    (item) => buildCard(
                      context,
                      item["title"]!,
                      item["content"]!,
                      item["content"]!,
                    ),
                  )
                  .toList(),
            ),
            // Sebelum
            ListView(
              children: sebelum
                  .map(
                    (item) => buildCard(
                      context,
                      item["title"]!,
                      item["content"]!,
                      item["content"]!,
                    ),
                  )
                  .toList(),
            ),
            // Saat
            ListView(
              children: saat
                  .map(
                    (item) => buildCard(
                      context,
                      item["title"]!,
                      item["content"]!,
                      item["content"]!,
                    ),
                  )
                  .toList(),
            ),
            // Setelah
            ListView(
              children: setelah
                  .map(
                    (item) => buildCard(
                      context,
                      item["title"]!,
                      item["content"]!,
                      item["content"]!,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class PanduanDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const PanduanDetailPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          content,
          style: GoogleFonts.quicksand(fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}
