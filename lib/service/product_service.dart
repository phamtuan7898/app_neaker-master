import 'dart:convert';
import 'dart:async'; // Add this for DelegatingStream
import 'dart:io'; // Add this for basename
import 'package:app_neaker/models/products_model.dart';
import 'package:path/path.dart' as path; // Add this for basename
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProductService {
  final String apiUrl = 'http://192.168.189.119:5002';
  final ImagePicker _picker = ImagePicker();

  String _formatPriceForApi(String price) {
    return price
        .replaceAll(',', '')
        .replaceAll('VND', '')
        .replaceAll(' ', '')
        .trim();
  }

  Future<void> updateProduct(
    String productId,
    String productName,
    String shoeType,
    List<XFile> newImageFiles,
    List<String> existingImages,
    String price,
    double rating,
    String description,
    List<String> color,
    List<String> size,
  ) async {
    try {
      final formattedPrice = _formatPriceForApi(price);

      List<String> newImageUrls = [];
      if (newImageFiles.isNotEmpty) {
        newImageUrls = await uploadImages(newImageFiles);
      }

      List<String> allImageUrls = [...existingImages, ...newImageUrls];

      final Map<String, dynamic> requestBody = {
        'productName': productName,
        'shoeType': shoeType,
        'image': allImageUrls,
        'price': formattedPrice,
        'rating': rating,
        'description': description,
        'color': color,
        'size': size,
      };

      print('Request body: ${json.encode(requestBody)}');

      // Update endpoint URL to match server route
      final response = await http.put(
        Uri.parse('$apiUrl/product/update/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final errorResponse = json.decode(response.body);
          throw Exception(
              'Failed to update product: ${errorResponse['error']}');
        } catch (e) {
          throw Exception('Failed to update product: ${response.body}');
        }
      }
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> addProduct(
    String productName,
    String shoeType,
    List<XFile> imageFiles,
    String price,
    double rating,
    String description,
    List<String> color,
    List<String> size,
  ) async {
    try {
      // Upload images first and get URLs
      List<String> imageUrls = await uploadImages(imageFiles);

      if (imageUrls.isEmpty) {
        throw Exception('No images were uploaded successfully');
      }

      // Create the product with image URLs
      final response = await http.post(
        Uri.parse('$apiUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productName': productName,
          'shoeType': shoeType,
          'image': imageUrls,
          'price': price,
          'rating': rating.toDouble(), // Đảm bảo gửi dưới dạng double
          'description': description,
          'color': color,
          'size': size,
        }),
      );

      if (response.statusCode == 201) {
        print('Product added successfully');
      } else {
        throw Exception('Failed to add product: ${response.body}');
      }
    } catch (e) {
      print('Error adding product: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  // Function to fetch product data
  Future<List<ProductModel>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/products'));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse
            .map((product) => ProductModel.fromJson(product))
            .toList();
      } else {
        throw Exception('Failed to load products: ${response.body}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to load products');
    }
  }

  Future<List<XFile>> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
      );
      return images;
    } catch (e) {
      print('Error picking images: $e');
      throw Exception('Failed to pick images');
    }
  }

  // Function to upload multiple images
  // Function to upload multiple images
  Future<List<String>> uploadImages(List<XFile> images) async {
    try {
      var uri = Uri.parse('$apiUrl/uploads-images');
      var request = http.MultipartRequest('POST', uri);

      // Add all files to the request
      for (var image in images) {
        var stream = http.ByteStream(Stream.castFrom(image.openRead()));
        var length = await image.length();

        var multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: path.basename(image.path),
        );

        request.files.add(multipartFile);
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Parse response
      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        // Make sure we're getting a List<String>
        List<dynamic> urls = jsonResponse['imageUrls'];
        return urls.map((url) => url.toString()).toList();
      } else {
        throw Exception(jsonResponse['error'] ?? 'Failed to upload images');
      }
    } catch (e) {
      print('Error uploading images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }

  // Trong file product_service.dart
  Future<void> deleteProduct(String productId) async {
    try {
      final response =
          await http.delete(Uri.parse('$apiUrl/products/$productId'));
      if (response.statusCode != 200) {
        final errorResponse = json.decode(response.body);
        throw Exception('Failed to delete product: ${errorResponse['error']}');
      }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
}
