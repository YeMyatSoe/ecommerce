class Reply {
  final String user;  // Assuming user is a string (e.g., user name or ID)
  final String replyText;
  final DateTime createdAt;

  Reply({
    required this.user,
    required this.replyText,
    required this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      user: json['user']?.toString() ?? '',  // Ensure this is a string
      replyText: json['reply_text'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
class Review {
  final int id;
  final String user;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final int productId;
  int likes;
  bool hasLiked; // Track if the current user has liked this review
  List<String> replies; // List to store replies
  bool isRepliesExpanded; // Track if replies are expanded

  Review({
    required this.id,
    required this.user,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.productId,
    this.likes = 0,
    this.hasLiked = true,
    List<String>? replies,
    this.isRepliesExpanded = false, // Initially, replies are not expanded
  }) : replies = replies ?? []; // Initialize replies as an empty list if null

  // Method to add a reply
  void addReply(String reply) {
    replies.add(reply); // Add reply to the list
  }

  // Method to like a review
  void like() {
    likes++;
  }

  // Adjust your `fromJson` method to handle potential type mismatches
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      user: json['user']?.toString() ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      productId: json['product_id'] ?? 0,
      likes: json['like_count'],
      hasLiked: json['has_liked'] ?? false,
      replies: List<String>.from(json['replies']?.map((x) => x['reply_text']) ?? []),
    );
  }
}
