import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:practice_project/screens/user_products.dart';

class RoundedRectangularFeaturedUser extends StatefulWidget {
  final String userUid;

  const RoundedRectangularFeaturedUser({
    required this.userUid,
    Key? key,
  }) : super(key: key);

  @override
  _RoundedRectangularFeaturedUserState createState() =>
      _RoundedRectangularFeaturedUserState();
}

class _RoundedRectangularFeaturedUserState
    extends State<RoundedRectangularFeaturedUser> {
  Map<String, int> userListingCount = {};

  @override
  void initState() {
    super.initState();
    updateUserListingsLength();
  }

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

  @override
  Widget build(BuildContext context) {
    // Sort userListingCount map keys (user UIDs) by value (number of products listed)
    final sortedUserUids = userListingCount.keys.toList()
      ..sort((a, b) => userListingCount[b]!.compareTo(userListingCount[a]!));

    const SizedBox(height: 10);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProducts(userUid: widget.userUid),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 400,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            color: Colors.white,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<String>(
                  future: getUserFullName(widget.userUid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.black));
                    } else {
                      return Text(
                        'Check out ${snapshot.data}\'s Products!',
                        style: TextStyle(color: Colors.black),
                        textAlign: TextAlign.center,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String> getUserFullName(String uid) async {
  final userNameSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final firstName = userNameSnapshot['firstname'];
  final lastName = userNameSnapshot['lastname'];
  return '$firstName $lastName';
}
