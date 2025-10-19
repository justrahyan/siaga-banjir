import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siaga_banjir/themes/colors.dart';

void showDeviceDetail(
  BuildContext context, {
  required String connectionStatus,
  required String powerSource,
  required int batteryPercentage,
  required String deviceName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 20, color: AppColors.text),
                      const SizedBox(width: 6),
                      Text(
                        connectionStatus,
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: connectionStatus.toLowerCase() == "online"
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (powerSource.toLowerCase() == "baterai")
                    _BatteryIndicator(batteryPercentage: batteryPercentage),
                ],
              ),
              const SizedBox(height: 16),
              // gambar device
              Center(
                child: Image.asset(
                  'assets/images/prototype.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 16),
              // judul
              Text(
                deviceName,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              // deskripsi
              Text(
                "Detail informasi alat pemantau banjir",
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              // sumber daya
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    powerSource.toLowerCase() == "solar panel"
                        ? Icons.solar_power
                        : Icons.battery_charging_full,
                    size: 20,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    powerSource,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // tombol
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Tutup",
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Widget custom baterai
class _BatteryIndicator extends StatelessWidget {
  final int batteryPercentage;

  const _BatteryIndicator({required this.batteryPercentage});

  @override
  Widget build(BuildContext context) {
    Color fillColor;
    if (batteryPercentage > 50) {
      fillColor = Colors.green;
    } else if (batteryPercentage > 20) {
      fillColor = Colors.orange;
    } else {
      fillColor = Colors.red;
    }

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.text, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: batteryPercentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              child: Container(width: 4, height: 8, color: AppColors.text),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          "$batteryPercentage%",
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}
