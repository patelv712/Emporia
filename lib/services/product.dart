import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

// ignore: must_be_immutable
class Product extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String vendor;
  bool isLiked;

  Product(
      {super.key,
      required this.id,
      required this.name,
      required this.description,
      required this.price,
      required this.images,
      required this.vendor,
      required this.isLiked});

  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  //Add products to database

  Future<void> addProduct(Product product) async {
    await products.add({
      'name': product.name,
      'id': product.id,
      'description': product.description,
      'price': product.price,
      'images': product.images,
      'vendor': product.vendor,
      'isLiked': product.isLiked,
    });
  }

  //retrieve all products from Firestore

  Future<List<Product>> getProducts() async {
    QuerySnapshot querySnapshot = await products.get();

    List<Product> productList = [];

    for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      products.add(Product(
        description: data['description'],
        id: data['id'],
        price: data['price'],
        name: data['name'],
        images: data['images'],
        isLiked: data['isLiked'],
        vendor: data['vendor'],
      ));

      
    }

    return productList;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
