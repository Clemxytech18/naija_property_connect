class PropertyModel {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? type; // e.g. 'apartment', 'house'
  final String? location;
  final double? price;
  final List<String> images;
  final String? video;
  final List<String> features;
  final int? bedrooms;
  final int? bathrooms;
  final double? sqft;
  final int? parkingSpaces;
  final double? serviceFee;
  final double? agentFee;
  final double? legalFee;
  final double? agreementFee;
  final double? cautionFee;
  final double? latitude;
  final double? longitude;
  final String status;
  final String? closedReason;
  final DateTime createdAt;

  PropertyModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.type,
    this.location,
    this.price,
    this.images = const [],
    this.video,
    this.features = const [],
    this.bedrooms,
    this.bathrooms,
    this.sqft,
    this.parkingSpaces,
    this.agentFee,
    this.legalFee,
    this.agreementFee,
    this.cautionFee,
    this.serviceFee,
    this.latitude,
    this.longitude,
    this.status = 'available',
    this.closedReason,
    required this.createdAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String?,
      location: json['location'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : (json['media'] != null
                ? List<String>.from(json['media'])
                : []), // Fallback to 'media' for backward compat
      video: json['video'] as String?,
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : const [],
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      sqft: json['sqft'] != null ? (json['sqft'] as num).toDouble() : null,
      parkingSpaces: json['parking_spaces'] as int?,
      agentFee: json['agent_fee'] != null
          ? (json['agent_fee'] as num).toDouble()
          : null,
      legalFee: json['legal_fee'] != null
          ? (json['legal_fee'] as num).toDouble()
          : null,
      agreementFee: json['agreement_fee'] != null
          ? (json['agreement_fee'] as num).toDouble()
          : null,
      cautionFee: json['caution_fee'] != null
          ? (json['caution_fee'] as num).toDouble()
          : null,
      serviceFee: json['service_fee'] != null
          ? (json['service_fee'] as num).toDouble()
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      status: json['status'] as String? ?? 'available',
      closedReason: json['closed_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'type': type,
      'location': location,
      'price': price,
      'images': images,
      'video': video,
      'features': features,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'sqft': sqft,
      'parking_spaces': parkingSpaces,
      'agent_fee': agentFee,
      'legal_fee': legalFee,
      'agreement_fee': agreementFee,
      'caution_fee': cautionFee,
      'service_fee': serviceFee,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'closed_reason': closedReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get totalPackage {
    return (price ?? 0) +
        (agentFee ?? 0) +
        (legalFee ?? 0) +
        (agreementFee ?? 0) +
        (cautionFee ?? 0) +
        (serviceFee ?? 0);
  }
}
