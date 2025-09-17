import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/main_screen.dart';
import 'package:siaga_banjir/splash_screen.dart';
import 'package:siaga_banjir/themes/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siaga Banjir',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
