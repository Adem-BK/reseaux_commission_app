import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reseaux_commission_app/models/users.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final usersCollection = FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Users?> getStoredUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      DocumentSnapshot snapshot = await usersCollection.doc(user.uid).get();

      if (snapshot.exists) {
        final userData =
            Users.fromJson(snapshot.data() as Map<String, dynamic>);
        return userData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserData(
      String userId, String nom, String prenom, String email, String tel,
      {String role = 'user'}) async {
    await usersCollection.doc(userId).set({
      'id': userId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'tel': tel,
      'recruiterId': "",
      'role': role, // Allow passing and saving the role
      // DO NOT store the password here. Firebase Auth handles it.
    });
  }

  Future<bool> loginWithPhoneAndPassword(String phone, String password) async {
    try {
      final String pseudoEmail = '$phone@app.local';
      await _auth.signInWithEmailAndPassword(
          email: pseudoEmail, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Login Error: $e');
      return false;
    } catch (e) {
      print('General Login Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
  }

  Future<bool> isAdminUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
    return adminDoc.exists;
  }
}
