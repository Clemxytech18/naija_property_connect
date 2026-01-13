class WishlistModel {
  final String id;
  final String userId;
  final String propertyId;
  final DateTime createdAt;

  // Optional: Embed property details if fetched with join
  final Map<String, dynamic>? property;

  WishlistModel({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.createdAt,
    this.property,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      propertyId: json['property_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      property: json['properties'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'property_id': propertyId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
