import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  // Registration function
  static Future<void> registerUser({
    required String username,
    required String email,
    required String password,
    required String dob,
    required String mobile,
  }) async {
    try {
      // 1️⃣ Create user in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid; // Get UID

      // 2️⃣ Store additional user info in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'dob': dob,
        'mobile': mobile,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("User registered successfully!");
    } on FirebaseAuthException catch (e) {
      print("Auth Error: ${e.message}");
      rethrow;
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }
}