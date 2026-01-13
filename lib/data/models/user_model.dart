class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? role; // e.g., 'landlord', 'tenant', 'agent'

  final String? avatarUrl;
  final String? bio;
  final String? employmentStatus;
  final String? gender;
  final String? maritalStatus;
  final String? state;
  final String? city;
  final String? businessName;
  final double? totalRevenue;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.role,
    this.avatarUrl,
    this.bio,
    this.employmentStatus,
    this.gender,
    this.maritalStatus,
    this.state,
    this.city,
    this.businessName,
    this.totalRevenue,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      employmentStatus: json['employment_status'] as String?,
      gender: json['gender'] as String?,
      maritalStatus: json['marital_status'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      businessName: json['business_name'] as String?,
      totalRevenue: json['total_revenue'] != null
          ? (json['total_revenue'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
      'bio': bio,
      'employment_status': employmentStatus,
      'gender': gender,
      'marital_status': maritalStatus,
      'state': state,
      'city': city,
      'business_name': businessName,
      'total_revenue': totalRevenue,
    };
  }
}
