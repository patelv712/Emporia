import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:practice_project/components/background.dart";
import "package:practice_project/components/product_tile.dart";
import "package:practice_project/components/user_tile.dart";
import "package:practice_project/screens/for_you_page.dart";
import "package:practice_project/screens/product_page.dart";
import "package:practice_project/screens/product_page_description.dart";

class UserProducts extends StatefulWidget {
  final String userUid;

  const UserProducts({
    required this.userUid,
    Key? key,
  }) : super(key: key);

  @override
  State<UserProducts> createState() => _UserProductsState();
}

class _UserProductsState extends State<UserProducts> {
  late Stream<List<Product>> _productsStream;
 
  @override
  void initState() {
    super.initState();
    _productsStream = loadUserProductsRealTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.userUid == FirebaseAuth.instance.currentUser!.uid)?  const Text("Your Products"): const Text(" "),
      ),
      body: Container(
        decoration: gradientDecoration(),
        child: StreamBuilder<List<Product>>(
          stream: _productsStream,
          builder:
              (BuildContext context, AsyncSnapshot<List<Product>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Some error occurred'));
            }

            final List<Product>? userItems = snapshot.data;

            if (userItems == null || userItems.isEmpty) {
              return const Center(
                child: Text(
                  'No Listings',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: userItems.length,
              itemBuilder: (context, index) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTileProduct(
                      product: userItems[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(userItems[index]),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Stream<List<Product>> loadUserProductsRealTime() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userUid) // Use the provided user UID
        .snapshots()
        .asyncMap((snapshot) async {
      final userListingIds = List<String>.from(snapshot['userListings'] ?? []);
      final userProducts = await getUserProducts(userListingIds);
      return userProducts;
    });
  }

  Future<List<Product>> getUserProducts(List<String> userListingIds) async {
    List<Product> userProducts = [];

    for (final id in userListingIds) {
      final snapshot =
          await FirebaseFirestore.instance.collection('products').doc(id).get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final product = Product(
          id: data['id'],
          name: data['name'],
          description: data['description'],
          price: data['price'].toDouble(),
          images: List<String>.from(data['images']),
          vendor: data['vendor'],
          isLiked: data['isLiked'],
          timeAdded: data['timeAdded'],
          productGenre: List<bool>.from(data['productGenre']),
        );
        userProducts.add(product);
      }
    }

    return userProducts;
  }
}

Future<void> addUserListing(
    Map<String, String> productIDMappings, Product product) async {
  try {
    // Get the current user reference
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case when no user is signed in
      throw Exception('No user signed in');
    }

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    List<String> userListings = await getUserListings();

    userListings.add(productIDMappings[product.id]!);
    updateUserListings(userRef, userListings);
  } catch (error) {
    // Handle errors here
    print('Error adding user listing: $error');
  }
}

Future<void> removeUserListing(
    Map<String, String> productIDMappings, String productId) async {
  try {
    // Get the current user reference
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case when no user is signed in
      throw Exception('No user signed in');
    }

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    List<String> userListings = await getUserListings();

    userListings.remove(productIDMappings[productId]!);
    updateUserListings(userRef, userListings);
  } catch (error) {
    // Handle errors here
    print('Error adding user listing: $error');
  }
}

void updateUserListings(
    DocumentReference userRef, List<String> userListings) async {
  try {
    await userRef.update({'userListings': userListings});
    print('User favorites updated successfully');
  } catch (e) {
    print('Error updating user favorites: $e');
    // Handle error appropriately, such as showing a snackbar or dialog to the user
  }
}

Future<List<String>> getUserListings() async {
  try {
    // Retrieve the document snapshot from Firestore
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    // Check if the document exists
    if (!snapshot.exists) {
      throw Exception('User not found');
    }

    // Extract user listings from the document data
    List<String>? userListings = snapshot.data()?['userListings'] != null
        ? List<String>.from(snapshot.data()?['userListings'])
        : [];

    return userListings;
  } catch (e) {
    // Handle errors
    print('Error retrieving user listings: $e');
    rethrow; // Rethrow the exception to be caught by the caller
  }
}
