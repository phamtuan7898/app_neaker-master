class CartItem {
  String id;
  String userId;
  String productId;
  String productName;
  String price;
  int quantity;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? json['id'] ?? '', // Thêm fallback cho id
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: json['price'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  double getTotalPrice() {
    final priceWithoutFormatting = price.replaceAll(RegExp(r'[^\d]'), '');
    return double.parse(priceWithoutFormatting) / 1;
  }
}
