import 'package:flutter/material.dart';
BoxDecoration gradientDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF9A69AB), // Dark Purple
        Color(0xFFC4A5E8), // Lighter Shade of Purple
        Color(0xFFFF6F61), // Contrasting Color
      ],
    ),
  );
}

BoxDecoration gradientDecoration2() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF9A69AB).withOpacity(0.8), // Starting with the contrasting color but with less opacity for subtlety
        Color(0xFFC4A5E8).withOpacity(0.8), // A lighter shade of purple but with more presence
        Color(0xFFFF6F61).withOpacity(0.8), // Ending with the dark purple
        

      ],
    ),
  );
}