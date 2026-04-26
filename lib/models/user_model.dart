import 'package:cloud_firestore/cloud_firestore.dart';

enum FitnessGoal { bulking, cutting, maintain }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final double weightKg;
  final double heightCm;
  final FitnessGoal goal;
  final DateTime createdAt;
  final String? photoUrl;
  final String? photoBase64;
  final bool reminderEnabled;
  final int reminderIntervalSeconds;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.createdAt,
    this.photoUrl,
    this.photoBase64,
    this.reminderEnabled = false,
    this.reminderIntervalSeconds = 86399,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String get goalLabel {
    switch (goal) {
      case FitnessGoal.bulking:
        return '💪 Bulking';
      case FitnessGoal.cutting:
        return '🔥 Cutting';
      case FitnessGoal.maintain:
        return '⚖️ Maintain';
    }
  }

  Duration get reminderInterval =>
      Duration(seconds: reminderIntervalSeconds);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Data user kosong');

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      weightKg: (data['weightKg'] ?? 0).toDouble(),
      heightCm: (data['heightCm'] ?? 0).toDouble(),
      goal: FitnessGoal.values.firstWhere(
        (e) => e.name == (data['goal'] ?? 'maintain'),
        orElse: () => FitnessGoal.maintain,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'],
      photoBase64: data['photoBase64'],
      reminderEnabled: data['reminderEnabled'] ?? false,
      reminderIntervalSeconds:
          (data['reminderIntervalSeconds'] ?? 86399).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'goal': goal.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
      'reminderEnabled': reminderEnabled,
      'reminderIntervalSeconds': reminderIntervalSeconds,
    };
  }

  UserModel copyWith({
    String? name,
    double? weightKg,
    double? heightCm,
    FitnessGoal? goal,
    String? photoUrl,
    String? photoBase64,
    bool? reminderEnabled,
    int? reminderIntervalSeconds,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      goal: goal ?? this.goal,
      createdAt: createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderIntervalSeconds:
          reminderIntervalSeconds ?? this.reminderIntervalSeconds,
    );
  }
}
