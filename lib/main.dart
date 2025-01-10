import 'package:client_manage/auth/pending_approval_screen.dart';
import 'package:client_manage/home/home_screen.dart';
import 'package:client_manage/splash_screen.dart';
import 'package:client_manage/utils/global_state.dart';
import 'package:client_manage/utils/notification_service.dart';
import 'package:client_manage/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:client_manage/auth/login_screen.dart';
import 'package:client_manage/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  await NotificationService.initialize();
  await NotificationService.requestPermission();
  await NotificationService.checkAndRequestExactAlarmPermission();
  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.handleInitialNotification();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GlobalState(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          // AppRoutes.signup: (context) => const SignupScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.pendingApproval: (context) => const PendingApprovalScreen(),
        },
      ),
    );
  }
}
