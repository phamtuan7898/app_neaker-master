import 'dart:convert';
import 'package:app_neaker/models/comment_model.dart';
import 'package:http/http.dart' as http;

class CommentService {
  final String apiUrl = 'http://192.168.1.14:5002';

  // Thêm bình luận mới
  Future<CommentModel> addComment(
    String productId,
    String userId,
    String username,
    String comment,
    double rating,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productId': productId,
          'userId': userId,
          'username': username,
          'comment': comment,
          'rating': rating,
        }),
      );

      if (response.statusCode == 201) {
        return CommentModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }

  // Lấy danh sách bình luận theo productId
  Future<List<CommentModel>> getComments(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/comments/$productId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse
            .map((comment) => CommentModel.fromJson(comment))
            .toList();
      } else {
        throw Exception('Failed to load comments: ${response.body}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      throw Exception('Failed to load comments');
    }
  }
}
