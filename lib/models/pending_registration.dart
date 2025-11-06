import 'user.dart';

class PendingRegistration {
  final String id;
  final String email;
  final String name;
  final UserType userType;
  final String password;
  final DateTime registrationDate;
  final bool approved;
  
  // Trainer specific fields
  final String? specialty;
  final String? cref;
  final String? experience;
  final String? bio;
  final String? hourlyRate;
  final String? city;
  
  // Student specific fields
  final String? goals;
  final String? fitnessLevel;

  const PendingRegistration({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    required this.password,
    required this.registrationDate,
    this.approved = false,
    this.specialty,
    this.cref,
    this.experience,
    this.bio,
    this.hourlyRate,
    this.city,
    this.goals,
    this.fitnessLevel,
  });

  factory PendingRegistration.fromJson(Map<String, dynamic> json) {
    return PendingRegistration(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: UserType.fromString(json['userType'] as String),
      password: json['password'] as String,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      approved: json['approved'] as bool? ?? false,
      specialty: json['specialty'] as String?,
      cref: json['cref'] as String?,
      experience: json['experience'] as String?,
      bio: json['bio'] as String?,
      hourlyRate: json['hourlyRate'] as String?,
      city: json['city'] as String?,
      goals: json['goals'] as String?,
      fitnessLevel: json['fitnessLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userType': userType.value,
      'password': password,
      'registrationDate': registrationDate.toIso8601String(),
      'approved': approved,
      'specialty': specialty,
      'cref': cref,
      'experience': experience,
      'bio': bio,
      'hourlyRate': hourlyRate,
      'city': city,
      'goals': goals,
      'fitnessLevel': fitnessLevel,
    };
  }

  PendingRegistration copyWith({
    String? id,
    String? email,
    String? name,
    UserType? userType,
    String? password,
    DateTime? registrationDate,
    bool? approved,
    String? specialty,
    String? cref,
    String? experience,
    String? bio,
    String? hourlyRate,
    String? city,
    String? goals,
    String? fitnessLevel,
  }) {
    return PendingRegistration(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      password: password ?? this.password,
      registrationDate: registrationDate ?? this.registrationDate,
      approved: approved ?? this.approved,
      specialty: specialty ?? this.specialty,
      cref: cref ?? this.cref,
      experience: experience ?? this.experience,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      city: city ?? this.city,
      goals: goals ?? this.goals,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
    );
  }

  User toUser() {
    return User(
      id: id,
      email: email,
      name: name,
      userType: userType,
      approved: true,
      specialty: specialty,
      cref: cref,
      experience: experience,
      bio: bio,
      hourlyRate: hourlyRate,
      city: city,
      goals: goals,
      fitnessLevel: fitnessLevel,
    );
  }
}
