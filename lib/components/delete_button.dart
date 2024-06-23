import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:practice_project/screens/for_you_page.dart';
import 'package:practice_project/screens/product_page.dart';

class DeleteButton extends StatelessWidget {
  final void Function()? onTap;
  String productID;

  DeleteButton({Key? key, required this.onTap, required this.productID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show confirmation dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirmation"),
              content: Text("Are you sure you want to delete this product?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    // Close the dialog and do nothing
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Close the dialog and execute the onTap function
                    Navigator.of(context).pop();
                    if (onTap != null) {
                      onTap!();
                    }
                  },
                  child: Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      child: Icon(
        Icons.delete,
        color: Colors.red,
      ),
    );
  }
}


