class OrderItem {
  final String productName;
  final String price;
  final int quantity;
  final String size;
  final String color;
  final String productId; // Thêm trường này nếu chưa có

  OrderItem({
    required this.productName,
    required this.price,
    required this.quantity,
    required this.size,
    required this.color,
    required this.productId, // Thêm vào constructor
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      productName: json['productName'],
      price: json['price'],
      quantity: json['quantity'],
      size: json['size'] ??
          json['Size'] ??
          '', // Kiểm tra cả camelCase và lowercase
      color: json['color'] ??
          json['Color'] ??
          '', // Kiểm tra cả camelCase và lowercase
    );
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status;
  final String phone;
  final String address;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.phone,
    required this.address,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      userId: json['userId'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      orderDate: DateTime.parse(json['orderDate']),
      status: json['status'],
      phone: json['phone'],
      address: json['address'],
    );
  }
}
