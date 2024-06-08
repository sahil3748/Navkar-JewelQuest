import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navkar_jewel_quest/main.dart';
import 'package:navkar_jewel_quest/product_form_page.dart';

class ProductListingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F4),
      appBar: AppBar(
        centerTitle: true,
        title: Text('Product Listing'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            final products = snapshot.data!.docs;

            if (products.isEmpty) {
              return Center(
                child: Text('No Data'),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .60),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final productData =
                    products[index].data() as Map<String, dynamic>;
                final productName = productData['name'];
                final productDescription = productData['description'];
                final productPrice = productData['price'];
                final mainImageUrl = productData['mainImage'];

                return GestureDetector(
                  onTap: () {
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => ProductFormPage()));
                  },
                  child: ProductItem(
                    productName: productName,
                    productDescription: productDescription,
                    productPrice: productPrice,
                    mainImageUrl: mainImageUrl,
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: !kIsWeb
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProductFormPage()));
              },
              icon: Icon(Icons.add),
              label: Text('Add Product'),
            )
          : null,
    );
  }
}

class ProductItem extends StatelessWidget {
  final String productName;
  final String productDescription;
  final double productPrice;
  final String mainImageUrl;

  const ProductItem({
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    required this.mainImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              mainImageUrl,
              fit: BoxFit.cover,
              height: MediaQuery.sizeOf(context).height / 5,
              width: MediaQuery.sizeOf(context).width / 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 20),
                ),
                SizedBox(height: 4),
                Text(
                  productDescription,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.justify,
                  style: TextStyle(color: Colors.grey, wordSpacing: .001),
                ),
                SizedBox(height: 8),
                Text(
                  '\₹ $productPrice',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
