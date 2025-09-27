// file: lib/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern untuk memastikan hanya ada satu instance dari service ini
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() {
    return _instance;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Pengaturan untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Gunakan ikon launcher default

    // Pengaturan untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Minta izin notifikasi untuk Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'banjir_channel', // ID channel
          'Notifikasi Banjir', // Nama channel
          channelDescription: 'Channel untuk notifikasi status banjir',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // ID notifikasi
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
