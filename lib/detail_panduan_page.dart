import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
