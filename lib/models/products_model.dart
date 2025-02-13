class ProductModel {
  String id;
  String productName;
  String shoeType;
  List<String> image;
  String price;
  double rating;
  String description;
  List<String> color;
  List<String> size;

  ProductModel({
    required this.id,
    required this.productName,
    required this.shoeType,
    required this.image,
    required this.price,
    required this.rating,
    required this.description,
    required this.color,
    required this.size,
  });

  // Factory method to create Shoe object from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? '',
      productName: json['productName'] as String,
      shoeType: json['shoeType'] as String,
      image: List<String>.from(json['image']),
      price: json['price'] as String,
      // Xử lý trường rating để chấp nhận cả int và double
      rating: (json['rating'] is int)
          ? (json['rating'] as int).toDouble()
          : json['rating'] as double,
      description: json['description'] as String,
      color: List<String>.from(json['color']),
      size: List<String>.from(json['size']),
    );
  }

  // Method to convert Shoe object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productName': productName,
      'shoeType': shoeType,
      'image': image,
      'price': price,
      'rating': rating,
      'description': description,
      'color': color,
      'size': size,
    };
  }
}
