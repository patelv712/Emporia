import 'package:flutter/material.dart';




class CustomTextFormField extends StatelessWidget {

  const CustomTextFormField({

    super.key,

    required this.controller,

    this.prefixIcon,

    this.suffixIcon,

    this.labelText,

    this.hintText,

    this.onPressedSuffixIcon,

    this.obscureText,

    this.onChanged,

  });




  final TextEditingController controller;

  final IconData? prefixIcon;

  final IconData? suffixIcon;

  final String? labelText;

  final String? hintText;

  final bool? obscureText;

  final VoidCallback? onPressedSuffixIcon;

  final ValueChanged<String>? onChanged;




  @override

  Widget build(BuildContext context) => TextFormField(

        controller: controller,

        obscureText: obscureText ?? false,

        onChanged: onChanged,

        decoration: InputDecoration(

          labelText: labelText,

          hintText: hintText,

          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,

          suffixIcon: suffixIcon != null

              ? IconButton(

                  onPressed: onPressedSuffixIcon,

                  icon: Icon(suffixIcon),

                )

              : null,

          border: OutlineInputBorder(

            borderRadius: BorderRadius.circular(30),

          ),

          focusedBorder: OutlineInputBorder(

            borderRadius: BorderRadius.circular(30),

            borderSide: const BorderSide(color: Color(0xff703efe)),

          ),

        ),

      );

}