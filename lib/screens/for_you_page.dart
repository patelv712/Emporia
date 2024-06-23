import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:practice_project/components/product_tile.dart";
import "package:practice_project/components/user_tile.dart";
import "package:practice_project/screens/product_page.dart";
import 'package:practice_project/components/background.dart';
import "package:practice_project/screens/product_page_description.dart";

final CollectionReference products =
    FirebaseFirestore.instance.collection('products');
final String _email = FirebaseAuth.instance.currentUser!.email.toString();
List<UserDuration> userDurations = [];
final Map<String, String> productIDMappings = {};
int userCount = 0;

class ForYouPage extends StatefulWidget {
  ForYouPage({Key? key}) : super(key: key);

  @override
  State<ForYouPage> createState() => _ForYouPageState();
}

class UserDuration {
  late String user;
  late int durationSeconds;

  UserDuration(this.user, this.durationSeconds);
  String toString() {
    return '(User: $user, Duration: $durationSeconds seconds)';
  }
}

class _ForYouPageState extends State<ForYouPage> with WidgetsBindingObserver {
  late DateTime _pageOpenTime;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _pageOpenTime = DateTime.now();
    WidgetsBinding.instance?.addObserver(this);
    updateUserListingsLength();
    userCount = 0;
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    _trackPageDuration();
  }

  void _trackPageDuration() {
    DateTime pageCloseTime = DateTime.now();
    Duration duration = pageCloseTime.difference(_pageOpenTime);
    print("$_email spent ${duration.inSeconds} seconds on ForYouPage.");
    userDurations.add(UserDuration(_email, duration.inSeconds));
    print(userDurations);
    // You can send this duration to analytics or store it as needed
  }

  Map<String, int> userListingCount = {};

  Future<void> updateUserListingsLength() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final usersSnapshot = await usersCollection.get();

    // Iterate over each user document
    for (final userDoc in usersSnapshot.docs) {
      final userUid = userDoc.id;
      final userListings =
          userDoc['userListings'] ?? []; // Assume it's a list of strings
      final userListingsLength = userListings.length;

      // Fetch user's first name and last name
      final userNameSnapshot = await usersCollection.doc(userUid).get();
      final firstName = userNameSnapshot['firstname'];
      final lastName = userNameSnapshot['lastname'];

      // Combine first name and last name to form user name
      final userName = '$firstName $lastName';

      setState(() {
        userListingCount[userUid] = userListingsLength;
      });
    }
  }

  Future<List<Product>> loadUserProducts() async {
    List<Product> userItems = await userPreferenceProducts(await getProducts());
    return userItems;
  }

  Future<List<Product>> getProducts() async {
    QuerySnapshot querySnapshot = await products.get();

    List<Product> productList = [];

    for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      productList.add(Product(
        id: data['id'],
        name: data['name'],
        description: data['description'],
        price: data['price'].toDouble(),
        images: List<String>.from(data['images']),
        isLiked: data['isLiked'],
        vendor: data['vendor'],
        timeAdded: data['timeAdded'],
        productGenre: List<bool>.from(data['productGenre']),
      ));

      productIDMappings[data['id']] = documentSnapshot.id;
    }

    return productList;
  }

  bool isUsersOver = true;

  void checkAndUpdateCondition() {
    // Example: Check some condition and update the variable
    setState(() {
      isUsersOver = !isUsersOver; // Toggle the condition for example purposes
    });
  }

  List<String> computeSortedUserIds(Map<String, int> userListingCount) {
    // Filter out mappings where the value is 0
    final filteredUserIds = userListingCount.entries
        .where((entry) => entry.value != 0)
        .toList(growable: false);

    // Sort the filtered user IDs in descending order based on their counts
    filteredUserIds.sort((a, b) => b.value.compareTo(a.value));

    // Extract only the user IDs
    final sortedUserIds = filteredUserIds.map((entry) => entry.key).toList();

    return sortedUserIds;
  }

  @override
  Widget build(BuildContext context) {
    final sortedUserUids = computeSortedUserIds(userListingCount);
    userCount = 0;


    int calculateItemCount(int totalItems) {
      // Number of rows with small tiles (2 items each)
      final smallTileRows = (totalItems / 2).ceil();
      // Number of large tiles
      final largeTiles = totalItems % 2;
      return smallTileRows + largeTiles;
    }

    bool isLargeTileIndex(int index, int totalItems) {
      // Check if index is the last item or falls on an odd index after small tile rows
      return index == totalItems - 1 ||
          index % 2 == 1 && index > (totalItems / 2).floor() * 2;
    }

    return Scaffold(
      body: Container(
        decoration: gradientDecoration(), // Applying the gradient decoration
        child: FutureBuilder<List<dynamic>>(
            future: loadUserProducts(),
            builder:
                (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Some error occurred'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 22, // Adjust the font size as needed
                      color: Colors.white, // Set the color to white
                    ),
                  ),
                );
              }

              List<dynamic> userItems = List<dynamic>.from(snapshot.data!);

              print(userItems);
              return ListView.separated(
                  itemBuilder: (context, index) {
                    print("out: $index");
                    final rowIndex = index ~/ 2; // Calculate row index
                    final firstItemIndex = index * 2;
                    final secondItemIndex = firstItemIndex + 1;

                    print("in: $index");

                    if(secondItemIndex < userItems.length && firstItemIndex < userItems.length){
                    return Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 10,
                                left: 5,
                                right:
                                    10), // Add padding of 5 pixels on all sides
                            child: SquareTileProduct(
                              product: userItems[firstItemIndex],
                              onTap: () {
                                analytics.logViewItem(
                                    currency: 'usd',
                                    value: userItems[firstItemIndex].price,
                                    parameters: <String, dynamic>{
                                      'name': userItems[firstItemIndex].name,
                                      'id': userItems[firstItemIndex].id,
                                      'vendor':
                                          userItems[firstItemIndex].vendor,
                                      'productGenre': userItems[firstItemIndex]
                                          .productGenre
                                          .toString()
                                    });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                        userItems[firstItemIndex]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Spacing between tiles
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 10,
                                left: 5,
                                right:
                                    10), // Add padding of 5 pixels on all sides
                            child: SquareTileProduct(
                              product: userItems[secondItemIndex],
                              onTap: () {
                                analytics.logViewItem(
                                    currency: 'usd',
                                    value: userItems[secondItemIndex].price,
                                    parameters: <String, dynamic>{
                                      'name': userItems[secondItemIndex].name,
                                      'id': userItems[secondItemIndex].id,
                                      'vendor':
                                          userItems[secondItemIndex].vendor,
                                      'productGenre': userItems[secondItemIndex]
                                          .productGenre
                                          .toString()
                                    });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                        userItems[secondItemIndex]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  else if(firstItemIndex < userItems.length) {
                    return Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                  left: 5,
                                  right:
                                      205), // Add padding of 5 pixels on all sides
                              child: SquareTileProduct(
                                product: userItems[firstItemIndex],
                                onTap: () {
                                  analytics.logViewItem(
                                      currency: 'usd',
                                      value: userItems[firstItemIndex].price,
                                      parameters: <String, dynamic>{
                                        'name': userItems[firstItemIndex].name,
                                        'id': userItems[firstItemIndex].id,
                                        'vendor':
                                            userItems[firstItemIndex].vendor,
                                        'productGenre':
                                            userItems[firstItemIndex]
                                                .productGenre
                                                .toString()
                                      });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(
                                          userItems[firstItemIndex]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                        ],
                      );

                  }
                  }
                  ,
                  separatorBuilder: (context, index) {
                    if (index < sortedUserUids.length) {
                      return Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(
                                  10), // Add padding of 10 pixels vertically
                              child: RoundedRectangularFeaturedUser(
                                userUid: sortedUserUids[index],
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                  itemCount: userItems.length + sortedUserUids.length);
            }

            // return Center(
            //   child: Container(
            //     padding:
            //         const EdgeInsets.all(15), // Add padding around all borders
            //     child: CustomScrollView(
            //       slivers: [
            //         SliverGrid(
            //           gridDelegate:
            //               const SliverGridDelegateWithMaxCrossAxisExtent(
            //             maxCrossAxisExtent:
            //                 400, // Adjust width based on your item size
            //             mainAxisSpacing: 10,
            //             crossAxisSpacing: 10,
            //           ),
            //           delegate: SliverChildBuilderDelegate(
            //             (context, index) {
            //               print(index);
            //               final isSpecialItem =
            //                   userItems[index].runtimeType == String;

            //               if (isSpecialItem) {
            //                 return Row(
            //                   children: [
            //                     Expanded(
            //                       child: RoundedRectangularFeaturedUser(
            //                         userUid: userItems[index],
            //                       ),
            //                     ),
            //                   ],
            //                 );
            //               } else {
            //                 // Handle remaining items (either two per row or single if list is odd-sized)
            //                 final firstItemIndex =
            //                     index; // Calculate first item index for the row
            //                 final secondItemIndex = firstItemIndex + 1;

            //                 if (userItems[secondItemIndex].runtimeType !=
            //                         String &&
            //                     secondItemIndex < userItems.length) {
            //                   // Two items in a row (if available)
            //                   final firstItem = userItems[firstItemIndex];
            //                   final secondItem = userItems[secondItemIndex];
            //                   index += 2;
            //                   return Row(
            //                     children: [
            //                       SquareTileProduct(
            //                         product: firstItem,
            //                         onTap: () {
            //                           analytics.logViewItem(
            //                               currency: 'usd',
            //                               value: userItems[index].price,
            //                               parameters: <String, dynamic>{
            //                                 'name': userItems[index].name,
            //                                 'id': userItems[index].id,
            //                                 'vendor': userItems[index].vendor,
            //                                 'productGenre': userItems[index]
            //                                     .productGenre
            //                                     .toString()
            //                               });
            //                           Navigator.push(
            //                             context,
            //                             MaterialPageRoute(
            //                               builder: (context) =>
            //                                   ProductDetailScreen(
            //                                       userItems[index]),
            //                             ),
            //                           );
            //                         },
            //                       ),
            //                       const SizedBox(width: 15),
            //                       SquareTileProduct(
            //                         product: secondItem,
            //                         onTap: () {
            //                           analytics.logViewItem(
            //                               currency: 'usd',
            //                               value: userItems[index].price,
            //                               parameters: <String, dynamic>{
            //                                 'name': userItems[index].name,
            //                                 'id': userItems[index].id,
            //                                 'vendor': userItems[index].vendor,
            //                                 'productGenre': userItems[index]
            //                                     .productGenre
            //                                     .toString()
            //                               });
            //                           Navigator.push(
            //                             context,
            //                             MaterialPageRoute(
            //                               builder: (context) =>
            //                                   ProductDetailScreen(
            //                                       userItems[index]),
            //                             ),
            //                           );
            //                         },
            //                       ),
            //                     ],
            //                   );
            //                 }  else {
            //                   // Single item if list is odd-sized and no more items
            //                   return Row(
            //                     children: [
            //                       Text("s"),
            //                       SquareTileProduct(
            //                         product: userItems[firstItemIndex],
            //                         onTap: () {
            //                           analytics.logViewItem(
            //                               currency: 'usd',
            //                               value: userItems[index].price,
            //                               parameters: <String, dynamic>{
            //                                 'name': userItems[index].name,
            //                                 'id': userItems[index].id,
            //                                 'vendor': userItems[index].vendor,
            //                                 'productGenre': userItems[index]
            //                                     .productGenre
            //                                     .toString()
            //                               });
            //                           Navigator.push(
            //                             context,
            //                             MaterialPageRoute(
            //                               builder: (context) =>
            //                                   ProductDetailScreen(
            //                                       userItems[index]),
            //                             ),
            //                           );
            //                         },
            //                       ),
            //                     ],
            //                   );
            //                 }
            //               }
            //             },
            //             childCount: userItems.length,
            //           ),
            //         ),
            //       ],
            //     ),

            //     /*

            // return Center(
            //   child: Container(
            //       padding: const EdgeInsets.all(
            //           15), // Add padding around all borders
            //       child: GridView.custom(
            //         gridDelegate: SliverStairedGridDelegate(
            //           crossAxisSpacing: 15,
            //           mainAxisSpacing: 0,
            //           startCrossAxisDirectionReversed: true,
            //           pattern: generatePattern(isUsersOver),
            //         ),
            //         childrenDelegate: SliverChildBuilderDelegate(
            //           (context, index) {
            //             if (index < userItems.length) {
            //               if (userCount < sortedUserUids.length &&
            //                   (index + 1) % 3 == 0) {
            //                 if (userCount < sortedUserUids.length) {
            //                   return Padding(
            //                     padding:
            //                         const EdgeInsets.only(top: 10, bottom: 10),
            //                     child: RoundedRectangularFeaturedUser(
            //                       userUid: sortedUserUids[userCount++],
            //                     ),
            //                   );
            //                 } else {
            //                   checkAndUpdateCondition();
            //                   return const SizedBox
            //                       .shrink(); // Placeholder widget if userCount exceeds sortedUserUids length
            //                 }
            //               } else {
            //                 return SquareTileProduct(
            //                   product: userItems[index],
            //                   onTap: () {
            //                     analytics.logViewItem(
            //                         currency: 'usd',
            //                         value: userItems[index].price,
            //                         parameters: <String, dynamic>{
            //                           'name': userItems[index].name,
            //                           'id': userItems[index].id,
            //                           'vendor': userItems[index].vendor,
            //                           'productGenre': userItems[index]
            //                               .productGenre
            //                               .toString()
            //                         });
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                         builder: (context) =>
            //                             ProductDetailScreen(userItems[index]),
            //                       ),
            //                     );
            //                   },
            //                 );
            //               }
            //             } else {
            //               return const SizedBox.shrink();
            //             }
            //           },
            //           childCount: userItems.length,
            //         ),
            //       )

            //     GridView.builder(
            //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //         crossAxisCount: 2, // Number of columns
            //         crossAxisSpacing: 15, // Spacing between columns
            //         mainAxisSpacing: 15, // Spacing between rows
            //         // Aspect ratio of each item (width / height)
            //       ),
            //       itemCount: userItems.length,
            //       itemBuilder: (context, index) {
            //         if ((index + 1) % 3 == 0 &&
            //             userCount < sortedUserUids.length) {
            //           return RoundedRectangularFeaturedUser(
            //             userUid: sortedUserUids[userCount++],
            //           );
            //         } else {
            //           print(userCount);
            //           return SquareTileProduct(
            //             product: userItems[index],
            //             onTap: () {
            //               analytics.logViewItem(
            //                   currency: 'usd',
            //                   value: userItems[index].price,
            //                   parameters: <String, dynamic>{
            //                     'name': userItems[index].name,
            //                     'id': userItems[index].id,
            //                     'vendor': userItems[index].vendor,
            //                     'productGenre':
            //                         userItems[index].productGenre.toString()
            //                   });
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) =>
            //                       ProductDetailScreen(userItems[index]),
            //                 ),
            //               );
            //             },
            //           );
            //         }
            //       },
            //     ),
            //     */
            //   ),
            // );

            ),
      ),
    );
  }

  Future<List<bool>> getPreferences() async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();

      if (userSnapshot.exists) {
        List<bool> preferences =
            List<bool>.from(userSnapshot['preferences'] ?? []);
        return preferences;
      } else {
        print('User document does not exist');
        return [];
      }
    } catch (e) {
      print('Error getting preferences: $e');
      return [];
    }
  }

  Future<List<Product>> userPreferenceProducts(
      List<Product> allProducts) async {
    List<Product> userPreferredProducts = [];

    List<bool> userPreferences = await getPreferences();

    for (int i = 0; i < allProducts.length; i++) {
      bool isMatch = false;
      List<bool> productGenre = allProducts[i].productGenre;

      for (int j = 0; j < 9; j++) {
        if (userPreferences[j] == true &&
            productGenre[j] == userPreferences[j]) {
          isMatch = true;
          break;
        }
      }

      if (isMatch) {
        userPreferredProducts.add(allProducts[i]);
      }
    }

    return userPreferredProducts;
  }
}
