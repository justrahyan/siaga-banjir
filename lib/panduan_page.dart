import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/themes/colors.dart';
import 'detail_panduan_page.dart';

class PanduanPage extends StatelessWidget {
  const PanduanPage({super.key});

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
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  color: AppColors.text,
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

  Widget buildList(String? kategori) {
    final query = kategori == null
        ? FirebaseFirestore.instance.collection('panduan')
        : FirebaseFirestore.instance
              .collection('panduan')
              .where('kategori', isEqualTo: kategori);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Terjadi kesalahan"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
                SizedBox(height: 12),
                Text(
                  "Memuat panduan...",
                  style: TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada Panduan tersedia",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          );
        }

        final data = snapshot.data!.docs;

        return ListView(
          children: data.map((doc) {
            final item = doc.data() as Map<String, dynamic>;
            return buildCard(
              context,
              item['title'] ?? '',
              item['content'] ?? '',
              item['content'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          surfaceTintColor: Colors.white,
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
        body: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TabBarView(
            children: [
              buildList(null), // semua
              buildList("sebelum"), // sebelum
              buildList("saat"), // saat
              buildList("setelah"), // setelah
            ],
          ),
        ),
      ),
    );
  }
}
