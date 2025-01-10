// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:client_manage/client/client_model.dart';
import 'package:client_manage/reminder/reminder_card.dart';
import 'package:client_manage/utils/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Client>> _clientsWithRemindersFuture;
  bool _showTodaysReminders = false;
  bool _showUpcomingReminders = false;
  bool _showPastReminders = false;
  String selectedAgent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadSelectedAgent();
    _loadClientsWithReminders();
  }

  Future<void> _loadSelectedAgent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAgent = prefs.getString('selectedAgent') ?? 'unknown';
    });
  }

  void _loadClientsWithReminders() {
    setState(() {
      _clientsWithRemindersFuture = _firebaseService
          .fetchClients(selectedAgent)
          .then((clients) =>
              clients.where((client) => client.reminder != '0').toList());
      _isLoading = false;
    });
  }

  Future<void> _refreshClientsWithReminders() async {
    try {
      _loadClientsWithReminders();
      await _clientsWithRemindersFuture;
    } catch (e) {
      _showErrorSnackBar('Error refreshing reminders: $e');
    }
  }

  // void _scheduleReminders(List<Client> clients) {
  //   for (var client in clients) {
  //     try {
  //       DateTime reminderDate = DateTime.parse(client.reminder);
  //       if (reminderDate.isAfter(DateTime.now())) {
  //         NotificationService.scheduleNotification(
  //           id: client.clientID.hashCode,
  //           title: 'Reminder for ${client.name}',
  //           body: 'It\'s time for ${client.name}\'s scheduled task.',
  //           scheduledTime: reminderDate,
  //         );
  //       }
  //     } catch (e) {
  //       _showErrorSnackBar('Error scheduling reminder for ${client.name}: $e');
  //     }
  //   }
  // }

  List<Client> _getTodaysReminders(List<Client> clients) {
    DateTime now = DateTime.now();
    return clients.where((client) {
      DateTime reminderDate = DateTime.parse(client.reminder);
      return reminderDate.year == now.year &&
          reminderDate.month == now.month &&
          reminderDate.day == now.day &&
          reminderDate.isAfter(now);
    }).toList()
      ..sort((a, b) =>
          DateTime.parse(a.reminder).compareTo(DateTime.parse(b.reminder)));
  }

  List<Client> _getUpcomingReminders(List<Client> clients) {
    DateTime now = DateTime.now();
    return clients.where((client) {
      DateTime reminderDate = DateTime.parse(client.reminder);
      return reminderDate.isAfter(now) &&
          !(reminderDate.year == now.year &&
              reminderDate.month == now.month &&
              reminderDate.day == now.day);
    }).toList()
      ..sort((a, b) =>
          DateTime.parse(a.reminder).compareTo(DateTime.parse(b.reminder)));
  }

  List<Client> _getPastReminders(List<Client> clients) {
    DateTime now = DateTime.now();
    DateTime fiveDaysAgo = now.subtract(const Duration(days: 5));

    return clients.where((client) {
      DateTime reminderDate = DateTime.parse(client.reminder);
      return reminderDate.isBefore(now) && reminderDate.isAfter(fiveDaysAgo);
    }).toList()
      ..sort((a, b) =>
          DateTime.parse(b.reminder).compareTo(DateTime.parse(a.reminder)));
  }

  Future<void> _removeOldPastReminders(List<Client> clients) async {
    DateTime now = DateTime.now();
    DateTime fiveDaysAgo = now.subtract(const Duration(days: 5));

    for (var client in clients) {
      DateTime reminderDate = DateTime.parse(client.reminder);
      if (reminderDate.isBefore(fiveDaysAgo)) {
        try {
          await FirebaseFirestore.instance
              .collection('agents')
              .doc(selectedAgent)
              .collection('clients')
              .doc(client.clientID)
              .update({'reminder': '0'});
        } catch (e) {
          _showErrorSnackBar(
              'Failed to remove reminder for ${client.name} from past: $e');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: FutureBuilder<List<Client>>(
        future: _clientsWithRemindersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No reminders found",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final clientsWithReminders = snapshot.data!;
          final todaysReminders = _getTodaysReminders(clientsWithReminders);
          final upcomingReminders = _getUpcomingReminders(clientsWithReminders);
          final pastReminders = _getPastReminders(clientsWithReminders);

          _removeOldPastReminders(pastReminders);

          return RefreshIndicator(
            color: Colors.black,
            backgroundColor: Colors.white,
            onRefresh: _refreshClientsWithReminders,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Today's Reminders Section
                _buildExpandableSection(
                  title: "Today",
                  isExpanded: _showTodaysReminders,
                  onToggle: () => setState(() {
                    _showTodaysReminders = !_showTodaysReminders;
                  }),
                  reminders: todaysReminders,
                ),

                // Upcoming Reminders Section
                _buildExpandableSection(
                  title: "Upcoming",
                  isExpanded: _showUpcomingReminders,
                  onToggle: () => setState(() {
                    _showUpcomingReminders = !_showUpcomingReminders;
                  }),
                  reminders: upcomingReminders,
                ),

                // Past Reminders Section
                _buildExpandableSection(
                  title: "Past",
                  isExpanded: _showPastReminders,
                  onToggle: () => setState(() {
                    _showPastReminders = !_showPastReminders;
                  }),
                  reminders: pastReminders,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Client> reminders,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              trailing: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        if (isExpanded)
          ...reminders.map(
            (client) => ReminderCard(client: client),
          ),
      ],
    );
  }
}
