import 'package:client_manage/utils/global_state.dart';
import 'package:flutter/material.dart';
import 'package:client_manage/client/client_detail_screen.dart';
import 'package:client_manage/client/client_util.dart';
import 'package:provider/provider.dart';
import 'client_model.dart';

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    final isCodeVerified = Provider.of<GlobalState>(context).isCodeVerified;
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
            if (isCodeVerified)
              Row(
                children: [
                  const Text(
                    "Closing Balance:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ClientUtil.formatBalanceValue(client.balance),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ClientUtil.getBalanceColor(client.balance),
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
