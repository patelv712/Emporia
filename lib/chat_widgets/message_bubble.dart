import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import '../../model/message.dart';
import 'package:http/http.dart' as http;

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {super.key,
      required this.isMe,
      required this.isImage,
      required this.message,
      required this.isPayment,
      required this.isVendor,
      required this.buyer,
      required this.productId, required this.vendor, required this.isPaymentConfirmation});

  final bool isMe;
  final bool isImage;
  final bool isPayment;
  final bool isVendor;
  final Message message;
  final String buyer;
  final String productId;
  final String vendor;
  final bool isPaymentConfirmation;

  @override
  Widget build(BuildContext context) => Align(
        alignment: isMe ? Alignment.topLeft : Alignment.topRight,
        child: Container(
          decoration: BoxDecoration(
            color: isPaymentConfirmation ? Colors.green : isMe ? Colors.grey : Colors.blue,
            borderRadius: isMe
                ? const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                    topLeft: Radius.circular(30),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    topLeft: Radius.circular(30),
                  ),
          ),
          margin: const EdgeInsets.only(top: 10, right: 10, left: 10),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              isImage
                  ? Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: NetworkImage(message.content),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : !isPayment
                      ? Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            Text(
                              message.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Adjust the font size as needed
                              ),
                            ),
                            Text(
                              formatTime(message.sentTime),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : !isVendor
                          ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    Colors.blue, // Change the color as needed
                              ),
                              padding: EdgeInsets.all(10),
                              child: GestureDetector(
                                onTap: () {
                                  initPayment(buyer, message.content, context,
                                      buyer, vendor, productId);
                                },
                                child: Text(
                                  '\$${message.content}', // Replace 'Your Price' with the actual price
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    Colors.blue, // Change the color as needed
                              ),
                              padding: EdgeInsets.all(10),
                              child: Text(
                                '\$${message.content}', // Replace 'Your Price' with the actual price
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      );
}

Future<void> _sendConfirmationMessage( String message,
    String buyer, String vendor, String productId) async {
  final checksAndBalances = await FirebaseFirestore.instance
      .collection("chat")
      .where(Filter.and(
          Filter("buyer", isEqualTo: buyer),
          Filter("vendor", isEqualTo: vendor),
          Filter("productId", isEqualTo: productId)))
      .get();
  if (checksAndBalances.docs.isNotEmpty) {
    FirebaseFirestore.instance
        .collection("${checksAndBalances.docs[0].reference.path}/messages")
        .add({
      "content": message,
      "messageType": "paymentConfirmation",
      "senderId": FirebaseAuth.instance.currentUser!.email,
      "sentTime": DateTime.now()
    });
  }
}

Future<void> initPayment(String? email, String price, BuildContext context,
    buyer, vendor, productId) async {
  try {
    print("Function entered");
    final response = await http.post(
        Uri.parse(
            "https://us-central1-cs4261assignment1.cloudfunctions.net/stripePaymentIntentRequest"),
        body: {
          'email': email,
          'amount': (double.parse(price) * 100).toString(),
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

    String confirmationMessage = 'Payment of \$$price successful!';
    _sendConfirmationMessage( confirmationMessage, buyer, vendor, productId);

    await createPayout(
        "acct_1PADwaP9QGkkmOjP", (double.parse(price) * 100).toString());
  } catch (error) {
    if (error is StripeException) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error occured: ${error.error.localizedMessage}')));
    }
  }
}

String formatTime(DateTime dateTime) {
  final formattedTime = DateFormat('MM/dd hh:mm a').format(dateTime);
  return formattedTime;
}

Future<void> createPayout(String stripeAccount, String amount) async {
  try {
    final response = await http.post(
      Uri.parse(
          "https://us-central1-cs4261assignment1.cloudfunctions.net/createPayout"),
      body: {
        'stripeAccount': stripeAccount,
        'amount': amount.toString(), // Amount in cents
      },
    );

    final jsonResponse = jsonDecode(response.body);
    print(jsonResponse.toString());

    if (response.statusCode == 200) {
      print('Payout successful: ${jsonResponse}');
    } else {
      print('Payout failed: ${jsonResponse}');
      throw Exception('Failed to create payout');
    }
  } catch (e) {
    print('Error creating payout: $e');
    throw Exception('Failed to create payout: $e');
  }
}
