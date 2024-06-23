import "dart:io";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import 'package:image_picker/image_picker.dart';
import 'package:practice_project/screens/for_you_page.dart';
import "package:practice_project/screens/product_page.dart";
import 'package:firebase_storage/firebase_storage.dart';
import 'package:practice_project/components/background.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:practice_project/screens/user_products.dart';
import 'package:uuid/uuid.dart';

class AddProduct extends StatefulWidget {
  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  File? image;
  static int counter = 0;

  String imageUrl = '';

  bool addProductButtonDisabled = false;

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

  Future<void> takePicture(ImageSource source) async {
    final pickedImage = await ImagePicker().pickImage(source: source);
    setState(() {
      image = pickedImage != null ? File(pickedImage.path) : null;
    });
  }

  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');


  Future<String> addProduct(Product product) async {
    try {
      // Add the product to Firestore
      DocumentReference docRef = await products.add({
        'name': product.name,
        'id': product.id,
        'description': product.description,
        'price': product.price,
        'images': product.images,
        'vendor': product.vendor,
        'isLiked': product.isLiked,
        'timeAdded': product.timeAdded,
        'productGenre': product.productGenre
      });

      // Return the document reference
      return docRef.id;
    } catch (error) {
      // Handle errors here
      print('Error adding product: $error');
      rethrow; // Re-throw the error for handling in the calling code
    }
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController vendorController = TextEditingController();

  bool _loading = false;

  final List<String> genres = [
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

  List<bool> selectedGenres = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  //stdout.write()

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: gradientDecoration(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Colors.white,
                  image: image != null
                      ? DecorationImage(
                          image: FileImage(File(image!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: image == null
                    ? Center(
                        child: Text(
                          'Take a picture or choose from Photos',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Your existing IconButton to pick an image from gallery
                  IconButton(
                    onPressed: () => pickImagesFromGallery(),
                    icon: const Icon(Icons.photo_library),
                  ),
                  // IconButton to capture image from camera
                  SizedBox(width: 20),
                  IconButton(
                    onPressed: () => takePicture(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                  ),
                ],
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Price'),
              ),
              SizedBox(height: 32),
              Text("Product Type"),
              SizedBox(height: 16),
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                shrinkWrap: true,
                itemCount: 9,
                itemBuilder: (BuildContext context, int index) {
                  return ElevatedButton(
                    onPressed: () {
                      // Handle button press
                      setState(() {
                        selectedGenres[index] = !selectedGenres[index];
                      });
                      //print('Button $index pressed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGenres[index]
                          ? Colors.purple[
                              100] // Change to your desired color when clicked
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            10.0), // Adjust the border radius
                      ),
                      side: const BorderSide(
                          color: Color.fromARGB(255, 74, 20, 140)),
                      padding: const EdgeInsets.all(
                          8.0), // Adjust the padding around the text
                    ),
                    child: Text(genres[index]),
                  );
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: addProductButtonDisabled
                    ? null
                    : () {
                        setState(() {
                          addProductButtonDisabled = true;
                        });

                        buttonLogic();

                        setState(() {
                          addProductButtonDisabled = false;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      addProductButtonDisabled ? Colors.grey : null,
                ),
                child: Text('Add Product'),
              ),
              if (_loading)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    ));
  }


  void buttonLogic() async {
    try {
      setState(() {
        _loading = true;
      });
      String dateAdded = DateTime.now().toString();
      String imageFileName = DateTime.now().microsecondsSinceEpoch.toString();
      Reference reference = FirebaseStorage.instance.ref();
      Reference refImages = reference.child('images');
      Reference uploadImage = refImages.child(imageFileName);

      // Compress the image before uploading
      File? compressedImage = await compressImage(File(image!.path));

      // Upload compressed image to Firebase Storage
      UploadTask uploadTask = uploadImage.putFile(compressedImage!);
      TaskSnapshot uploadSnapshot = await uploadTask;
      imageUrl = await uploadSnapshot.ref.getDownloadURL();

      var uuid = Uuid();
      String productId = uuid.v1().toString();

      // Construct the product
      Product newProduct = Product(
        name: nameController.text.trim(),
        price: double.parse(priceController.text.trim()),
        description: descriptionController.text.trim(),
        vendor: FirebaseAuth.instance.currentUser!.email.toString(),
        isLiked: false,
        images: [imageUrl],
        id: productId,
        timeAdded: dateAdded,
        productGenre: selectedGenres,
      );

      // Add product to database
      productIDMappings[newProduct.id] = await addProduct(newProduct);
      addUserListing(productIDMappings, newProduct);

      // Clear controllers and reset state
      nameController.clear();
      descriptionController.clear();
      priceController.clear();
      selectedGenres = List.filled(9, false);
      setState(() {
        image = null;
        _loading = false;
      });

      // Show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product Added!'),
          duration: Duration(milliseconds: 900),
        ),
      );
    } catch (error) {
      // Handle errors
      print('Error adding product: $error');
    }
  }

// Function to compress image
  Future<File?> compressImage(File imageFile) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        imageFile.path,
        quality: 50, // Adjust the quality as needed
      );
      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return imageFile; // Return null in case of error
    }
  }
}
