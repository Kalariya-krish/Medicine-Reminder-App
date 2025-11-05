// In a file named: lib/services/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class FirebaseAuthService {
  // Registration function (Ensuring 'imageUrl' is stored)
  static Future<void> registerUser({
    required String username,
    required String email,
    required String password,
    required String dob,
    required String mobile,
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'dob': dob,
        'mobile': mobile,
        'imageUrl': 'assets/images/default_profile.png', // Default image path
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

  // Uploads a file to Firebase Storage and returns the public URL
  static Future<String> uploadProfileImageBytes(
      Uint8List imageBytes, String uid) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg'); // Use UID as file name

    // Upload raw bytes instead of a dart:io File object
    final uploadTask = storageRef.putData(imageBytes);
    final snapshot = await uploadTask.whenComplete(() {});

    // Get the downloadable URL
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Update Firestore user document with the new URL
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'imageUrl': downloadUrl,
    });

    return downloadUrl;
  }

  // Fetches user details from Firestore
  static Future<Map<String, dynamic>?> fetchUserDetails(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  // UPDATED FUNCTION: for updating non-image fields in Firestore
  static Future<void> updateUserDetails({
    required String uid,
    required String username,
    required String mobile,
    required String dob, // Added DOB
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'username': username,
      'mobile': mobile,
      'dob': dob, // Update DOB field
    });
  }
}
