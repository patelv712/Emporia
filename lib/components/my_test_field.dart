import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final dynamic controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({
    super.key, 
    required this.controller, 
    required this.hintText, 
    required this.obscureText, required TextInputType keyboardType, required InputDecoration decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:const  EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField( 
        obscureText: obscureText,
        controller: controller,
        decoration:  InputDecoration(
          hintText: hintText,
          enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(255, 189, 189, 189),
            ),
          ),
          fillColor: const Color.fromARGB(255, 238, 238, 238),
          filled: true,
        ),
      ),
    );
  }
}