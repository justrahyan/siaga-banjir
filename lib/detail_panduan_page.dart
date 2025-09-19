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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black26,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.quicksand(fontSize: 14, height: 1.6),
          ),
        ),
      ),
    );
  }
}
