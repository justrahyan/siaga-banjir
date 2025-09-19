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
    PetaPage(),
    PanduanPage(),
    // RiwayatPage(),
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
      icon: Center(
        child: Image.asset(
          isSelected ? primaryIcon : secondaryIcon,
          width: 28,
          height: 28,
        ),
      ),
      activeIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(primaryIcon, width: 28, height: 28),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      label: '',
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
        showUnselectedLabels: false,
        showSelectedLabels: false,
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
            label: "Panduan",
            primaryIcon: 'assets/images/icon/panduan-primary.png',
            secondaryIcon: 'assets/images/icon/panduan-secondary.png',
          ),
          // _buildNavItem(
          //   index: 2,
          //   label: "Riwayat",
          //   primaryIcon: 'assets/images/icon/riwayat-primary.png',
          //   secondaryIcon: 'assets/images/icon/riwayat-secondary.png',
          // ),
        ],
      ),
    );
  }
}
