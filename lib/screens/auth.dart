import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import 'package:practice_project/screens/dashboard_screen.dart';
import "package:practice_project/screens/loginOrRegister.dart";
import "package:practice_project/screens/verify_email_page.dart";
import "package:practice_project/components/background.dart";

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Container(
        decoration: gradientDecoration(),
        child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return  VerifyEmailPage();
              } else {
                return const LoginOrRegisterScreen();
              }
            })));
  }
}
