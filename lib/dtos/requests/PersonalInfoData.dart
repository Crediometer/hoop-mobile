class PersonalInfoData {
  final String dateOfBirth; // ISO date string
  final String gender;
  final String bio;
  final String occupation;
  final double latitude;
  final String requestId;
  final double longitude;
  final String bvn;

  PersonalInfoData({
    required this.dateOfBirth,
    required this.gender,
    required this.bio,
    required this.occupation,
    required this.latitude,
    required this.requestId,
    required this.longitude,
    required this.bvn,
  });

  Map<String, dynamic> toJson() => {
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'bio': bio,
        'occupation': occupation,
        'latitude': latitude,
        'requestId': requestId,
        'longitude': longitude,
        'bvn': bvn,
      };
}

