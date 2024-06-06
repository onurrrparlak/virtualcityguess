import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/user_model.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize Firebase
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Stream to listen for changes in authentication state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
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
          'createdAt': FieldValue.serverTimestamp(),
        });

        Provider.of<UserModel>(context, listen: false).setUser(email, playerName, 1000, false); // Set user data locally

        await user.sendEmailVerification();
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Check if player name is already taken
  Future<bool> isPlayerNameAvailable(String playerName) async {
    final result = await _firestore.collection('users').where('playerName', isEqualTo: playerName).get();
    return result.docs.isEmpty;
  }

  // Sign in with email and password
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

  // Sign out
  Future<void> signOut(BuildContext context) async {
    try {
      Provider.of<UserModel>(context, listen: false).setUser('', '', 0, false); // Clear user data locally
      final userBox = await Hive.openBox<UserModel>('userBox');
      await userBox.clear(); // Clear the Hive box
      await _auth.signOut(); // Sign out the user
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print(e.toString());
    }
  }

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle(BuildContext context) async {
    try {
      print('Attempting Google sign-in...');
      final GoogleSignIn googleSignIn = GoogleSignIn();

      print('Starting Google sign-in process...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign-in cancelled or failed.');
        return {'user': null, 'isNewUser': false};
      }

      print('Google sign-in successful, getting authentication...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Authenticating with Firebase...');
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      bool isNewUser = result.additionalUserInfo!.isNewUser;

      if (isNewUser) {
        print('New user detected, creating user document...');
        await _firestore.collection('users').doc(user!.uid).set({
          'email': user.email,
          'playerName': user.displayName ?? 'Anonymous',
          'rating': 1000,
          'premium': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print('Fetching user data from Firestore...');
      DocumentSnapshot userData = await _firestore.collection('users').doc(user!.uid).get();
      Provider.of<UserModel>(context, listen: false).setUser(
        userData['email'],
        userData['playerName'],
        userData['rating'],
        userData['premium'],
      );

      print('Sign-in successful. Returning user data.');
      return {'user': user, 'isNewUser': isNewUser};
    } catch (e) {
      print('Error during Google sign-in: $e');
      throw FirebaseAuthException(
          code: 'google-sign-in-failed', message: e.toString());
    }
  }
}
