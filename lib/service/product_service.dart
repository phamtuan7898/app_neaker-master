import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:app_neaker/constants/config.dart';
import 'package:app_neaker/models/products_model.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProductService {
  final http.Client _client;
  final ImagePicker _picker;

  // Sử dụng từ AppConfig
  String get _baseUrl => AppConfig.baseUrl;
  Duration get _requestTimeout => Duration(seconds: AppConfig.apiTimeout);
  Duration get _uploadTimeout => Duration(seconds: AppConfig.uploadTimeout);

  ProductService({
    http.Client? httpClient,
    ImagePicker? picker,
  })  : _client = httpClient ?? http.Client(),
        _picker = picker ?? ImagePicker() {}

  // JSON headers chung
  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Format giá trước khi gửi API
  String _formatPrice(String price) =>
      price.replaceAll(RegExp(r'[,\s]|VND'), '').trim();

  // -------------------------
  //  Generic Error Handler
  // -------------------------
  Never _throwError(
    http.Response res,
    String operation,
  ) {
    try {
      final data = json.decode(res.body);
      throw ProductServiceException(
        message: data['error'] ?? 'Unknown error',
        statusCode: res.statusCode,
        operation: operation,
      );
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException(
        message: res.body,
        statusCode: res.statusCode,
        operation: operation,
      );
    }
  }

  // -------------------------
  //  Generic Request Handler
  // -------------------------
  Future<T> _handle<T>({
    required Future<http.Response> Function() request,
    required T Function(String body) parser,
    required String operation,
  }) async {
    try {
      final res = await request().timeout(_requestTimeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return parser(res.body);
      }

      _throwError(res, operation);
    } on TimeoutException {
      throw ProductServiceException(
        message: 'Request timeout',
        operation: operation,
      );
    } on SocketException {
      throw ProductServiceException(
        message: 'No internet connection',
        operation: operation,
      );
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException(
        message: e.toString(),
        operation: operation,
      );
    }
  }

  // ==================================================
  //                    CRUD API
  // ==================================================

  Future<List<ProductModel>> fetchProducts() async {
    return _handle<List<ProductModel>>(
      request: () => _client.get(Uri.parse('$_baseUrl/api/products')),
      operation: 'fetchProducts',
      parser: (body) {
        final List list = json.decode(body);
        return list.map((e) => ProductModel.fromJson(e)).toList();
      },
    );
  }

  Future<void> addProduct(
    String name,
    String type,
    List<XFile> images,
    String price,
    double rating,
    String description,
    List<String> colors,
    List<String> sizes,
  ) async {
    _validateProductInput(name, type, price, colors, sizes);

    if (images.isEmpty) {
      throw ProductServiceException(
        message: 'At least one image is required',
        operation: 'addProduct',
      );
    }

    final imageUrls = await uploadImages(images);

    final body = {
      'productName': name,
      'shoeType': type,
      'image': imageUrls,
      'price': _formatPrice(price),
      'rating': rating,
      'description': description,
      'color': colors,
      'size': sizes,
    };

    await _handle(
      request: () => _client.post(
        Uri.parse('$_baseUrl/api/products'),
        headers: _jsonHeaders,
        body: json.encode(body),
      ),
      operation: 'addProduct',
      parser: (_) => null,
    );
  }

  Future<void> updateProduct(
    String id,
    String name,
    String type,
    List<XFile> newImages,
    List<String> existingImages,
    String price,
    double rating,
    String description,
    List<String> colors,
    List<String> sizes,
  ) async {
    _validateProductInput(name, type, price, colors, sizes);

    final newUrls =
        newImages.isNotEmpty ? await uploadImages(newImages) : <String>[];

    final allImages = [...existingImages, ...newUrls];

    final body = {
      'productName': name,
      'shoeType': type,
      'image': allImages,
      'price': _formatPrice(price),
      'rating': rating,
      'description': description,
      'color': colors,
      'size': sizes,
    };

    await _handle(
      request: () => _client.put(
        Uri.parse('$_baseUrl/api/products/$id'),
        headers: _jsonHeaders,
        body: json.encode(body),
      ),
      operation: 'updateProduct',
      parser: (_) => null,
    );
  }

  Future<void> deleteProduct(String id) async {
    if (id.isEmpty) {
      throw ProductServiceException(
        message: 'Product ID is required',
        operation: 'deleteProduct',
      );
    }

    await _handle(
      request: () => _client.delete(
        Uri.parse('$_baseUrl/api/products/$id'),
      ),
      operation: 'deleteProduct',
      parser: (_) => null,
    );
  }

  // ==================================================
  //                 Upload Images
  // ==================================================

  Future<List<String>> uploadImages(List<XFile> images) async {
    if (images.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/api/uploads-images');
      final req = http.MultipartRequest('POST', uri);

      for (final img in images) {
        final bytes = await img.readAsBytes();
        req.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: path.basename(img.path),
          ),
        );
      }

      final streamRes = await req.send().timeout(_uploadTimeout);
      final res = await http.Response.fromStream(streamRes);

      if (res.statusCode != 200) _throwError(res, 'uploadImages');

      final data = json.decode(res.body);

      if (data['success'] != true) {
        throw ProductServiceException(
          message: data['error'] ?? 'Upload failed',
          operation: 'uploadImages',
        );
      }

      return List<String>.from(data['imageUrls']);
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
    }
  }

  // ==================================================
  //                Image Picker
  // ==================================================

  Future<List<XFile>> pickImages({int? max}) async {
    try {
      return await _picker.pickMultiImage(imageQuality: 70, limit: max);
    } catch (e) {
      throw ProductServiceException(
        message: 'Failed to pick images: $e',
        operation: 'pickImages',
      );
    }
  }

  // ==================================================
  //                Validation
  // ==================================================

  void _validateProductInput(
    String name,
    String type,
    String price,
    List<String> colors,
    List<String> sizes,
  ) {
    if (name.isEmpty) {
      throw ProductServiceException(
        message: 'Product name is required',
        operation: 'validation',
      );
    }
    if (type.isEmpty) {
      throw ProductServiceException(
        message: 'Shoe type is required',
        operation: 'validation',
      );
    }
    if (price.isEmpty) {
      throw ProductServiceException(
        message: 'Price is required',
        operation: 'validation',
      );
    }
    if (colors.isEmpty) {
      throw ProductServiceException(
        message: 'At least one color is required',
        operation: 'validation',
      );
    }
    if (sizes.isEmpty) {
      throw ProductServiceException(
        message: 'At least one size is required',
        operation: 'validation',
      );
    }
  }

  // ==================================================
  //                Clean Up
  // ==================================================

  void dispose() => _client.close();
}

// ==================================================
//                Exception Class
// ==================================================
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
  String toString() =>
      'ProductServiceException($operation): $message (status: $statusCode)';
}
