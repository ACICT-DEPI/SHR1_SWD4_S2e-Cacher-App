
import 'dart:io';
import 'package:flutter_application_1/domain/repositories/auth_repo.dart';
import 'package:flutter_application_1/ui/auth/cubit/auth_states.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/model/manager_model.dart';
import '../../../data/repositories/auth_repo_impl.dart';
import '../login_screen.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState());
  AuthRepo repo = AuthRepoImpl();
  late GlobalKey<FormState> formKeylogin = GlobalKey<FormState>();
  late GlobalKey<FormState> formKeyregister = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController registrationCode = TextEditingController();
  TextEditingController name = TextEditingController();
  XFile? selectedImage;

  static const String correctCode = "!@abo2005%%";

  // Method to show error dialog
  void showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Login Method
  void login(BuildContext context) {
    if (formKeylogin.currentState != null && formKeylogin.currentState!.validate()) {
      emit(AuthStateLoading());
      repo.login(email.text, password.text).then((onValue) {
        emit(AuthStateSuccess());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
      }).catchError((error) {
        emit(AuthStateError(error.toString()));
        showErrorDialog(context, error.toString());
      });
    }
  }

  // Register Method
  void register(BuildContext context) async {
  try {
    if (formKeyregister.currentState != null && formKeyregister.currentState!.validate()) {
      if (registrationCode.text == correctCode) {
        emit(AuthStateLoading());

        // Default image URL (fallback)
        const String defaultImageUrl = 'https://some-default-url.jpg';

        if (selectedImage == null) {
          // Download default image if no image is selected
          try {
            final response = await http.get(Uri.parse(defaultImageUrl));
            if (response.statusCode == 200) {
              final tempDir = await getTemporaryDirectory();
              final tempImageFile = File('${tempDir.path}/default_image.jpg');
              await tempImageFile.writeAsBytes(response.bodyBytes);
              selectedImage = XFile(tempImageFile.path);
            } else {
              throw Exception('Failed to download default image');
            }
          } catch (e) {
            emit(AuthStateError('Failed to set default image: ${e.toString()}'));
            showErrorDialog(context, 'Failed to set default image');
            return;
          }
        }

        ManagerModel managerModel = ManagerModel(
          email: email.text,
          name: name.text,
          password: password.text,
          logoPath: selectedImage!.path,
        );

        await repo.register(managerModel, selectedImage);

        // Save the image locally
        final String localImagePath = await saveImageLocally(selectedImage!.path);

        // Save local image path to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('managerLogoPath', localImagePath); // Save local image path

        emit(AuthStateSuccess());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful')),
        );
      } else {
        emit(AuthStateError("Incorrect registration code"));
        showErrorDialog(context, "Incorrect registration code");
      }
    }
  } catch (e) {
    emit(AuthStateError(e.toString()));
    showErrorDialog(context, e.toString());
  }
}
Future<String> saveImageLocally(String imagePath) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final String newPath = '${directory.path}/logo.png';

    // Copy the selected image to the app's documents directory
    final File imageFile = File(imagePath);
    final File localImageFile = await imageFile.copy(newPath);

    return localImageFile.path;  // Return the path of the saved image
  } catch (e) {
    throw Exception('Error saving image locally: $e');
  }
}



  // Method to update the user's name
  Future<void> updateName(BuildContext context, String newName) async {
    emit(AuthStateLoading());
    repo.updateName(newName).then((_) {
      name.text = newName;
      emit(AuthStateSuccess());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    }).catchError((error) {
      emit(AuthStateError(error.toString()));
      showErrorDialog(context, error.toString());
    });
  }

  // Method to update the logo
  Future<void> updateLogo(BuildContext context, XFile newLogo) async {
    emit(AuthStateLoading());
    repo.updateLogo(newLogo).then((_) {
      selectedImage = newLogo;
      emit(AuthStateSuccess());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo updated successfully')),
      );
    }).catchError((error) {
      emit(AuthStateError(error.toString()));
      showErrorDialog(context, error.toString());
    });
  }

  // Logout Method
  void logout(BuildContext context) {
    emit(AuthStateLoading());
    repo.logout().then((_) {
      emit(AuthStateLoggedOut());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }).catchError((error) {
      emit(AuthStateError(error.toString()));
      showErrorDialog(context, error.toString());
    });
  }

  // Image picker from gallery
  Future<void> imageFromGallery() async {
    try {
      XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      selectedImage = image;
      emit(UploadImageSuccess());
    } on PlatformException catch (e) {
      emit(UploadImageError(e.toString()));
    }
  }
}
