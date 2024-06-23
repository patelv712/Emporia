import "package:flutter/material.dart";

class LikeButton extends StatelessWidget {
  final bool liked;
  void Function()? onTap;

  LikeButton({super.key, required this.liked, required this.onTap});

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        liked? Icons.favorite : Icons.favorite_border, 
        color: liked? Colors.red: Colors.grey, 
      ),
    );
  }
}
