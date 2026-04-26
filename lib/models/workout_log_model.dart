import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSet {
  final int setNumber;
  int reps;
  double weightKg;
  bool isCompleted;

  ExerciseSet({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.isCompleted = false,
  });

  factory ExerciseSet.fromMap(Map<String, dynamic> map) => ExerciseSet(
    setNumber: map['setNumber'] ?? 1,
    reps: map['reps'] ?? 0,
    weightKg: (map['weightKg'] ?? 0).toDouble(),
    isCompleted: map['isCompleted'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'setNumber': setNumber,
    'reps': reps,
    'weightKg': weightKg,
    'isCompleted': isCompleted,
  };

  double get volume => reps * weightKg;
}

class ExerciseLog {
  final String id;
  final String name;
  final String category;
  final List<ExerciseSet> sets;
  final String? notes;

  ExerciseLog({
    required this.id,
    required this.name,
    required this.category,
    required this.sets,
    this.notes,
  });

  factory ExerciseLog.fromMap(Map<String, dynamic> map) => ExerciseLog(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    category: map['category'] ?? '',
    sets:
        (map['sets'] as List<dynamic>?)
            ?.map((s) => ExerciseSet.fromMap(s as Map<String, dynamic>))
            .toList() ??
        [],
    notes: map['notes'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'sets': sets.map((s) => s.toMap()).toList(),
    'notes': notes,
  };

  bool get isTimedExercise => _normalizeExerciseName(name) == 'plank';

  int get completedSets => sets.where((s) => s.isCompleted).length;

  double get totalVolume =>
      sets.where((s) => s.isCompleted).fold(0, (sum, s) => sum + s.volume);
}

/// WorkoutLog — photos stored as base64 strings in Firestore (no Storage billing).
/// Each photo ~150–200KB base64, keep max 3 per log to stay under 1MB doc limit.
class WorkoutLog {
  final String id;
  final String userId;
  final String planName;
  final List<ExerciseLog> exercises;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;

  /// base64-encoded JPEG strings (not URLs)
  final List<String> photoBase64List;
  final String? notes;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.planName,
    required this.exercises,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.photoBase64List = const [],
    this.notes,
  });

  Duration get duration {
    if (durationSeconds > 0) {
      return Duration(seconds: durationSeconds);
    }

    if (endTime == null) {
      return Duration.zero;
    }

    return endTime!.difference(startTime);
  }

  String get durationFormatted {
    final d = duration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    if (s > 0) return '${s}s';
    return '0s';
  }

  double get totalVolume => exercises.fold(0, (sum, e) => sum + e.totalVolume);

  int get totalSetsCompleted =>
      exercises.fold(0, (sum, e) => sum + e.completedSets);

  bool get hasPhotos => photoBase64List.isNotEmpty;

  factory WorkoutLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      planName: data['planName'] ?? '',
      exercises:
          (data['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      durationSeconds: (data['durationSeconds'] ?? 0) as int,
      photoBase64List: List<String>.from(data['photoBase64List'] ?? []),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'planName': planName,
    'exercises': exercises.map((e) => e.toMap()).toList(),
    'startTime': Timestamp.fromDate(startTime),
    'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    'durationSeconds': durationSeconds,
    'photoBase64List': photoBase64List,
    'notes': notes,
  };

  WorkoutLog copyWith({
    String? planName,
    List<ExerciseLog>? exercises,
    DateTime? endTime,
    int? durationSeconds,
    List<String>? photoBase64List,
    String? notes,
  }) => WorkoutLog(
    id: id,
    userId: userId,
    planName: planName ?? this.planName,
    exercises: exercises ?? this.exercises,
    startTime: startTime,
    endTime: endTime ?? this.endTime,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    photoBase64List: photoBase64List ?? this.photoBase64List,
    notes: notes ?? this.notes,
  );
}

// ─── Exercise Templates ───────────────────────────────────────────────────────

String _normalizeExerciseName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

class ExerciseTemplate {
  final String name;
  final String category;
  final String description;
  final int defaultSets;
  final int defaultReps;

  const ExerciseTemplate({
    required this.name,
    required this.category,
    required this.description,
    this.defaultSets = 3,
    this.defaultReps = 10,
  });
}

const List<ExerciseTemplate> kExerciseTemplates = [
  ExerciseTemplate(
    name: 'Bench Press',
    category: 'Chest',
    description: 'Compound chest exercise',
  ),
  ExerciseTemplate(
    name: 'Incline Bench Press',
    category: 'Chest',
    description: 'Upper chest focus',
  ),
  ExerciseTemplate(
    name: 'Dumbbell Flyes',
    category: 'Chest',
    description: 'Chest isolation',
  ),
  ExerciseTemplate(
    name: 'Push Ups',
    category: 'Chest',
    description: 'Bodyweight chest',
    defaultReps: 15,
  ),
  ExerciseTemplate(
    name: 'Overhead Press',
    category: 'Shoulders',
    description: 'Compound shoulder press',
  ),
  ExerciseTemplate(
    name: 'Lateral Raises',
    category: 'Shoulders',
    description: 'Side delt isolation',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Front Raises',
    category: 'Shoulders',
    description: 'Front delt isolation',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Tricep Pushdown',
    category: 'Triceps',
    description: 'Cable tricep isolation',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Skull Crushers',
    category: 'Triceps',
    description: 'Lying tricep extension',
  ),
  ExerciseTemplate(
    name: 'Dips',
    category: 'Triceps',
    description: 'Bodyweight tricep',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Pull Ups',
    category: 'Back',
    description: 'Compound back exercise',
    defaultReps: 8,
  ),
  ExerciseTemplate(
    name: 'Barbell Row',
    category: 'Back',
    description: 'Compound row',
  ),
  ExerciseTemplate(
    name: 'Lat Pulldown',
    category: 'Back',
    description: 'Lat focus',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Cable Row',
    category: 'Back',
    description: 'Mid back focus',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Deadlift',
    category: 'Back',
    description: 'Compound posterior chain',
    defaultSets: 3,
    defaultReps: 5,
  ),
  ExerciseTemplate(
    name: 'Barbell Curl',
    category: 'Biceps',
    description: 'Compound bicep curl',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Dumbbell Curl',
    category: 'Biceps',
    description: 'Unilateral curl',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Hammer Curl',
    category: 'Biceps',
    description: 'Brachialis focus',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Squat',
    category: 'Legs',
    description: 'King of all exercises',
    defaultSets: 4,
    defaultReps: 8,
  ),
  ExerciseTemplate(
    name: 'Romanian Deadlift',
    category: 'Legs',
    description: 'Hamstring focus',
  ),
  ExerciseTemplate(
    name: 'Leg Press',
    category: 'Legs',
    description: 'Machine quad press',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Leg Curl',
    category: 'Legs',
    description: 'Hamstring isolation',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Leg Extension',
    category: 'Legs',
    description: 'Quad isolation',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Calf Raise',
    category: 'Legs',
    description: 'Calf isolation',
    defaultSets: 3,
    defaultReps: 15,
  ),
  ExerciseTemplate(
    name: 'Lunges',
    category: 'Legs',
    description: 'Unilateral leg',
    defaultReps: 12,
  ),
  ExerciseTemplate(
    name: 'Plank',
    category: 'Core',
    description: 'Core stability',
    defaultSets: 3,
    defaultReps: 60,
  ),
  ExerciseTemplate(
    name: 'Crunches',
    category: 'Core',
    description: 'Ab crunch',
    defaultSets: 3,
    defaultReps: 20,
  ),
  ExerciseTemplate(
    name: 'Cable Crunch',
    category: 'Core',
    description: 'Weighted ab',
    defaultReps: 15,
  ),
];

const Map<String, List<String>> kWorkoutPlans = {
  'Push Day': [
    'Bench Press',
    'Incline Bench Press',
    'Overhead Press',
    'Lateral Raises',
    'Tricep Pushdown',
  ],
  'Pull Day': [
    'Pull Ups',
    'Barbell Row',
    'Lat Pulldown',
    'Barbell Curl',
    'Hammer Curl',
  ],
  'Leg Day': [
    'Squat',
    'Romanian Deadlift',
    'Leg Press',
    'Leg Curl',
    'Calf Raise',
  ],
  'Upper Body': [
    'Bench Press',
    'Barbell Row',
    'Overhead Press',
    'Barbell Curl',
    'Tricep Pushdown',
  ],
  'Full Body': [
    'Squat',
    'Bench Press',
    'Barbell Row',
    'Overhead Press',
    'Deadlift',
  ],
  'Custom': [],
};
