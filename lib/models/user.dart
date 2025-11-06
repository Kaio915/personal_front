enum UserType {
  trainer('trainer'),
  student('student'),
  admin('admin');

  const UserType(this.value);
  final String value;

  static UserType fromString(String value) {
    return UserType.values.firstWhere((e) => e.value == value);
  }

  String get displayName {
    switch (this) {
      case UserType.trainer:
        return 'Personal Trainer';
      case UserType.student:
        return 'Aluno';
      case UserType.admin:
        return 'Administrador';
    }
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final UserType userType;
  final bool? approved;
  
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

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.approved,
    this.specialty,
    this.cref,
    this.experience,
    this.bio,
    this.hourlyRate,
    this.city,
    this.goals,
    this.fitnessLevel,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: UserType.fromString(json['userType'] as String),
      approved: json['approved'] as bool?,
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

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserType? userType,
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
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
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

  bool get isTrainer => userType == UserType.trainer;
  bool get isStudent => userType == UserType.student;
  bool get isAdmin => userType == UserType.admin;
}
