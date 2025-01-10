import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:client_manage/client/client_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Client>> fetchClients(String agentName) async {
    try {
      final clientSnapshot = await _firestore
          .collection('agents')
          .doc(agentName)
          .collection('clients')
          .get();
      return clientSnapshot.docs
          .map((doc) => Client.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch clients: $e');
    }
  }

  Future<List<String>> fetchAgentNames() async {
    try {
      final snapshot = await _firestore.collection('agentNames').get();
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      throw Exception('Failed to fetch agent names: $e');
    }
  }
}
