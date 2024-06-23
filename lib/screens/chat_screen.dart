import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:image_picker/image_picker.dart';
import 'package:practice_project/chat_widgets/custom_text_form_field.dart';
import 'package:practice_project/chat_widgets/message_bubble.dart';
import 'package:practice_project/model/message.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    Key? key,
    required this.vendor,
    required this.productId,
    required this.buyer,
  }) : super(key: key);

  final String vendor;
  final String buyer;
  final String productId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String docRef = "none";
  final controller = TextEditingController();
  File? image;

  @override
  void initState() {
    super.initState();
    getDocRef();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void getDocRef() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("chat")
        .where('productId', isEqualTo: widget.productId)
        .where('vendor', isEqualTo: widget.vendor)
        .where('buyer', isEqualTo: widget.buyer)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        docRef = snapshot.docs[0].reference.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: docRef == "none"
                    ? null
                    : FirebaseFirestore.instance
                        .collection("$docRef/messages")
                        .orderBy("sentTime")
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.hasError) {
                    return const Center(child: Text('No messages yet!'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final Message message = Message.fromJson(
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>);
                      final bool isMe = message.senderId !=
                          FirebaseAuth.instance.currentUser!.email;
                      final isTextMessage =
                          message.messageType == MessageType.text;
                      final isPaymentMessage =
                          message.messageType == MessageType.payment;
                      final isPaymentConfirmation =  message.messageType == MessageType.paymentConfirmation;

                      return isTextMessage || isPaymentConfirmation
                          ? MessageBubble(
                              isMe: isMe,
                              message: message,
                              isImage: false,
                              isPayment: false,
                              isVendor: widget.vendor ==
                                  FirebaseAuth.instance.currentUser?.email,
                              buyer: widget.buyer, productId: widget.productId, vendor: widget.vendor, isPaymentConfirmation: isPaymentConfirmation)
                          : isPaymentMessage
                              ? MessageBubble(
                                  isMe: isMe,
                                  message: message,
                                  isImage: false,
                                  isPayment: true,
                                  isVendor: widget.vendor ==
                                      FirebaseAuth.instance.currentUser?.email,
                                  buyer: widget.buyer, productId: widget.productId, vendor: widget.vendor, isPaymentConfirmation: isPaymentConfirmation,
                                )
                              : MessageBubble(
                                  isMe: isMe,
                                  message: message,
                                  isImage: true,
                                  isPayment: false,
                                  isVendor: widget.vendor ==
                                      FirebaseAuth.instance.currentUser?.email,
                                  buyer: widget.buyer, productId: widget.productId,
                                  vendor: widget.vendor,
                                  isPaymentConfirmation: isPaymentConfirmation
                                );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(hintText: 'Add Message...'),
                  ),
                ),
                const SizedBox(width: 5),
                CircleAvatar(
                  backgroundColor: Color(0xff703efe),
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () =>
                        _sendText(context, false, controller.text, false),
                  ),
                ),
                const SizedBox(width: 5),
                CircleAvatar(
                  backgroundColor: Color(0xff703efe),
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.image, color: Colors.white),
                    onPressed: () => sendImageMessage(context, false),
                  ),
                ),
                const SizedBox(width: 5),
                widget.vendor == FirebaseAuth.instance.currentUser!.email
                    ? GestureDetector(
                        onTap: () async {
                          String? paymentAmount = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              String? price;
                              return AlertDialog(
                                title: Text('Enter Payment Amount'),
                                content: TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter amount',
                                  ),
                                  onChanged: (value) {
                                    // You can add validation or formatting logic here if needed
                                    // For example, to ensure only numbers and decimals are entered
                                    if (value.isNotEmpty &&
                                        double.tryParse(value) == null) {
                                      // If the input is not a valid number, clear the field
                                      setState(() {
                                        price = null;
                                      });
                                    } else {
                                      setState(() {
                                        price = value;
                                      });
                                    }
                                  },
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (price != null) {
                                        _sendText(context, true, price!, false);
                                        print("Payment sent");
                                        // Validate the input here if needed
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: Text('Send'),
                                  ),
                                ],
                              );
                            },
                          );

                          // Once the dialog is closed, you can use the paymentAmount variable
                          if (paymentAmount != null) {
                            print('Payment amount entered: $paymentAmount');
                            // Implement logic to send the payment request with the entered amount
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Color(0xff703efe),
                          radius: 20,
                          child: Icon(Icons.payment, color: Colors.white),
                        ),
                      )
                    : const SizedBox()
              ],
            )
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        elevation: 0,
        foregroundColor: Colors.black,
        backgroundColor: Colors.transparent,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vendor == FirebaseAuth.instance.currentUser!.email
                        ? widget.buyer
                        : widget.vendor,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Future<void> _sendText(BuildContext context, bool isPayment, String content,
      bool isImage) async {
    if (docRef == "none") {
      print("new docref");
      final checksAndBalances = await FirebaseFirestore.instance
          .collection("chat")
          .where(Filter.and(
              Filter("buyer",
                  isEqualTo: FirebaseAuth.instance.currentUser!.email),
              Filter("vendor",
                  isEqualTo: widget.vendor),
                  Filter("productId", isEqualTo: widget.productId)))
          .get();
      if (checksAndBalances.docs.isEmpty) {
        final newChatRef =
            await FirebaseFirestore.instance.collection('chat').add({
          "productId": widget.productId,
          "vendor": widget.vendor,
          "buyer": FirebaseAuth.instance.currentUser!.email
        });
        setState(() {
          docRef = newChatRef.path;
        });
        await FirebaseFirestore.instance
            .collection("${newChatRef.path}/messages")
            .add({
          "content": content,
          "messageType": isPayment
              ? "payment"
              : isImage
                  ? "image"
                  : "text",
          "senderId": FirebaseAuth.instance.currentUser!.email,
          "sentTime": DateTime.now(),
        });
      }
    } else {
      await FirebaseFirestore.instance.collection("$docRef/messages").add({
        "content": content,
        "messageType": isPayment
            ? "payment"
            : isImage
                ? "image"
                : "text",
        "senderId": FirebaseAuth.instance.currentUser!.email,
        "sentTime": DateTime.now()
      });
    }
    controller.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> sendPaymentRequest(
      String? email, double price, BuildContext context) async {
    try {
      print("Function entered");
      final response = await http.post(
          Uri.parse(
              "https://us-central1-cs4261assignment1.cloudfunctions.net/stripePaymentIntentRequest"),
          body: {
            'email': email,
            'amount': (price * 100).toString(),
          });

      final jsonResponse = jsonDecode(response.body);
      print(jsonResponse.toString());

      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: jsonResponse['paymentIntent'],
        merchantDisplayName: 'Emporia',
        customerId: jsonResponse['customer'],
        customerEphemeralKeySecret: jsonResponse['ephemeralKey'],
      ));
      print("Made payment sheet");

      await Stripe.instance.presentPaymentSheet();
      print("done");

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment is successful')));
    } catch (error) {
      if (error is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error occured: ${error.error.localizedMessage}')));
      }
    }
  }

  Future<String> addImage(File? image) async {
    String imageFileName = DateTime.now().microsecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref();
    Reference refImages = reference.child('images');
    Reference uploadImage = refImages.child(imageFileName);

    UploadTask uploadTask = uploadImage.putFile(File(image!.path));
    TaskSnapshot uploadSnapshot = await uploadTask;
    String imageUrl = await uploadSnapshot.ref.getDownloadURL();

    return imageUrl;
  }

  Future<void> pickImagesFromGallery() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    try {
      pickedFile = await picker.pickImage(
        source: ImageSource
            .gallery, // Use ImageSource.camera for capturing from camera
      );
    } catch (e) {
      print("Error picking image: $e");
    }

    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile!.path);
      });
    }
  }

  Future<String> obtainImageUrl() async {
    pickImagesFromGallery();
    String imgFile = await addImage(image);
    return imgFile;
  }

  void sendImageMessage(BuildContext context, bool isPayment) async {
    String imageUrl = await obtainImageUrl();

    _sendText(context, isPayment, imageUrl, true);
  }
}
