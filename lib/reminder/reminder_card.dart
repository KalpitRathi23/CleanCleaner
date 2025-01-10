import 'package:flutter/material.dart';
import 'package:client_manage/client/client_model.dart';
import 'package:client_manage/client/client_detail_screen.dart';
import 'package:client_manage/client/client_util.dart';

class ReminderCard extends StatelessWidget {
  final Client client;

  const ReminderCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    DateTime reminderDate = DateTime.parse(client.reminder);

    String formattedReminder =
        "${ClientUtil.formatDate(reminderDate)}, ${ClientUtil.formatTime(reminderDate, context)}";
    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(
          client.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                const Text(
                  "Reminder:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    formattedReminder,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text(
                  "Category:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
                ClientUtil.buildBadge(client.category),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientDetailsScreen(client: client),
            ),
          );
        },
      ),
    );
  }
}
