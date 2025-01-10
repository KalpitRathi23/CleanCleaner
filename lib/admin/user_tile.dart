import 'package:client_manage/client/client_util.dart';
import 'package:client_manage/user/user_model.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final String actionType;
  final Future<void> Function(String email) onAction;

  const UserTile({
    super.key,
    required this.user,
    required this.actionType,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDateTime =
        "${ClientUtil.formatDate(user.createdAt)}, ${ClientUtil.formatTime(user.createdAt, context)}";

    return Card(
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name == '0' ? "Owner" : user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Created: $formattedDateTime",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onAction(user.email).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        actionType == "approve"
                            ? "User approved successfully."
                            : "User deleted successfully.",
                      ),
                    ),
                  );
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                backgroundColor:
                    actionType == "approve" ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionType == "approve" ? "Approve" : "Delete",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
