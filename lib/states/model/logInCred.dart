class LogInCred {
  final String token;
  final int expiresIn;
  final String createdAt;
  final String username;
  final String personId; // Added this missing field
  final String firstName;
  final String lastName;
  final String email;
  final String employeeId;
  final List<String> roles;
  final List<String> rolesName;
  final String siteId;
  final String userId;
  final String siteName;
  final bool isMsLogin;

  LogInCred({
    required this.token,
    required this.expiresIn,
    required this.createdAt,
    required this.username,
    required this.personId, // Added
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.employeeId,
    required this.roles,
    required this.rolesName,
    required this.siteId,
    required this.userId,
    required this.siteName,
    required this.isMsLogin,
  });

  factory LogInCred.fromJson(Map<String, dynamic> json) {
    return LogInCred(
      token: json['token'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      username: json['username'] ?? '',
      personId: json['personId'] ?? '', // Added
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      employeeId: json['employeeId'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      rolesName: List<String>.from(json['rolesName'] ?? []),
      siteId: json['siteId'] ?? '',
      userId: json['userId'] ?? '',
      siteName: json['siteName'] ?? '',
      isMsLogin: json['isMsLogin'] ?? false,
    );
  }
}