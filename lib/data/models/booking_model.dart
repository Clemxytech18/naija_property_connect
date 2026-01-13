class BookingModel {
  final String id;
  final String propertyId;
  final String userId;
  final DateTime date;
  final String status;

  // Optional expanded data for UI
  final String? propertyTitle;
  final String? userName;
  final String? userAvatarUrl;

  BookingModel({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.date,
    required this.status,
    this.propertyTitle,
    this.userName,
    this.userAvatarUrl,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      propertyTitle: json['properties'] != null
          ? json['properties']['title'] as String?
          : null,
      userName: json['users'] != null
          ? json['users']['full_name'] as String?
          : null,
      userAvatarUrl: json['users'] != null
          ? json['users']['avatar_url'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}
