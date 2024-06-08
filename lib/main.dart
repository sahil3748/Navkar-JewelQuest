import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:navkar_jewel_quest/productListing_page.dart';
import 'package:path/path.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Product Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProductListingPage(),
    );
  }
}

class ProductFormPage extends StatefulWidget {
  @override
  _ProductFormPageState createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  File? _mainImage;
  List<File> _images = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isAvailable = false;
  bool isLoading = false;

  Future<void> _pickImage(ImageSource source, bool isMainImage) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (isMainImage == true) {
        setState(() {
          _mainImage = File(pickedFile.path);
        });
      } else {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _uploadProduct() async {
      if (_formKey.currentState!.validate() && _mainImage != null) {
        try {
          setState(() {
            isLoading = true;
          });
          final productImagesRef =
              FirebaseStorage.instance.ref().child('product_images');

          // Upload main image to Firebase Storage
          final mainImageName = 'main_image.jpg';
          final mainImageTask =
              productImagesRef.child(mainImageName).putFile(_mainImage!);
          final mainImageUrl = await (await mainImageTask).ref.getDownloadURL();

          // Upload additional images to Firebase Storage
          List<String> imageUrls = [];
          for (int i = 0; i < _images.length; i++) {
            final imageFile = _images[i];
            final imageName = 'image_$i.jpg';
            final uploadTask =
                productImagesRef.child(imageName).putFile(imageFile);
            final imageUrl = await (await uploadTask).ref.getDownloadURL();
            imageUrls.add(imageUrl);
          }

          // Save product details to Firestore
          await FirebaseFirestore.instance.collection('products').add({
            'name': _nameController.text,
            'description': _descriptionController.text,
            'price': double.parse(_priceController.text),
            'is_available': _isAvailable,
            'mainImage': mainImageUrl,
            'imageList': imageUrls,
            'created_at': Timestamp.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product uploaded successfully!')),
          );

          // Clear form after successful upload
          setState(() {
            _mainImage = null;
            _images.clear();
            _nameController.clear();
            _descriptionController.clear();
            _priceController.clear();
            _isAvailable = false;
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        }
      }
    }

    removeMainImage() {}

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _mainImage != null
                  ? Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(200)),
                          child: Image.file(_mainImage!, fit: BoxFit.cover),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _mainImage = null;
                                // _images.removeAt(index);
                              });
                            },
                            child: Text('Remove Image')),
                      ],
                    )
                  : GestureDetector(
                      onTap: () {
                        _pickImage(ImageSource.gallery, true);
                      },
                      child: Container(
                          height: 200,
                          child: CircleAvatar(
                            child: Icon(
                              Icons.file_upload_outlined,
                              size: 50,
                            ),
                          )),
                    ),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Product Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Product Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ElevatedButton(
                  //   onPressed: () => _pickImage(ImageSource.gallery),
                  //   child: Text('Pick Main Image'),
                  // ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery, false),
                    child: Text('Add Additional Image'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: _images.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                Image.file(_images[index]),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _images.removeAt(index);
                                      });
                                    },
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.red,
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(child: Text('No additional images selected')),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Is Available'),
                  Switch(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              isLoading == true
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _uploadProduct,
                      child: Text('Upload Product'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
