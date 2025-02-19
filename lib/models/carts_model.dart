class CartItem {
  String id;
  String userId;
  String productId;
  String productName;
  String price;
  int quantity;
  String size; 
  String color; 

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
    this.size = '', // Default empty string
    this.color = '', // Default empty string
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'size': size, // Include size in JSON
      'color': color, // Include color in JSON
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: json['price'] ?? '',
      quantity: json['quantity'] ?? 1,
      size: json['size'] ?? '', // Parse size from JSON
      color: json['color'] ?? '', // Parse color from JSON
    );
  }

  double getTotalPrice() {
    final priceWithoutFormatting = price.replaceAll(RegExp(r'[^\d]'), '');
    return double.parse(priceWithoutFormatting) / 1;
  }
}
