import 'package:app_neaker/models/comment_model.dart';
import 'package:app_neaker/service/comment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ViewCommentsScreen extends StatefulWidget {
  final String productId;

  ViewCommentsScreen({required this.productId});

  @override
  _ViewCommentsScreenState createState() => _ViewCommentsScreenState();
}

class _ViewCommentsScreenState extends State<ViewCommentsScreen> {
  final CommentService _commentService = CommentService();
  List<CommentModel> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _commentService.getComments(widget.productId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Reviews'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white24, Colors.lightBlueAccent.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _comments.isEmpty
                ? Center(child: Text('No reviews yet.'))
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(_comments[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(comment.username,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_formatDate(comment.createdAt),
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            SizedBox(height: 4),
            RatingBarIndicator(
              rating: comment.rating,
              itemBuilder: (context, index) =>
                  Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 16.0,
              direction: Axis.horizontal,
            ),
            SizedBox(height: 8),
            Text(comment.comment),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
