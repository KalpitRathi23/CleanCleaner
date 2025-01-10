// ignore_for_file: avoid_print

import 'package:client_manage/auth/login_screen.dart';
import 'package:client_manage/auth/pending_approval_screen.dart';
import 'package:client_manage/client/client_detail_screen.dart';
import 'package:client_manage/client/client_model.dart';
import 'package:client_manage/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      const androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _handleNotificationResponse,
      );
    } catch (e) {
      print('Error during notification initialization: $e');
    }
  }

  static Future<void> handleInitialNotification() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final String? payload =
          notificationAppLaunchDetails?.notificationResponse?.payload;

      if (payload != null && payload.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('email');

        if (userEmail != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userEmail)
                .get();

            if (userDoc.exists) {
              final isVerified = userDoc.data()?['isVerified'] ?? false;
              if (isVerified) {
                await _navigateToClientDetails(payload);
              } else {
                await navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => const PendingApprovalScreen(),
                  ),
                );
              }
            } else {
              await navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            }
          } catch (e) {
            await navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        } else {
          await navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      }
    }
  }

  static Future<void> _handleNotificationResponse(
      NotificationResponse response) async {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('email');

      if (userEmail != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userEmail)
              .get();

          if (userDoc.exists) {
            final isVerified = userDoc.data()?['isVerified'] ?? false;
            if (isVerified) {
              await _navigateToClientDetails(response.payload!);
            } else {
              await navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => const PendingApprovalScreen(),
                ),
              );
            }
          } else {
            await navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        } catch (e) {
          await navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      } else {
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } else {
      print("Empty or null notification payload received.");
    }
  }

  static Future<void> _navigateToClientDetails(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    String selectedAgent = prefs.getString('selectedAgent') ?? 'unknown';
    try {
      final clientSnapshot = await FirebaseFirestore.instance
          .collection('agents')
          .doc(selectedAgent)
          .collection('clients')
          .doc(clientId)
          .get();

      if (clientSnapshot.exists) {
        final clientData = clientSnapshot.data()!;
        final client = Client.fromFirestore(clientData);

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ClientDetailsScreen(client: client),
          ),
        );
      } else {
        print('Client not found in Firestore!');
      }
    } catch (e) {
      print('Error navigating to client details: $e');
    }
  }

  static Future<void> requestPermission() async {
    try {
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (status != PermissionStatus.granted) {
          print("Notification permissions denied.");
        }
      }

      // For iOS-specific permissions
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      print("Error requesting notification permissions: $e");
    }
  }

  static Future<void> checkAndRequestExactAlarmPermission() async {
    try {
      if (await Permission.scheduleExactAlarm.isDenied) {
        final status = await Permission.scheduleExactAlarm.request();
        if (status != PermissionStatus.granted) {
          print("Exact alarm permission not granted.");
          return;
        }
      }
      print("Exact alarm permission granted.");
    } catch (e) {
      print("Error requesting exact alarm permission: $e");
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const androidNotificationDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosNotificationDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String clientId,
  }) async {
    try {
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      const androidNotificationDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const iosNotificationDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: clientId,
      );
      print('Notification successfully scheduled for $id');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      print('Notification with ID $id canceled.');
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }
}
