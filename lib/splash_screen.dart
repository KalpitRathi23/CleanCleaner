// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:client_manage/utils/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInternetAvailable = true;
  bool _restrictApp = false;

  @override
  void initState() {
    super.initState();
    _checkInternetAndProceed();
  }

  Future<void> _checkInternetAndProceed() async {
    bool hasInternet = await _checkInternetConnection();

    if (hasInternet) {
      await _checkSecurity();
    } else {
      setState(() {
        _isInternetAvailable = false;
      });
    }
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile);
  }

  Future<void> _checkSecurity() async {
    try {
      DateTime expiryDate = DateTime(2026, 1, 8);
      DateTime currentDate = DateTime.now();

      if (currentDate.isAfter(expiryDate)) {
        _showExpiryMessage();
        return;
      }

      DocumentSnapshot securityDoc =
          await _firestore.collection('security').doc('start').get();

      if (securityDoc.exists) {
        setState(() {
          _restrictApp = securityDoc['restrictApp'] ?? false;
        });

        if (!_restrictApp) {
          _startTimer();
        } else {
          _showSecurityMessage();
        }
      } else {
        _showSecurityMessage();
      }
    } catch (e) {
      _showSecurityMessage();
    }
  }

  void _showSecurityMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          titlePadding: const EdgeInsets.only(
            top: 20,
            bottom: 15,
          ),
          title: const Center(
            child: Text(
              'App Restricted',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          content: const Text(
            'The app is currently restricted. \n Please try again later',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        );
      },
    );
  }

  void _showExpiryMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          titlePadding: const EdgeInsets.only(
            top: 20,
            bottom: 15,
          ),
          title: const Center(
            child: Text(
              'App Expired',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          content: const Text(
            'Your time to use the app has expired. Please contact the administrator for assistance.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        );
      },
    );
  }

  void _startTimer() {
    Timer(const Duration(seconds: 2), _checkLoggedInUser);
  }

  Future<void> _checkLoggedInUser() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.email).get();

        if (!mounted) return;

        if (userDoc.exists && userDoc['isVerified'] == true) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.pendingApproval);
        }
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _retryConnection() async {
    bool hasInternet = await _checkInternetConnection();

    if (hasInternet) {
      await _checkSecurity();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Still no internet connection!")),
      );
    }

    setState(() {
      _isInternetAvailable = hasInternet;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isInternetAvailable
            ? Image.asset(
                'assets/images/logo.png',
                width: screenWidth * 0.85,
                height: screenHeight * 0.85,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 70, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Please check your \ninternet connection",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _retryConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Retry",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
