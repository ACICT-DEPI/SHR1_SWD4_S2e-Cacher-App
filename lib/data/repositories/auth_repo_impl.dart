import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // Import this package
import 'package:http/http.dart' as http;

import '../../domain/repositories/auth_repo.dart';
import '../model/manager_model.dart';

class AuthRepoImpl extends AuthRepo {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  Future<void> login(String email, String password) async {
    try {
      log('Start in login');
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      )
          .catchError((onError) {
        throw Exception(onError.toString());
      });
      log('Finish login');

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      }
    }
  }

  @override
  Future<void> register(managerModel, selectedLogo) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: managerModel.email!,
        password: managerModel.password!,
      );

      Reference storageRef = _storage
          .ref()
          .child('url_images')
          .child("${userCredential.user!.uid}.jpg");
      TaskSnapshot uploadTask =
          await storageRef.putFile(File(selectedLogo!.path));
      managerModel.logoPath = await uploadTask.ref.getDownloadURL();

      await _firestore
          .collection('managers')
          .doc(userCredential.user!.uid)
          .set(managerModel.toJson(userCredential.user!.uid));

      // Save the image locally
      await saveImageLocally(managerModel.logoPath!);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateLogo(XFile newLogo) async {
    try {
      String userId = _auth.currentUser!.uid;

      Reference storageRef = _storage.ref().child('url_images').child("$userId.jpg");
      TaskSnapshot uploadTask = await storageRef.putFile(File(newLogo.path));
      String newLogoUrl = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('managers').doc(userId).update({
        'manager_logo': newLogoUrl,
      });

      // Update the logo URL in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('managerLogoUrl', newLogoUrl);

      // Save the image locally
      await saveImageLocally(newLogoUrl);
    } catch (e) {
      throw Exception("Error updating logo: ${e.toString()}");
    }
  }

  Future<void> saveImageLocally(String imageUrl) async {
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Get the document directory path
        final directory = await getApplicationDocumentsDirectory();
        // Create a file to store the image
        final file = File('${directory.path}/logo.png');
        // Write the image to the file
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      print('Error saving image locally: $e');
    }
  }

  @override
  Future<ManagerModel?> fetchManagerData() async {
    try {
      String managerId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc =
          await _firestore.collection('managers').doc(managerId).get();

      if (doc.exists) {
        return ManagerModel.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('No manager found.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> reauthenticateUser(String password) async {
    try {
      User? user = _auth.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw Exception("Reauthentication failed: ${e.toString()}");
    }
  }

  @override
  Future<void> updateName(String newName) async {
    try {
      String userId = _auth.currentUser!.uid;
      await _firestore.collection('managers').doc(userId).update({
        'manager_name': newName,
      });
    } catch (e) {
      throw Exception("Error updating name: ${e.toString()}");
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }
}
