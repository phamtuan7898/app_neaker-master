class UserModel {
  final String id;
  final String username;
  final String email;
  final String img; // Now non-nullable with a default value
  final String phone; // Now non-nullable with a default value
  final String address; // Now non-nullable with a default value

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.img = '', // Default to empty string
    this.phone = '', // Default to empty string
    this.address = '', // Default to empty string
  });

  // Factory constructor to create from Map
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['_id'],
      username: data['username'],
      email: data['email'],
      img: data['img'] ?? '', // Default to empty string if null
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'], // Adjust according to your MongoDB schema
      username: json['username'],
      email: json['email'],
      img: json['img'] ?? '', // Handle null safely
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }

  // Convert to Map for registration or update
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'img': img, // Add img to Map
      'phone': phone, // Add phone to Map
      'address': address, // Add address to Map
    };
  }

  // JSON conversion
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'img': img,
      'phone': phone,
      'address': address,
    };
  }

  // Method to create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? img,
    String? phone,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      img: img ?? this.img,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
