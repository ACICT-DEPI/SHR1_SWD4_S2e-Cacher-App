import 'package:flutter/material.dart';

class CustomAuthContainer extends StatelessWidget {
  final TextEditingController name;    // New field for name
  final TextEditingController email;
  final TextEditingController password;
  final GlobalKey<FormState> formKey;
  final bool isLogin;

  const CustomAuthContainer({
    super.key,
    required this.name,    // Add name to constructor
    required this.email,
    required this.password,
    required this.formKey,
    required this.isLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Name Field
          if(isLogin == false)
          TextFormField(
            validator: (value) {
              if (name.text.isEmpty) {
                return "من فضلك قم بإدخال اسم المحل";
              }
              return null;
            },
            controller: name,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "اسم المحل",
              hintStyle: TextStyle(color: Colors.grey[700]),
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          if(isLogin == false)
          const Divider(height: 1),

          // Email Field
          TextFormField(
            validator: (value) {
              if (email.text.isEmpty) {
                return "من فضلك قم بإدخال البريد الإلكتروني الخاص بك";
              }
              if (!email.text.contains('@')) {
                return "من فضلك أدخل بريد إلكتروني صالح";
              }
              return null;
            },
            controller: email,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "البريد الإلكتروني",
              hintStyle: TextStyle(color: Colors.grey[700]),
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          const Divider(height: 1),

          // Password Field
          TextFormField(
            validator: (value) {
              if (password.text.isEmpty) {
                return "من فضلك قم بإدخال الرقم السري الخاص بك";
              }
              if (password.text.length < 6) {
                return "الرقم السري الخاص بك أقل من 6";
              }
              return null;
            },
            controller: password,
            obscureText: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "من فضلك أدخل الرقم السري",
              hintStyle: TextStyle(color: Colors.grey[700]),
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
