class CommentModel {
  final String id;
  final String productId;
  final String userId;
  final String username;
  final String comment;
  final double rating;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.username,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'],
      productId: json['productId'],
      userId: json['userId'],
      username: json['username'],
      comment: json['comment'],
      rating: json['rating'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'userId': userId,
      'username': username,
      'comment': comment,
      'rating': rating,
    };
  }
}
