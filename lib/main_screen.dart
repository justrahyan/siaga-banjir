import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/themes/colors.dart';
import 'home_page.dart';
import 'panduan_page.dart';
import 'peta_page.dart';
import 'riwayat_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomePage(),
    PanduanPage(),
    PetaPage(),
    RiwayatPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildNavItem({
    required int index,
    required String label,
    required String primaryIcon,
    required String secondaryIcon,
  }) {
    final bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Image.asset(
        isSelected ? primaryIcon : secondaryIcon,
        width: isSelected ? 26 : 32,
        height: isSelected ? 26 : 32,
      ),
      label: isSelected ? label : "",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.quicksand(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: GoogleFonts.quicksand(fontSize: 12),
        items: [
          _buildNavItem(
            index: 0,
            label: "Beranda",
            primaryIcon: 'assets/images/icon/beranda-primary.png',
            secondaryIcon: 'assets/images/icon/beranda-secondary.png',
          ),
          _buildNavItem(
            index: 1,
            label: "Peta",
            primaryIcon: 'assets/images/icon/peta-primary.png',
            secondaryIcon: 'assets/images/icon/peta-secondary.png',
          ),
          _buildNavItem(
            index: 2,
            label: "Riwayat",
            primaryIcon: 'assets/images/icon/riwayat-primary.png',
            secondaryIcon: 'assets/images/icon/riwayat-secondary.png',
          ),
          _buildNavItem(
            index: 3,
            label: "Panduan",
            primaryIcon: 'assets/images/icon/panduan-primary.png',
            secondaryIcon: 'assets/images/icon/panduan-secondary.png',
          ),
        ],
      ),
    );
  }
}
