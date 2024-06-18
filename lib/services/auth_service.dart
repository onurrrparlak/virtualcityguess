import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> registerWithEmailAndPassword(BuildContext context, String email, String password, String playerName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'playerName': playerName,
          'rating': 1000,
          'premium': false,
          'avatarUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        Provider.of<UserModel>(context, listen: false).setUser(email, playerName, 1000, false, '');

        await user.sendEmailVerification();
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<String> uploadAvatar(String uid, File avatarFile) async {
    try {
      Reference ref = _storage.ref().child('avatars/$uid');
      UploadTask uploadTask = ref.putFile(avatarFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error uploading avatar: $e');
    }
  }

  Future<bool> isPlayerNameAvailable(String playerName) async {
    final result = await _firestore.collection('users').where('playerName', isEqualTo: playerName).get();
    return result.docs.isEmpty;
  }

  Future<User?> signInWithEmailAndPassword(BuildContext context, String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null && user.emailVerified) {
        DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();
        Provider.of<UserModel>(context, listen: false).setUser(
          userData['email'],
          userData['playerName'],
          userData['rating'],
          userData['premium'],
          userData['avatarUrl'],
        );
        return user;
      } else if (user != null && !user.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email to log in.');
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'E-mail or password is incorrect');
    }
    return null;
  }

  Future<void> signOut(BuildContext context) async {
    try {
      Provider.of<UserModel>(context, listen: false).setUser('', '', 0, false, '');
      final userBox = await Hive.openBox<UserModel>('userBox');
      await userBox.clear();
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {'user': null, 'isNewUser': false};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      bool isNewUser = result.additionalUserInfo!.isNewUser;

      if (isNewUser) {
        await _firestore.collection('users').doc(user!.uid).set({
          'email': user.email,
          'playerName': user.displayName ?? 'Anonymous',
          'rating': 1000,
          'premium': false,
          'avatarUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      DocumentSnapshot userData = await _firestore.collection('users').doc(user!.uid).get();
      Provider.of<UserModel>(context, listen: false).setUser(
        userData['email'],
        userData['playerName'],
        userData['rating'],
        userData['premium'],
        userData['avatarUrl'],
      );

      return {'user': user, 'isNewUser': isNewUser};
    } catch (e) {
      throw FirebaseAuthException(
          code: 'google-sign-in-failed', message: e.toString());
    }
  }
}
