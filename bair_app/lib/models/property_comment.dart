class PropertyComment {
  final int id;
  final String username;
  final int? userId;
  final String text;
  final String createdAt;
  final int likeCount;
  final bool isLiked;
  const PropertyComment({
    required this.id,
    required this.username,
    required this.text,
    required this.createdAt,
    this.userId,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory PropertyComment.fromJson(Map<String, dynamic> d) => PropertyComment(
    id: d['id'] as int,
    username: d['username'] as String? ?? '',
    userId: (d['user_id'] as num?)?.toInt(),
    text: d['text'] as String? ?? '',
    createdAt: d['created_at'] as String? ?? '',
    likeCount: (d['like_count'] as num?)?.toInt() ?? 0,
    isLiked: d['is_liked'] == true,
  );

  PropertyComment copyWith({int? likeCount, bool? isLiked}) => PropertyComment(
    id: id,
    username: username,
    userId: userId,
    text: text,
    createdAt: createdAt,
    likeCount: likeCount ?? this.likeCount,
    isLiked: isLiked ?? this.isLiked,
  );
}