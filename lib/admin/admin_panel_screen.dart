import 'package:flutter/material.dart';
import 'package:client_manage/admin/expandable_section.dart';
import 'package:client_manage/user/user_model.dart';
import 'package:client_manage/user/user_repository.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final UserRepository userRepository = UserRepository();
  late Future<void> _allDataFuture;

  bool _showApproveRequests = false;
  bool _showDeleteAgents = false;

  List<UserModel> _pendingUsers = [];
  List<UserModel> _verifiedAgents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _allDataFuture = Future.wait([
      userRepository.fetchPendingUsers().then((data) {
        _pendingUsers = data;
      }),
      userRepository.fetchVerifiedAgents().then((data) {
        _verifiedAgents = data;
      }),
    ]);
  }

  Future<void> _refreshData() async {
    _loadData();
    await _allDataFuture;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: FutureBuilder<void>(
        future: _allDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: Colors.black,
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ExpandableSection(
                  title: "Approve Requests",
                  isExpanded: _showApproveRequests,
                  onToggle: () => setState(() {
                    _showApproveRequests = !_showApproveRequests;
                  }),
                  users: _pendingUsers,
                  isLoading: false,
                  actionType: "approve",
                  onAction: userRepository.approveUser,
                ),
                ExpandableSection(
                  title: "Delete Agents",
                  isExpanded: _showDeleteAgents,
                  onToggle: () => setState(() {
                    _showDeleteAgents = !_showDeleteAgents;
                  }),
                  users: _verifiedAgents,
                  isLoading: false,
                  actionType: "delete",
                  onAction: userRepository.deleteUser,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
