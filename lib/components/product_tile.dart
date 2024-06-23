import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:practice_project/components/delete_button.dart';
import 'package:practice_project/components/like_product.dart';
import 'package:practice_project/screens/for_you_page.dart';
import 'package:practice_project/screens/product_page.dart';
import 'package:practice_project/screens/user_products.dart';
import 'package:shared_preferences/shared_preferences.dart';

import "package:practice_project/dashboard_widgets/favorites.dart";

class SquareTileProduct extends StatefulWidget {
  final Product product;
  final Function()? onTap;
  const SquareTileProduct(
      {super.key, required this.product, required this.onTap});

  @override
  State<SquareTileProduct> createState() => _SquareTileProductState();
}

class _SquareTileProductState extends State<SquareTileProduct> {
  late bool liked = false;

  late List<String> favoriteProductsID;

  late SharedPreferences prefs;

  String? userEmail = FirebaseAuth.instance.currentUser!.email;

  @override
  void initState() {
    super.initState();
    initLiked();
    print(liked);

    initializeUserData();
  }

  Future<void> initializeUserData() async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserUid);

    final userSnapshot = await userRef.get();

    if (userSnapshot.exists) {
      favoriteProductsID =
          List<String>.from(userSnapshot['favoriteProducts'] ?? []);
    } else {
      print('User document does not exist');
      favoriteProductsID = [];
    }
  }

  // Fetch initial value for 'liked' from Firestore
  Future<void> initLiked() async {
    bool userLikesProduct = await doesUserLike(widget.product);
    setState(() {
      liked = userLikesProduct;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // White border around the image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    18), // Adjust the border radius accordingly
                child: CachedNetworkImage(
                  imageUrl: widget.product.images.first,
                  fit: BoxFit.cover,
                  height: 200,
                  width: 200,
                ),
              ),
            ),
            // Product details
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                //padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  color: Colors.black.withOpacity(0.45),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Text(
                          '\$${naturalPrices(widget.product.price)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Like button
                        if (userEmail != widget.product.vendor)
                          LikeButton(
                            liked: liked,
                            onTap: () => toggleLike(),
                          )
                        else
                          DeleteButton(
                            productID: widget.product.id,
                            onTap: () => deleteProduct(widget.product.id),
                          ),
                      ],
                    ),
                    SizedBox(height: 0),
                    // Name
                    Center(
                      child: Text(
                        widget.product.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void toggleLike() async {
    setState(() {
      if (liked == false) {
        addFavorite(
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid),
          favoriteProductsID,
          productIDMappings,
          widget.product,
        );
        liked =
            true; // Update 'liked' immediately when the user likes a product
      } else {
        removeFavorite(
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid),
          favoriteProductsID,
          productIDMappings,
          widget.product,
        );
        liked =
            false; // Update 'liked' immediately when the user unlikes a product

        prefs.setBool(widget.product.id, liked);
      }
    });
  }

  void deleteProduct(String productID) async {
    try {
      await removeUserListing(
          productIDMappings, productID); // Wait for user listings to be updated
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productIDMappings[productID])
          .delete();
      productIDMappings.remove(productID);
      print('Product deleted successfully!');
    } catch (e) {
      print('Error deleting product: $e');
    }
  }
}

String naturalPrices(double price) {
  String p = price.toString();

  if (p.length > 3) {
    if (p.substring(p.length - 2) == ".0") {
      return p.substring(0, p.length - 2);
    } else if (p.substring(p.length - 2) == ".00") {
      return p.substring(0, p.length - 3);
    } else {
      return p;
    }
  }

  return p;
}

Future<bool> doesUserLike(Product product) async {
  String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  try {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .get();
    if (userSnapshot.exists) {
      List<String> favoriteProducts =
          List<String>.from(userSnapshot['favoriteProducts'] ?? []);
      return favoriteProducts.contains(productIDMappings[product.id]);
    } else {
      print('User document does not exist');
      return false;
    }
  } catch (e) {
    print('Error getting preferences: $e');
    return false;
  }
}
