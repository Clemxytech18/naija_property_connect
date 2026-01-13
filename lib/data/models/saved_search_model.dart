class SavedSearchModel {
  final String id;
  final String userId;
  final String title;
  final Map<String, dynamic> criteria;
  final DateTime createdAt;

  SavedSearchModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.criteria,
    required this.createdAt,
  });

  factory SavedSearchModel.fromJson(Map<String, dynamic> json) {
    return SavedSearchModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      criteria: json['criteria_json'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'criteria_json': criteria,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
