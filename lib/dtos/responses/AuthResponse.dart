import 'package:hoop/dtos/responses/User.dart';

class AuthResponse {
  final String token;
  final String firstName;
  final String lastName;
  final String email;
  final String? refreshToken;  // Make nullable
  final int? expiresIn;  // Make nullable
  final int operationStatus;
  final int userId;

  AuthResponse({
    required this.token,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.refreshToken,
    this.expiresIn,
    required this.operationStatus,
    required this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    print("Parsing AuthResponse JSON: $json");
    
    // Try to extract firstName with case-insensitive approach
    String firstName = '';
    if (json.containsKey('firstName')) {
      firstName = json['firstName']?.toString() ?? '';
    } else if (json.containsKey('firstname')) {
      firstName = json['firstname']?.toString() ?? '';
    } else if (json.containsKey('first_name')) {
      firstName = json['first_name']?.toString() ?? '';
    }
    
    // Try to extract lastName with case-insensitive approach
    String lastName = '';
    if (json.containsKey('lastName')) {
      lastName = json['lastName']?.toString() ?? '';
    } else if (json.containsKey('lastname')) {
      lastName = json['lastname']?.toString() ?? '';
    } else if (json.containsKey('last_name')) {
      lastName = json['last_name']?.toString() ?? '';
    }

    // Extract token - check multiple possible field names
    String token = '';
    if (json.containsKey('token')) {
      token = json['token']?.toString() ?? '';
    } else if (json.containsKey('accessToken')) {
      token = json['accessToken']?.toString() ?? '';
    } else if (json.containsKey('access_token')) {
      token = json['access_token']?.toString() ?? '';
    }

    // Try to create User object from root fields if not provided
  

    return AuthResponse(
      token: token,
      firstName: firstName,
      lastName: lastName,
      email: json['email']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(),
      expiresIn: json['expiresIn'] != null ? int.tryParse(json['expiresIn'].toString()) : null,
      operationStatus: json['operationStatus'] != null ? int.tryParse(json['operationStatus'].toString()) ?? 0 : 0,
      userId: json['userId'] != null ? int.tryParse(json['userId'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (expiresIn != null) 'expiresIn': expiresIn,
      'operationStatus': operationStatus,
      'userId': userId,
    };
  }

  @override
  String toString() {
    return 'AuthResponse( token: $token, firstName: $firstName, lastName: $lastName, email: $email, operationStatus: $operationStatus, userId: $userId)';
  }
}