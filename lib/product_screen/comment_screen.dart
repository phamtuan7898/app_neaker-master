import 'package:app_neaker/models/comment_model.dart';
import 'package:app_neaker/models/user_model.dart';
import 'package:app_neaker/service/comment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class CommentScreen extends StatefulWidget {
  final String productId;
  final UserModel? user;

  CommentScreen({required this.productId, required this.user});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 5.0;
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
      appBar: AppBar(title: Text('Comments')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.user != null
                  ? _buildAddCommentForm()
                  : _buildLoginPrompt(),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(
                          child:
                              Text('No comments yet. Be the first to review!'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            return _buildCommentItem(_comments[index]);
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Please log in to add your review.'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigate to login
              },
              child: Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCommentForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Your Review',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Rating:'),
            RatingBar.builder(
              initialRating: _userRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 30,
              itemBuilder: (context, _) =>
                  Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _userRating = rating;
                });
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write your review here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitComment,
                child: Text('Submit Review'),
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
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

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your review')),
      );
      return;
    }

    try {
      await _commentService.addComment(
        widget.productId,
        widget.user!.id,
        widget.user!.username,
        _commentController.text.trim(),
        _userRating,
      );

      _commentController.clear();
      setState(() {
        _userRating = 5.0;
      });
      await _loadComments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your review has been added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add review. Please try again.')),
      );
    }
  }
}
