import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_application_1/ui/auth/cubit/auth_cubit.dart';
import 'package:flutter_application_1/ui/auth/cubit/auth_states.dart';
import 'package:flutter_application_1/ui/auth/register_screen.dart';
import 'package:flutter_application_1/ui/widgets/custom_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../main screen/main_screen.dart';
import '../widgets/custom_auth_button.dart';
import '../widgets/custom_auth_fields.dart';
import '../widgets/custom_dialogs.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AuthCubit authCubit = AuthCubit();

    return BlocProvider(
      create: (_) => authCubit,
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthStateLoading) {
            showLoadingDialog(context); // Show loading dialog when loading
          } else if (state is AuthStateSuccess) {
            hideLoadingDialog(context); // Hide loading dialog on success
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else if (state is AuthStateError) {
            hideLoadingDialog(context); // Ensure the loading dialog is hidden before showing the error
            showErrorDialog(context, state.error); // Show error dialog
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                BackGround(txt: "تسجيل الدخول", isLogin: Container()),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 30.0, right: 30, bottom: 30),
                  child: Column(
                    children: <Widget>[
                      FadeInUp(
                        duration: const Duration(milliseconds: 1800),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color.fromRGBO(143, 148, 251, 1)),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color.fromRGBO(143, 148, 251, .2),
                                  blurRadius: 20.0,
                                  offset: Offset(0, 10))
                            ],
                          ),
                          child: CustomAuthContainer(
                            email: authCubit.email,
                            password: authCubit.password,
                            formKey: authCubit.formKeylogin,
                            isLogin: true,
                            name: authCubit.name,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1900),
                        child: CustomAuthButton(
                          authCubit: authCubit,
                          doOperation: () => authCubit.login(context),
                          operation: "تسجيل الدخول",
                        ),
                      ),
                      const SizedBox(height: 70),
                      FadeInUp(
                        duration: const Duration(milliseconds: 2000),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            "ليس لديك حساب؟ أنشئ حساب جديد",
                            style: TextStyle(
                                color: Color.fromRGBO(143, 148, 251, 1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
