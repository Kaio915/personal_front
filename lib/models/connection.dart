enum ConnectionStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  const ConnectionStatus(this.value);
  final String value;

  static ConnectionStatus fromString(String value) {
    return ConnectionStatus.values.firstWhere((e) => e.value == value);
  }
}

class Connection {
  final String id;
  final String trainerId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final ConnectionStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final int? rating;

  const Connection({
    required this.id,
    required this.trainerId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.rating,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      trainerId: json['trainerId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      studentEmail: json['studentEmail'] as String,
      status: ConnectionStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt'] as String) 
          : null,
      rating: json['rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainerId': trainerId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'rating': rating,
    };
  }

  Connection copyWith({
    String? id,
    String? trainerId,
    String? studentId,
    String? studentName,
    String? studentEmail,
    ConnectionStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    int? rating,
  }) {
    return Connection(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      rating: rating ?? this.rating,
    );
  }

  bool get isPending => status == ConnectionStatus.pending;
  bool get isAccepted => status == ConnectionStatus.accepted;
  bool get isRejected => status == ConnectionStatus.rejected;
}
