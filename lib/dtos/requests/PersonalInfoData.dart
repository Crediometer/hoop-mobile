class PersonalInfoData {
  final String dateOfBirth; // ISO date string
  final String gender;
  final String bio;
  final String occupation;
  final double latitude;

  final double longitude;

  PersonalInfoData({
    required this.dateOfBirth,
    required this.gender,
    required this.bio,
    required this.occupation,
    required this.latitude,
    required this.longitude,

  });

  Map<String, dynamic> toJson() => {
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'bio': bio,
        'occupation': occupation,
        'latitude': latitude,

        'longitude': longitude,
      };
}


  // Location Data Model
  class LocationData {
    final double latitude;
    final double longitude;
    final String? address;
    final String accuracy; // 'high', 'medium', 'low'
    final String source; // 'gps', 'ip', 'default'

    LocationData({
      required this.latitude,
      required this.longitude,
      this.address,
      required this.accuracy,
      required this.source,
    });
  }