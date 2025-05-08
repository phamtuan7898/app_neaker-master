class CartItem {
  String id;
  String userId;
  String productId;
  String productName;
  String price;
  int quantity;
  String size;
  String color;
  String image; // Trường image để lưu URL hình ảnh

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
    this.size = '',
    this.color = '',
    this.image = '', // Khởi tạo giá trị mặc định là chuỗi rỗng
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'size': size,
      'color': color,
      'image': image, // Thêm image vào JSON
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: json['price']?.toString() ?? '',
      quantity: json['quantity'] ?? 1,
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      image: json['image'] is List && json['image'].isNotEmpty
          ? json['image'][0] // Lấy URL đầu tiên nếu image là mảng
          : json['image']?.toString() ??
              '', // Xử lý trường hợp image là chuỗi hoặc null
    );
  }

  double getTotalPrice() {
    final priceWithoutFormatting = price.replaceAll(RegExp(r'[^\d]'), '');
    return double.parse(priceWithoutFormatting) / 1;
  }
}
