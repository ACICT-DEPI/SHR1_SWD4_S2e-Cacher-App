import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/auth/cubit/auth_cubit.dart';
import 'package:flutter_application_1/ui/auth/cubit/auth_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ignore: must_be_immutable
class CustomImagePicker extends StatelessWidget {
  AuthCubit authCubit;
  CustomImagePicker({
    super.key,
    required this.authCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
        bloc: authCubit,
        builder: (context, state) {
          return Stack(
            children: [
              InkWell(
                onTap: () => authCubit.imageFromGallery,
                child: CircleAvatar(
                  backgroundColor: const Color.fromRGBO(143, 148, 251, 1),
                  backgroundImage: authCubit.selectedImage != null
                      ? FileImage(File(authCubit.selectedImage!.path))
                      : null,
                  radius: 55,
                ),
              ),
              Positioned(
                bottom: 0,
                right: -10,
                child: IconButton(
                  onPressed: () => authCubit.imageFromGallery(),
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              )
            ],
          );
        });
  }
}
