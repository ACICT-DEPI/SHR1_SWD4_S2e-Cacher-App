import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_application_1/ui/auth/cubit/auth_cubit.dart';
import 'package:flutter_application_1/ui/auth/cubit/auth_states.dart';
import 'package:flutter_application_1/ui/auth/login_screen.dart';
import 'package:flutter_application_1/ui/widgets/custom_auth_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../main screen/main_screen.dart';
import '../widgets/custom_auth_fields.dart';
import '../widgets/custom_background.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/custom_image_picker.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthStateLoading) {
            showLoadingDialog(context); // Show loading dialog when loading
          } else if (state is AuthStateSuccess) {
            hideLoadingDialog(context); // Hide the loading dialog
            // Proceed with navigation or success actions
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          } else if (state is AuthStateError) {
            hideLoadingDialog(
                context); // Ensure the loading dialog is hidden before showing the error
            showErrorDialog(context, state.error); // Show the error dialog
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                BackGround(
                  txt: "إنشاء حساب",
                  isLogin: Positioned(
                    top: 270,
                    left: MediaQuery.of(context).size.width / 3,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 1600),
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          // Access the AuthCubit only after it's been provided
                          final authCubit = context.read<AuthCubit>();

                          return CustomImagePicker(
                            authCubit: authCubit, // Provide AuthCubit
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      FadeInUp(
                        duration: const Duration(milliseconds: 1800),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color.fromRGBO(143, 148, 251, 1),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(143, 148, 251, .2),
                                blurRadius: 20.0,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                final authCubit = context.read<AuthCubit>();
                                return Column(
                                  children: [
                                    CustomAuthContainer(
                                      email: authCubit.email,
                                      name: authCubit.name,
                                      password: authCubit.password,
                                      formKey: authCubit.formKeyregister,
                                      isLogin: false,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1800),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              final authCubit = context.read<AuthCubit>();
                              return TextFormField(
                                controller: authCubit.registrationCode,
                                decoration: const InputDecoration(
                                  labelText: 'أدخل كلمة السر',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(143, 148, 251, 1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(143, 148, 251, 1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(143, 148, 251, 1),
                                      width: 2,
                                    ),
                                  ),
                                  alignLabelWithHint: true,
                                  floatingLabelAlignment:
                                      FloatingLabelAlignment.start,
                                ),
                                textAlign: TextAlign.right,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال كلمة السر';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1900),
                        child: BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final authCubit = context.read<AuthCubit>();
                            return CustomAuthButton(
                              authCubit: authCubit,
                              doOperation: () {
                                authCubit.register(
                                    context); // Use context for registration
                              },
                              operation: 'إنشاء حساب',
                            );
                          },
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
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "لديك حساب بالفعل؟ قم بتسجيل الدخول",
                            style: TextStyle(
                              color: Color.fromRGBO(143, 148, 251, 1),
                            ),
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
