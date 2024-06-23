import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:practice_project/components/my_button.dart';
import 'package:practice_project/components/my_test_field.dart';
import 'package:practice_project/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:practice_project/services/aut_services.dart';

class HomeScreen extends StatefulWidget {
  final Function()? onTap;
  const HomeScreen({super.key, required this.onTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final Map<String?, String> uidEmailMappings = {};

class _HomeScreenState extends State<HomeScreen> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  //sign user
  void signUserIn() async {
    //Navigator.pop(context);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);

      FirebaseAuth user = FirebaseAuth.instance;

      FirebaseFirestore.instance
          .collection('users')
          .doc(user.currentUser?.uid)
          .set({
        'uid': user.currentUser?.uid,
        'email': user.currentUser!.email,
      }, SetOptions(merge: true));
      if (!uidEmailMappings.containsKey(user.currentUser!.email)) {
        uidEmailMappings[user.currentUser!.email] = user.currentUser!.uid;
      }
    } on FirebaseAuthException catch (exception) {
      wrongInputMessage(exception.toString());
    }
    await analytics.logLogin();
  }

  void wrongInputMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF9A69AB), // Dark Purple
              Color(0xFFC4A5E8), // Lighter Shade of Purple
              Color(0xFFFF6F61), // Contrasting Color
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),

                //FlutterLogo(size: 100), // Temporary placeholder for logo
                // Make sure your logo is in the assets and properly linked in pubspec.yaml
                Image.asset('lib/images/new_logo.jpg', width: 200, height: 200),

                SizedBox(height: 24),

                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'Log in to your account',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),

                SizedBox(height: 48),

                // Email Input Field
                _buildInputField(
                  icon: Icons.email,
                  hintText: 'Email',
                  controller: emailController,
                  obscureText: false,
                ),

                SizedBox(height: 16),

                // Password Input Field
                _buildInputField(
                  icon: Icons.lock,
                  hintText: 'Password',
                  controller: passwordController,
                  obscureText: true,
                ),

                SizedBox(height: 24),

                // Sign In Button
                ElevatedButton(
                  onPressed: signUserIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    shape: StadiumBorder(),
                    elevation: 5,
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                SizedBox(height: 30),
                // Registration prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        ' Register Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    required bool obscureText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
