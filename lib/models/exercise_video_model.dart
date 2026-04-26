class ExerciseVideoTutorial {
  final String exerciseName;
  final String title;
  final String youtubeId;
  final String description;
  final String category;
  final List<String> aliases;

  const ExerciseVideoTutorial({
    required this.exerciseName,
    required this.title,
    required this.youtubeId,
    required this.description,
    required this.category,
    this.aliases = const [],
  });

  bool matchesExerciseName(String exerciseName) {
    final normalized = _normalizeExerciseName(exerciseName);
    return _normalizeExerciseName(this.exerciseName) == normalized ||
        aliases.any((alias) => _normalizeExerciseName(alias) == normalized);
  }
}

String _normalizeExerciseName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

class ExerciseVideoCatalog {
  static const ExerciseVideoTutorial _defaultTutorial = ExerciseVideoTutorial(
    exerciseName: 'All Exercises',
    title: 'Basic Form Tutorial',
    youtubeId: 'gRVjAtPip0Y',
    description: 'Video tutorial default untuk demonstrasi gerakan latihan.',
    category: 'General',
  );

  static const List<ExerciseVideoTutorial> _tutorials = [
    ExerciseVideoTutorial(
      exerciseName: 'Bench Press',
      title: 'Bench Press Tutorial',
      youtubeId: '9_JPTA3ie7k',
      description: 'Tutorial bench press untuk teknik dasar dan form yang benar.',
      category: 'Chest',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Incline Bench Press',
      title: 'Incline Bench Press Tutorial',
      youtubeId: '7UB2HQg5FNY',
      description: 'Referensi teknik incline pressing untuk upper chest.',
      category: 'Chest',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Dumbbell Flyes',
      title: 'Dumbbell Flyes Tutorial',
      youtubeId: '1ezRy5FcvwY',
      description: 'Referensi gerakan chest isolation dan kontrol beban.',
      category: 'Chest',
      aliases: ['Dumbell Flyes'],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Push Ups',
      title: 'Push Ups Tutorial',
      youtubeId: 'woLWA3zdGes',
      description: 'Referensi bodyweight chest movement dan stabilitas core.',
      category: 'Chest',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Overhead Press',
      title: 'Overhead Press Tutorial',
      youtubeId: 'QSBi--cj980',
      description: 'Referensi pressing movement dan kontrol bahu.',
      category: 'Shoulders',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Lateral Raises',
      title: 'Lateral Raises Tutorial',
      youtubeId: 'wZnsZsMywrY',
      description: 'Referensi kontrol gerakan dan stabilisasi bahu.',
      category: 'Shoulders',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Front Raises',
      title: 'Front Raises Tutorial',
      youtubeId: 'ugPIPY7j-GM',
      description: 'Referensi isolasi deltoid dengan tempo yang terkontrol.',
      category: 'Shoulders',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Tricep Pushdown',
      title: 'Tricep Pushdown Tutorial',
      youtubeId: 'vyxgVa8_tL8',
      description: 'Referensi ekstensi siku dan kontrol repetisi.',
      category: 'Triceps',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Skull Crushers',
      title: 'Skull Crushers Tutorial',
      youtubeId: 'D47mYdoKllE',
      description: 'Referensi untuk gerakan elbow extension yang stabil.',
      category: 'Triceps',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Dips',
      title: 'Dips Tutorial',
      youtubeId: '_wUdg_4wCCk',
      description: 'Referensi untuk gerakan mendorong tubuh dengan kontrol.',
      category: 'Triceps',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Pull Ups',
      title: 'Pull Ups Tutorial',
      youtubeId: 'wF602AEdTys',
      description: 'Referensi untuk kontrol upper body dan scapular stability.',
      category: 'Back',
      aliases: ['Pull ups'],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Barbell Row',
      title: 'Barbell Row Tutorial',
      youtubeId: '_g05fGTPZBo',
      description: 'Referensi kontrol punggung dan posisi torso.',
      category: 'Back',
      aliases: ['Barbell Rows'],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Lat Pulldown',
      title: 'Lat Pulldown Tutorial',
      youtubeId: 'HRW6o9Udbjg',
      description: 'Referensi menarik beban dengan kontrol dan range of motion.',
      category: 'Back',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Cable Row',
      title: 'Cable Row Tutorial',
      youtubeId: 'TLRdVjMPfG0',
      description: 'Referensi untuk gerakan rowing dan retraksi scapula.',
      category: 'Back',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Deadlift',
      title: 'Deadlift Tutorial',
      youtubeId: 'xfQWZLs2Kfs',
      description: 'Referensi full-body brace dan kontrol beban.',
      category: 'Back',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Barbell Curl',
      title: 'Barbell Curl Tutorial',
      youtubeId: 'cHWcRzEYMiQ',
      description: 'Referensi kontrol siku dan tempo reps.',
      category: 'Biceps',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Dumbbell Curl',
      title: 'Dumbbell Curl Tutorial',
      youtubeId: 'UekMr6kus4A',
      description: 'Referensi isolasi lengan dengan kontrol penuh.',
      category: 'Biceps',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Hammer Curl',
      title: 'Hammer Curl Tutorial',
      youtubeId: 'Q2vJdALRmVY',
      description: 'Referensi curl movement yang stabil.',
      category: 'Biceps',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Squat',
      title: 'Squat Tutorial',
      youtubeId: 'xqvCmoLULNY',
      description: 'Referensi posisi tubuh, brace, dan kontrol repetisi.',
      category: 'Legs',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Romanian Deadlift',
      title: 'Romanian Deadlift Tutorial',
      youtubeId: '5WxMW-Fu5KU',
      description: 'Referensi hinging movement dan posisi hip.',
      category: 'Legs',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Leg Press',
      title: 'Leg Press Tutorial',
      youtubeId: 'EfsrbYKsIzY',
      description: 'Referensi leg drive dan kontrol dorongan beban.',
      category: 'Legs',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Leg Curl',
      title: 'Leg Curl Tutorial',
      youtubeId: '61PY7qSW5ng',
      description: 'Referensi isolasi dengan tempo dan kontrol.',
      category: 'Legs',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Leg Extension',
      title: 'Leg Extension Tutorial',
      youtubeId: 'COMUw5GXHTs',
      description: 'Referensi isolasi quad dengan range of motion penuh.',
      category: 'Legs',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Calf Raise',
      title: 'Calf Raise Tutorial',
      youtubeId: '-M4-G8p8fmc',
      description: 'Referensi repetisi terkontrol dan stabilitas.',
      category: 'Legs',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Lunges',
      title: 'Lunges Tutorial',
      youtubeId: 'auyE2hZGB9k',
      description: 'Referensi keseimbangan, langkah, dan kontrol tubuh.',
      category: 'Legs',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Plank',
      title: 'Plank Tutorial',
      youtubeId: 'pvIjsG5Svck',
      description: 'Referensi bracing core dan stabilitas tubuh.',
      category: 'Core',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Crunches',
      title: 'Crunches Tutorial',
      youtubeId: 'grk_p6job48',
      description: 'Referensi kontraksi core dan kontrol tempo.',
      category: 'Core',
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Cable Crunch',
      title: 'Cable Crunch Tutorial',
      youtubeId: 'VRXp4xQls2U',
      description: 'Referensi fleksi torso dan kontrol gerakan.',
      category: 'Core',
    ),
  ];

  static ExerciseVideoTutorial? findByExerciseName(String exerciseName) {
    for (final tutorial in _tutorials) {
      if (tutorial.matchesExerciseName(exerciseName)) {
        return tutorial;
      }
    }

    return _defaultTutorial;
  }

}
