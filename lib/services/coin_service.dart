import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addCoins(int amount) async {
    String userId = _auth.currentUser!.uid;
    DocumentReference userDoc = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userDoc);

      if (!snapshot.exists) {
        userDoc.set({'coins': amount});
        return;
      }

      int newCoins = (snapshot['coins'] ?? 0) + amount;
      transaction.update(userDoc, {'coins': newCoins});
    });
  }

  Future<int> getCoins() async {
    String userId = _auth.currentUser!.uid;
    DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).get();
    return snapshot['coins'] ?? 0;
  }
}
