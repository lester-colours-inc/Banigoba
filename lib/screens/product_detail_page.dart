import 'package:flutter/material.dart';
import 'camera_screen.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> productData;

  const ProductDetailPage({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    final imageUrl = productData['imageUrl'] ?? productData['imageURL'] ?? '';
    final name = productData['name'] ?? 'No Name';
    final category = productData['category'] ?? 'N/A';
    final subcategory = productData['subcategory'] ?? 'N/A';
    final colour = productData['colour'] ?? 'N/A';
    final gender = productData['gender'] ?? 'N/A';
    final visibility = productData['visibility'] ?? 'private';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow("Category", category),
                  _buildDetailRow("Subcategory", subcategory),
                  _buildDetailRow("Colour", colour),
                  _buildDetailRow("Gender", gender),
                  _buildDetailRow("Visibility", visibility),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D0140),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Try On",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value[0].toUpperCase() + value.substring(1),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
