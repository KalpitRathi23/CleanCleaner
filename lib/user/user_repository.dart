import 'package:client_manage/user/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> fetchPendingUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('isVerified', isEqualTo: false)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<List<UserModel>> fetchVerifiedAgents() async {
    final snapshot = await _firestore
        .collection('users')
        .where('isVerified', isEqualTo: true)
        .where('role', isEqualTo: 'Agent')
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<void> approveUser(String email) async {
    await _firestore.collection('users').doc(email).update({
      'isVerified': true,
    });
  }

  Future<void> deleteUser(String email) async {
    await _firestore.collection('users').doc(email).update({
      'isVerified': false,
    });
  }
}
