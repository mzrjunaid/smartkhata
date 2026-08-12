class TopLenderModel {
  const TopLenderModel({
    required this.profileId,
    required this.fullName,
  });

  final String profileId;
  final String fullName;

  factory TopLenderModel.fromJson(Map<String, dynamic> json) {
    return TopLenderModel(
      profileId: json['profile_id'] as String,
      fullName: json['full_name'] as String,
    );
  }
}
