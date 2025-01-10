// owner_client_screen.dart
// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:client_manage/client/client_model.dart';
import 'package:client_manage/client/client_card.dart';
import 'package:client_manage/utils/firebase_service.dart';
import 'package:client_manage/utils/global_state.dart';

class OwnerClientScreen extends StatefulWidget {
  const OwnerClientScreen({super.key});

  @override
  _OwnerClientScreenState createState() => _OwnerClientScreenState();
}

class _OwnerClientScreenState extends State<OwnerClientScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  late Future<List<Client>> _clientsFuture;
  List<Client> _clients = [];
  List<Client> _filteredClients = [];

  List<String> _agentNames = [];
  String _selectedAgentForOwner = 'Select Agent';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _additionalCodeController =
      TextEditingController();
  bool _showFilters = false;
  String _selectedCategory = 'All';
  String _selectedBalanceOrder = 'None';
  String selectedAgent = 'unknown';
  double _totalClosingBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _clientsFuture = Future.value([]);
    _loadAgentNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _additionalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAgentNames() async {
    try {
      final names = await _firebaseService.fetchAgentNames();
      setState(() {
        _agentNames = names;
      });
    } catch (e) {
      debugPrint('Error fetching agent names: $e');
    }
  }

  void _loadClients() {
    setState(() {
      _clientsFuture =
          _firebaseService.fetchClients(_selectedAgentForOwner).then((clients) {
        _clients = clients;
        _filteredClients = clients;
        _calculateTotalClosingBalance();
        return clients;
      });
    });
  }

  Future<void> _refreshClients() async {
    _loadClients();
    await _clientsFuture;
  }

  void _onSearchChanged() {
    _filterClients();
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _clients.where((client) {
        final name = client.name.toLowerCase();
        final address = client.address.toLowerCase();
        final mobile = client.mobile.toLowerCase();
        bool matchesSearch = name.contains(query) ||
            address.contains(query) ||
            mobile.contains(query);

        bool matchesCategory = (_selectedCategory == 'All') ||
            (client.category == _selectedCategory);

        return matchesSearch && matchesCategory;
      }).toList();

      if (_selectedBalanceOrder == 'High to Low') {
        _filteredClients.sort((a, b) => b.balance.compareTo(a.balance));
      } else if (_selectedBalanceOrder == 'Low to High') {
        _filteredClients.sort((a, b) => a.balance.compareTo(b.balance));
      }
    });
  }

  Future<void> _verifyCode(BuildContext context, String enteredCode) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('security')
          .doc('password')
          .get();

      if (doc.exists && doc['code'] == enteredCode) {
        Provider.of<GlobalState>(context, listen: false).verifyCode();
        _additionalCodeController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code verified successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying code: $e')),
      );
    }
  }

  void _calculateTotalClosingBalance() {
    setState(() {
      _totalClosingBalance =
          _filteredClients.fold(0.0, (sum, client) => sum + client.balance);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCodeVerified = Provider.of<GlobalState>(context).isCodeVerified;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search Client',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.close : Icons.filter_list,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _agentNames.isEmpty
                        ? null
                        : (_agentNames.contains(_selectedAgentForOwner)
                            ? _selectedAgentForOwner
                            : null),
                    isDense: true,
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 24,
                    elevation: 16,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    items: _agentNames
                        .map((agent) => DropdownMenuItem(
                              value: agent,
                              child: Text(agent),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        Provider.of<GlobalState>(context, listen: false)
                            .updateSelectedOwnerAgent(value);
                        setState(() {
                          _selectedAgentForOwner = value;
                        });
                        _loadClients();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Select Agent',
                      labelStyle: const TextStyle(
                        color: Colors.black54,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2.0,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          dropdownColor: Colors.green.shade50,
                          items: ['All', 'Good', 'Normal', 'Bad']
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                              _filterClients();
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2.0,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedBalanceOrder,
                          dropdownColor: Colors.green.shade50,
                          items: ['None', 'High to Low', 'Low to High']
                              .map((order) => DropdownMenuItem(
                                    value: order,
                                    child: Text(
                                      order,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBalanceOrder = value!;
                              _filterClients();
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Closing Balance',
                            labelStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2.0,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _additionalCodeController,
                          cursorColor: Colors.black,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Enter Code',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          if (isCodeVerified) {
                            Provider.of<GlobalState>(context, listen: false)
                                .resetCodeVerification();
                          } else {
                            final enteredCode =
                                _additionalCodeController.text.trim();
                            if (enteredCode.isNotEmpty) {
                              await _verifyCode(context, enteredCode);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a code.'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.black,
                        ),
                        child: Text(
                          isCodeVerified ? 'Hide' : 'Enter',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isCodeVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          const Text(
                            'Total Closing Balance: ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${_totalClosingBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              color: _totalClosingBalance >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Client>>(
              future: _clientsFuture,
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
                      "No clients found",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                if (_filteredClients.isEmpty) {
                  return const Center(
                    child: Text(
                      "No matching clients",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  onRefresh: _refreshClients,
                  child: ListView.builder(
                    itemCount: _filteredClients.length,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    itemBuilder: (context, index) {
                      return ClientCard(
                        client: _filteredClients[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
