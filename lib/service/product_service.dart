import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:app_neaker/models/products_model.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProductService {
  final String apiUrl;
  final ImagePicker _picker;
  final http.Client _httpClient;

  // Constructor với dependency injection
  ProductService({
    this.apiUrl = 'http://192.168.1.16:5002',
    ImagePicker? picker,
    http.Client? httpClient,
  })  : _picker = picker ?? ImagePicker(),
        _httpClient = httpClient ?? http.Client();

  // Thêm timeout constants
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  // Centralized headers
  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  String _formatPriceForApi(String price) {
    return price
        .replaceAll(RegExp(r'[,\s]'), '') // Dùng RegExp để gọn hơn
        .replaceAll('VND', '')
        .trim();
  }

  /// Xử lý response và throw exception nếu có lỗi
  void _handleErrorResponse(http.Response response, String operation) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    try {
      final errorResponse = json.decode(response.body);
      throw ProductServiceException(
        message: errorResponse['error'] ?? 'Unknown error',
        statusCode: response.statusCode,
        operation: operation,
      );
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException(
        message: response.body,
        statusCode: response.statusCode,
        operation: operation,
      );
    }
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
      // Validate inputs
      _validateProductInput(productName, shoeType, price, color, size);

      final formattedPrice = _formatPriceForApi(price);

      // Upload ảnh mới song song nếu có
      final newImageUrls = newImageFiles.isNotEmpty
          ? await uploadImages(newImageFiles)
          : <String>[];

      final allImageUrls = [...existingImages, ...newImageUrls];

      // Validate có ít nhất 1 ảnh
      if (allImageUrls.isEmpty) {
        throw ProductServiceException(
          message: 'At least one image is required',
          operation: 'updateProduct',
        );
      }

      final requestBody = {
        'productName': productName,
        'shoeType': shoeType,
        'image': allImageUrls,
        'price': formattedPrice,
        'rating': rating,
        'description': description,
        'color': color,
        'size': size,
      };

      final response = await _httpClient
          .put(
            Uri.parse('$apiUrl/api/products/$productId'),
            headers: _jsonHeaders,
            body: json.encode(requestBody),
          )
          .timeout(_requestTimeout);

      _handleErrorResponse(response, 'updateProduct');
    } on TimeoutException {
      throw ProductServiceException(
        message: 'Request timeout',
        operation: 'updateProduct',
      );
    } on SocketException {
      throw ProductServiceException(
        message: 'No internet connection',
        operation: 'updateProduct',
      );
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException(
        message: e.toString(),
        operation: 'updateProduct',
      );
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
      // Validate inputs
      _validateProductInput(productName, shoeType, price, color, size);

      if (imageFiles.isEmpty) {
        throw ProductServiceException(
          message: 'At least one image is required',
          operation: 'addProduct',
        );
      }

      final imageUrls = await uploadImages(imageFiles);

      if (imageUrls.isEmpty) {
        throw ProductServiceException(
          message: 'No images were uploaded successfully',
          operation: 'addProduct',
        );
      }

      final requestBody = {
        'productName': productName,
        'shoeType': shoeType,
        'image': imageUrls,
        'price': _formatPriceForApi(price),
        'rating': rating,
        'description': description,
        'color': color,
        'size': size,
      };

      final response = await _httpClient
          .post(
            Uri.parse('$apiUrl/api/products'),
            headers: _jsonHeaders,
            body: json.encode(requestBody),
          )
          .timeout(_requestTimeout);

      _handleErrorResponse(response, 'addProduct');
    } on TimeoutException {
      throw ProductServiceException(
        message: 'Request timeout',
        operation: 'addProduct',
      );
    } on SocketException {
      throw ProductServiceException(
        message: 'No internet connection',
        operation: 'addProduct',
      );
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException(
        message: e.toString(),
        operation: 'addProduct',
      );
    }
  }

  Future<List<ProductModel>> fetchProducts() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$apiUrl/api/products'))
          .timeout(_requestTimeout);

      _handleErrorResponse(response, 'fetchProducts');

      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((product) => ProductModel.fromJson(product))
          .toList();
    } on TimeoutException {
      throw ProductServiceException(
        message: 'Request timeout',
        operation: 'fetchProducts',
      );
    } on SocketException {
      throw ProductServiceException(
        message: 'No internet connection',
        operation: 'fetchProducts',
      );
    } on FormatException {
      throw ProductServiceException(
        message: 'Invalid response format',
        operation: 'fetchProducts',
      );
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException(
        message: e.toString(),
        operation: 'fetchProducts',
      );
    }
  }

  Future<List<XFile>> pickImages({int? maxImages}) async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 70,
        limit: maxImages,
      );
      return images;
    } catch (e) {
      throw ProductServiceException(
        message: 'Failed to pick images: ${e.toString()}',
        operation: 'pickImages',
      );
    }
  }

  Future<List<String>> uploadImages(List<XFile> images) async {
    if (images.isEmpty) return [];

    try {
      final uri = Uri.parse('$apiUrl/api/uploads-images');
      final request = http.MultipartRequest('POST', uri);

      // Upload tất cả ảnh song song
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: path.basename(image.path),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final jsonResponse = json.decode(response.body);
        throw ProductServiceException(
          message: jsonResponse['error'] ?? 'Failed to upload images',
          statusCode: response.statusCode,
          operation: 'uploadImages',
        );
      }

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] != true) {
        throw ProductServiceException(
          message: jsonResponse['error'] ?? 'Upload failed',
          operation: 'uploadImages',
        );
      }

      final List<dynamic> urls = jsonResponse['imageUrls'];
      return urls.map((url) => url.toString()).toList();
    } on TimeoutException {
      throw ProductServiceException(
        message: 'Upload timeout',
        operation: 'uploadImages',
      );
    } on SocketException {
      throw ProductServiceException(
        message: 'No internet connection',
        operation: 'uploadImages',
      );
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException(
        message: e.toString(),
        operation: 'uploadImages',
      );
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      if (productId.isEmpty) {
        throw ProductServiceException(
          message: 'Product ID is required',
          operation: 'deleteProduct',
        );
      }

      final response = await _httpClient
          .delete(Uri.parse('$apiUrl/api/products/$productId'))
          .timeout(_requestTimeout);

      _handleErrorResponse(response, 'deleteProduct');
    } on TimeoutException {
      throw ProductServiceException(
        message: 'Request timeout',
        operation: 'deleteProduct',
      );
    } on SocketException {
      throw ProductServiceException(
        message: 'No internet connection',
        operation: 'deleteProduct',
      );
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException(
        message: e.toString(),
        operation: 'deleteProduct',
      );
    }
  }

  /// Validate input chung
  void _validateProductInput(
    String productName,
    String shoeType,
    String price,
    List<String> color,
    List<String> size,
  ) {
    if (productName.trim().isEmpty) {
      throw ProductServiceException(
        message: 'Product name is required',
        operation: 'validation',
      );
    }
    if (shoeType.trim().isEmpty) {
      throw ProductServiceException(
        message: 'Shoe type is required',
        operation: 'validation',
      );
    }
    if (price.trim().isEmpty) {
      throw ProductServiceException(
        message: 'Price is required',
        operation: 'validation',
      );
    }
    if (color.isEmpty) {
      throw ProductServiceException(
        message: 'At least one color is required',
        operation: 'validation',
      );
    }
    if (size.isEmpty) {
      throw ProductServiceException(
        message: 'At least one size is required',
        operation: 'validation',
      );
    }
  }

  /// Cleanup resources
  void dispose() {
    _httpClient.close();
  }
}

/// Custom exception class
class ProductServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String operation;

  ProductServiceException({
    required this.message,
    this.statusCode,
    required this.operation,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ProductServiceException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    buffer.write(' - Operation: $operation');
    return buffer.toString();
  }
}
