
import 'package:flutter/material.dart';

import '../auth/cubit/auth_cubit.dart';

class CustomAuthButton extends StatelessWidget {
  const CustomAuthButton(
      {super.key,
      required this.authCubit,
      required this.doOperation,
      required this.operation});
  final String operation;
  final Function() doOperation;
  final AuthCubit authCubit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: doOperation,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: [
              Color.fromRGBO(143, 148, 251, 1),
              Color.fromRGBO(143, 148, 251, .6),
            ])),
        child: Center(
          child: Text(
            operation,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
