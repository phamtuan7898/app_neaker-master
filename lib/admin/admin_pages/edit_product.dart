import 'dart:io';
import 'package:app_neaker/models/products_model.dart';
import 'package:app_neaker/service/product_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  final ProductModel product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  late TextEditingController _priceController;
  late TextEditingController _ratingController;

  List<String> _colors = [];
  List<String> _sizes = [];
  List<String> _existingImages = [];
  List<XFile> _newImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.product.price);
    _ratingController =
        TextEditingController(text: widget.product.rating.toString());
    _colors = List<String>.from(widget.product.color);
    _sizes = List<String>.from(widget.product.size);
    _existingImages = List<String>.from(widget.product.image);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> selectedImages = await _productService.pickImages();
      if (selectedImages.isNotEmpty) {
        setState(() {
          _newImages = selectedImages;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No images selected.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _productService.updateProduct(
        widget.product.id,
        widget.product.productName, // Keep original name
        widget.product.shoeType, // Keep original type
        _newImages,
        _existingImages,
        _priceController.text.trim(),
        double.parse(_ratingController.text.trim()),
        widget.product.description, // Keep original description
        _colors,
        _sizes,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview(List<String> imageUrls, bool isNetwork) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                isNetwork
                    ? Image.network(
                        imageUrl,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 100);
                        },
                      )
                    : Image.file(
                        File(imageUrl),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 100);
                        },
                      ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (isNetwork) {
                          _existingImages.removeAt(index);
                        } else {
                          _newImages.removeAt(index);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addAttribute(String value, List<String> list) {
    if (value.isNotEmpty && !list.contains(value)) {
      setState(() {
        list.add(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Display non-editable product information
                    ListTile(
                      title:
                          Text('Product Name: ${widget.product.productName}'),
                      subtitle: Text('Type: ${widget.product.shoeType}'),
                    ),
                    const Divider(),

                    // Editable fields
                    _buildTextField(_priceController, 'Price', isNumber: true),
                    _buildTextField(_ratingController, 'Rating',
                        isNumber: true, range: 5),
                    const SizedBox(height: 16),

                    // Images
                    const Text('Current Images:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildImagePreview(_existingImages, true),
                    if (_newImages.isNotEmpty)
                      const Text('New Images:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildImagePreview(
                        _newImages.map((image) => image.path).toList(), false),
                    TextButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Images'),
                    ),
                    const SizedBox(height: 16),

                    // Colors
                    const Text('Colors:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      children: _colors
                          .map((color) => Chip(
                                label: Text(color),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () =>
                                    setState(() => _colors.remove(color)),
                              ))
                          .toList(),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Add Color'),
                      onSubmitted: (value) => _addAttribute(value, _colors),
                    ),
                    const SizedBox(height: 16),

                    // Sizes
                    const Text('Sizes:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      children: _sizes
                          .map((size) => Chip(
                                label: Text(size),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () =>
                                    setState(() => _sizes.remove(size)),
                              ))
                          .toList(),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Add Size'),
                      onSubmitted: (value) => _addAttribute(value, _sizes),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProduct,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Update Product'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false, double range = 0}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.text : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isNumber) {
          if (label == 'Price') {
            final processedValue = value
                .replaceAll(',', '')
                .replaceAll('VND', '')
                .replaceAll(' ', '')
                .trim();

            final numValue = double.tryParse(processedValue);

            if (numValue == null) {
              return 'Please enter a valid price';
            }
            if (numValue < 0) {
              return 'Price cannot be negative';
            }
            return null;
          } else {
            final processedValue = value.replaceAll(',', '');
            final numValue = double.tryParse(processedValue);

            if (numValue == null) return 'Please enter a valid number';
            if (range > 0 && (numValue < 0 || numValue > range)) {
              return '$label must be between 0 and $range';
            }
          }
        }
        return null;
      },
      onChanged: (value) {
        if (isNumber && label == 'Price') {
          try {
            if (value.isNotEmpty) {
              String numericValue = value
                  .replaceAll(',', '')
                  .replaceAll('VND', '')
                  .replaceAll(' ', '')
                  .trim();

              double? number = double.tryParse(numericValue);
              if (number != null) {
                String formattedValue = number
                    .toStringAsFixed(0)
                    .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},');

                formattedValue = '$formattedValue VND';

                if (controller.text != formattedValue) {
                  controller.value = TextEditingValue(
                    text: formattedValue,
                    selection:
                        TextSelection.collapsed(offset: formattedValue.length),
                  );
                }
              }
            }
          } catch (e) {
            print('Error formatting price: $e');
          }
        }
      },
    );
  }

  Widget _buildAttributeInput(String label, List<String> list) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(labelText: label),
            onFieldSubmitted: (value) => _addAttribute(value, list),
          ),
        ),
      ],
    );
  }
}
