// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:client_manage/admin/admin_panel_screen.dart';
import 'package:client_manage/client/owner_client_screen.dart';
import 'package:client_manage/utils/global_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:client_manage/client/client_screen.dart';
import 'package:client_manage/reminder/reminder_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];
  bool isLoading = true;
  String selectedAgent = '';

  @override
  void initState() {
    super.initState();
    _initializeHomeScreen();
  }

  Future<void> _initializeHomeScreen() async {
    await _loadSelectedAgent();
    await _checkUserRole();
  }

  Future<void> _loadSelectedAgent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAgent = prefs.getString('selectedAgent') ?? 'Unknown';
    });
  }

  Future<void> _checkUserRole() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.email)
            .get();

        if (userDoc.exists && userDoc['role'] == 'Owner') {
          setState(() {
            _pages = [
              const OwnerClientScreen(),
              const ReminderScreen(),
              const AdminPanelScreen(),
            ];
            _navItems = [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.alarm_outlined),
                activeIcon: Icon(Icons.alarm),
                label: 'Reminder',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_outlined),
                activeIcon: Icon(Icons.admin_panel_settings),
                label: 'Admin',
              ),
            ];
          });
        } else {
          setState(() {
            _pages = [
              const ClientScreen(),
              const ReminderScreen(),
            ];
            _navItems = [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.alarm_outlined),
                activeIcon: Icon(Icons.alarm),
                label: 'Reminder',
              ),
            ];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user role: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Provider.of<GlobalState>(context, listen: false).resetCodeVerification();
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Text(
          selectedAgent,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.black,
          selectedFontSize: 15,
          unselectedFontSize: 12,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedIconTheme: const IconThemeData(size: 32),
          unselectedIconTheme: const IconThemeData(size: 26),
          onTap: (index) {
            setState(
              () {
                _currentIndex = index;
              },
            );
          },
          items: _navItems,
        ),
      ),
    );
  }
}
