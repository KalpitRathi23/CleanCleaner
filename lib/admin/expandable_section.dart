import 'package:flutter/material.dart';
import 'package:client_manage/user/user_model.dart';
import 'package:client_manage/admin/user_tile.dart';

class ExpandableSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<UserModel> users;
  final bool isLoading;
  final String actionType;
  final Future<void> Function(String email) onAction;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.users,
    required this.isLoading,
    required this.actionType,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
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
          isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                )
              : users.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          "No data available",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return UserTile(
                          user: users[index],
                          actionType: actionType,
                          onAction: onAction,
                        );
                      },
                    ),
      ],
    );
  }
}
