import "dart:convert";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_stripe/flutter_stripe.dart";
import "package:practice_project/components/background.dart";
import "package:practice_project/screens/user_products.dart";
import "package:url_launcher/url_launcher.dart";
import 'package:http/http.dart' as http;

class ProfileWidget extends StatelessWidget {
  final String _email = FirebaseAuth.instance.currentUser!.email.toString();

  Future<String> getUserFullName(String uid) async {
    // Reference to the users collection in Firestore
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');

    try {
      // Fetch the user document using the UID
      final DocumentSnapshot userSnapshot =
          await usersCollection.doc(uid).get();

      // Check if the user document exists and if it has data
      if (userSnapshot.exists && userSnapshot.data() != null) {
        // Explicitly cast the data to a Map<String, dynamic>
        final Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        // Access the first and last name attributes
        final String? firstName =
            userData['firstname'] as String?; // Nullable string
        final String? lastName =
            userData['lastname'] as String?; // Nullable string

        // Check if both first name and last name are not null
        if (firstName != null && lastName != null) {
          // Construct and return the full name
          return '$firstName $lastName';
        }
      }

      // Handle the case where the user document does not exist or where first name or last name is null
      return 'User not found';
    } catch (e) {
      // Handle any errors that may occur during fetching
      print('Error fetching user: $e');
      return 'Error fetching user';
    }
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Profile',
            style: TextStyle(
                fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Email: $_email', style: TextStyle(color: Colors.white)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: FutureBuilder<String>(
            future: getUserFullName(FirebaseAuth.instance.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.white));
              } else {
                return Text('Name: ${snapshot.data}',
                    style: TextStyle(color: Colors.white));
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton(
            onPressed: () {
              // TODO
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
            ),
            child: const Text('Edit Profile',
                style: TextStyle(color: Colors.white)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ButtonGridScreen()));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
            ),
            child: const Text('Edit Preferences',
                style: TextStyle(color: Colors.white)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UserProducts(userUid: FirebaseAuth.instance.currentUser!.uid)));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
            ),
            child: const Text('My Listings',
                style: TextStyle(color: Colors.white)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton(
            onPressed: () {
              launchFeedbackForm();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
            ),
            child:
                const Text('FeedBack!', style: TextStyle(color: Colors.white)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton(
            onPressed: () {
              createStripeAccount(_email);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
            ),
            child: const Text('Create Stripe Account', style: TextStyle(color: Colors.white)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton(
            onPressed: () {
              signUserOut();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

launchFeedbackForm() async {
  Uri formsWebsite = Uri.parse('https://forms.gle/KAXmLJtCWutYXsXr5');
  if (await canLaunchUrl(formsWebsite)) {
    await launchUrl(formsWebsite);
  } else {
    throw 'Could not launch';
  }
}

class ButtonGridScreen extends StatefulWidget {
  @override
  _ButtonGridScreenState createState() => _ButtonGridScreenState();
}

class _ButtonGridScreenState extends State<ButtonGridScreen> {
  late List<bool> userPreferences;

  @override
  void initState() {
    super.initState();
    fetchUserPreferences();
  }

  Future<void> fetchUserPreferences() async {
    List<bool> preferences = await getUserPreferences();
    setState(() {
      userPreferences = preferences;
    });
  }

  final List<String> preferences = [
    "Vintage",
    "Tops",
    "Bottoms",
    "Tech",
    "Jewlery",
    "Accessories",
    "Books",
    "Shoes",
    "Decor"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Your Preferences'),
      ),
      body: Container(
        decoration: gradientDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: 9,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 3.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: CheckboxListTile(
                          value: userPreferences[index],
                          onChanged: (newValue) {
                            setState(() {
                              userPreferences[index] = !userPreferences[index];
                              
                            });
                          },
                          title: Text(
                            preferences[index],
                            style: TextStyle(fontSize: 16.0),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor:
                              Colors.purple[100], // Adjust the selected color
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.0), // Spacer

// Submit Button
              ElevatedButton(
                onPressed: () {
                  try {
                    FirebaseAuth user = FirebaseAuth.instance;

                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.currentUser?.uid)
                        .set({
                      'uid': user.currentUser?.uid,
                      'email': user.currentUser!.email,
                      'preferences': userPreferences,
                    }, SetOptions(merge: true));

                    Navigator.pop(context);
                  } on FirebaseAuthException catch (exception) {}
                },
                child: Text('Update'),
              ),
              SizedBox(height: 30.0),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<bool>> getUserPreferences() async {
    // Get the current user's UID
    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Get the user's preferences document from Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users') // Change to your Firestore collection name
              .doc(uid) // Use the UID to identify the specific user
              .get();

      // Check if the document exists
      if (snapshot.exists) {
        // Retrieve the "preferences" field from the document
        List<dynamic> preferences = snapshot.data()!['preferences'];

        // Return the preferences'

        List<bool> prefs = preferences.map((dynamic value) {
          if (value is bool) {
            return value;
          }
          return false;
        }).toList();

        return prefs;
      } else {
        // Document does not exist
        print('User preferences not found.');
        return [false, false, false, false, false, false, false, false, false];
      }
    } catch (e) {
      // Handle errors
      print('Error getting user preferences: $e');
      return [false, false, false, false, false, false, false, false, false];
    }
  }
}

Future<void> createStripeAccount(String email) async {
    // Replace 'your-cloud-function-url' with the URL of your Firebase Cloud Function
    const cloudFunctionUrl =
        'https://us-central1-cs4261assignment1.cloudfunctions.net/createStripeAccount';

    try {
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        
        body: jsonEncode(<String, String>{
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        // Stripe account created successfully
        print('Stripe account created successfully');
        final responseData = jsonDecode(response.body);
        final accountId = responseData['accountId'];
        print('Stripe Account ID: $accountId');
      } else {
        // Failed to create Stripe account
        print('Failed to create Stripe account');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      // Error occurred while making the request
      print('Error creating Stripe account: $error');
    }
  }

