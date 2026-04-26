class ExerciseVideoTutorial {
  final String exerciseName;
  final String title;
  final String youtubeId;
  final String description;
  final String category;
  final List<String> aliases;
  final List<String> instructions;

  const ExerciseVideoTutorial({
    required this.exerciseName,
    required this.title,
    required this.youtubeId,
    required this.description,
    required this.category,
    this.aliases = const [],
    this.instructions = const [],
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
    instructions: [
      'Perhatikan form dan teknik yang benar pada video.',
      'Mulai dengan beban ringan untuk pemanasan.',
      'Jaga napas tetap teratur selama melakukan gerakan.',
      'Hubungi instruktur jika ragu dengan gerakan tertentu.'
    ],
  );

  static const List<ExerciseVideoTutorial> _tutorials = [
    ExerciseVideoTutorial(
      exerciseName: 'Bench Press',
      title: 'Bench Press Tutorial',
      youtubeId: '9_JPTA3ie7k',
      description: 'Tutorial bench press untuk teknik dasar dan form yang benar.',
      category: 'Chest',
      instructions: [
        'Berbaring di bangku dengan mata tepat di bawah bar.',
        'Genggam bar sedikit lebih lebar dari lebar bahu.',
        'Turunkan bar ke tengah dada dengan terkontrol.',
        'Dorong bar kembali ke atas sampai lengan lurus sepenuhnya.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Incline Bench Press',
      title: 'Incline Bench Press Tutorial',
      youtubeId: '7UB2HQg5FNY',
      description: 'Referensi teknik incline pressing untuk upper chest.',
      category: 'Chest',
      instructions: [
        'Atur bench ke sudut 30-45 derajat.',
        'Genggam bar sedikit lebih lebar dari lebar bahu.',
        'Turunkan bar ke bagian atas dada secara perlahan.',
        'Dorong bar kembali ke atas hingga lengan lurus sepenuhnya.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Dumbbell Flyes',
      title: 'Dumbbell Flyes Tutorial',
      youtubeId: '1ezRy5FcvwY',
      description: 'Referensi gerakan chest isolation dan kontrol beban.',
      category: 'Chest',
      aliases: ['Dumbell Flyes'],
      instructions: [
        'Berbaring telentang, pegang dumbbell di atas dada dengan lengan hampir lurus.',
        'Turunkan dumbbell ke samping dalam busur lebar hingga terasa tarikan di dada.',
        'Jaga sedikit tekukan pada siku agar sendi tidak tertekan.',
        'Tarik kembali dumbbell ke posisi awal menggunakan kekuatan otot dada.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Push Ups',
      title: 'Push Ups Tutorial',
      youtubeId: 'woLWA3zdGes',
      description: 'Referensi bodyweight chest movement dan stabilitas core.',
      category: 'Chest',
      instructions: [
        'Mulai dalam posisi plank dengan tangan sedikit lebih lebar dari bahu.',
        'Turunkan tubuh hingga dada hampir menyentuh lantai.',
        'Jaga siku tetap dekat dengan tubuh (sudut sekitar 45 derajat).',
        'Dorong tubuh kembali ke posisi awal dengan kekuatan tangan.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Overhead Press',
      title: 'Overhead Press Tutorial',
      youtubeId: 'QSBi--cj980',
      description: 'Referensi pressing movement dan kontrol bahu.',
      category: 'Shoulders',
      instructions: [
        'Berdiri tegak, pegang bar setinggi bahu dengan genggaman overhand.',
        'Tekan bar langsung ke atas hingga lengan terkunci di atas kepala.',
        'Jaga core tetap kencang dan hindari melengkungkan punggung bawah.',
        'Turunkan bar kembali ke bahu dengan gerakan terkontrol.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Lateral Raises',
      title: 'Lateral Raises Tutorial',
      youtubeId: 'wZnsZsMywrY',
      description: 'Referensi kontrol gerakan dan stabilisasi bahu.',
      category: 'Shoulders',
      instructions: [
        'Berdiri tegak dengan dumbbell di samping tubuh.',
        'Angkat dumbbell ke samping hingga setinggi bahu dengan siku sedikit ditekuk.',
        'Jaga telapak tangan menghadap ke bawah atau sedikit ke depan.',
        'Turunkan beban secara perlahan ke posisi awal.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Front Raises',
      title: 'Front Raises Tutorial',
      youtubeId: 'ugPIPY7j-GM',
      description: 'Referensi isolasi deltoid dengan tempo yang terkontrol.',
      category: 'Shoulders',
      instructions: [
        'Berdiri tegak dengan dumbbell di depan paha.',
        'Angkat dumbbell lurus ke depan hingga setinggi bahu.',
        'Jangan mengayunkan tubuh (momentum) untuk mengangkat beban.',
        'Turunkan beban secara perlahan ke posisi semula.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Tricep Pushdown',
      title: 'Tricep Pushdown Tutorial',
      youtubeId: 'vyxgVa8_tL8',
      description: 'Referensi ekstensi siku dan kontrol repetisi.',
      category: 'Triceps',
      instructions: [
        'Berdiri di depan mesin kabel, pegang bar dengan genggaman overhand.',
        'Jaga siku tetap menempel erat di samping tubuh selama gerakan.',
        'Tekan beban ke bawah hingga lengan lurus sepenuhnya.',
        'Kembalikan ke posisi awal perlahan tanpa menggerakkan posisi siku.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Skull Crushers',
      title: 'Skull Crushers Tutorial',
      youtubeId: 'D47mYdoKllE',
      description: 'Referensi untuk gerakan elbow extension yang stabil.',
      category: 'Triceps',
      instructions: [
        'Berbaring di bench, pegang bar di atas dada dengan lengan lurus.',
        'Tekuk siku untuk menurunkan bar perlahan ke arah dahi.',
        'Jaga lengan atas tetap vertikal dan diam (jangan biarkan siku bergerak).',
        'Dorong beban kembali ke atas menggunakan kekuatan tricep.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Dips',
      title: 'Dips Tutorial',
      youtubeId: '_wUdg_4wCCk',
      description: 'Referensi untuk gerakan mendorong tubuh dengan kontrol.',
      category: 'Triceps',
      instructions: [
        'Pegang bar paralel, angkat tubuh hingga lengan lurus.',
        'Turunkan tubuh dengan membungkukkan siku hingga lengan atas sejajar lantai.',
        'Condongkan tubuh sedikit ke depan untuk fokus ke otot dada.',
        'Dorong kembali ke atas hingga posisi lengan lurus.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Pull Ups',
      title: 'Pull Ups Tutorial',
      youtubeId: 'wF602AEdTys',
      description: 'Referensi untuk kontrol upper body dan scapular stability.',
      category: 'Back',
      aliases: ['Pull ups'],
      instructions: [
        'Gantung pada bar dengan genggaman lebih lebar dari bahu.',
        'Tarik tubuh ke atas hingga dagu melewati bar.',
        'Fokuskan pada menarik siku ke bawah ke arah pinggul.',
        'Turunkan tubuh secara terkontrol hingga lengan lurus sepenuhnya.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Barbell Row',
      title: 'Barbell Row Tutorial',
      youtubeId: '_g05fGTPZBo',
      description: 'Referensi kontrol punggung dan posisi torso.',
      category: 'Back',
      aliases: ['Barbell Rows'],
      instructions: [
        'Bungkukkan badan dengan punggung lurus, pegang bar genggaman overhand.',
        'Tarik bar ke arah perut bagian bawah.',
        'Peras (squeeze) otot punggung di bagian atas gerakan.',
        'Turunkan bar kembali secara perlahan dan terkontrol.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Lat Pulldown',
      title: 'Lat Pulldown Tutorial',
      youtubeId: 'HRW6o9Udbjg',
      description: 'Referensi menarik beban dengan kontrol dan range of motion.',
      category: 'Back',
      instructions: [
        'Duduk tegak, pegang bar lebar dengan genggaman overhand.',
        'Tarik bar ke bawah menuju dada bagian atas.',
        'Jaga punggung tetap stabil dan jangan menggunakan momentum tubuh.',
        'Lepaskan beban perlahan kembali ke posisi awal.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Cable Row',
      title: 'Cable Row Tutorial',
      youtubeId: 'TLRdVjMPfG0',
      description: 'Referensi untuk gerakan rowing dan retraksi scapula.',
      category: 'Back',
      instructions: [
        'Duduk di mesin, letakkan kaki di pijakan dan pegang handle.',
        'Tarik handle ke arah perut sambil menarik bahu ke belakang.',
        'Jaga punggung tetap tegak dan core kencang selama gerakan.',
        'Rentangkan lengan kembali ke depan secara perlahan.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Deadlift',
      title: 'Deadlift Tutorial',
      youtubeId: 'xfQWZLs2Kfs',
      description: 'Referensi full-body brace dan kontrol beban.',
      category: 'Back',
      instructions: [
        'Berdiri dengan kaki selebar pinggul, bar di atas tengah kaki.',
        'Engsel pinggul ke bawah dan genggam bar di luar kaki.',
        'Jaga punggung tetap lurus dan dada membusung ke depan.',
        'Berdiri tegak dengan mendorong kaki ke lantai sambil menarik beban.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Barbell Curl',
      title: 'Barbell Curl Tutorial',
      youtubeId: 'cHWcRzEYMiQ',
      description: 'Referensi kontrol siku dan tempo reps.',
      category: 'Biceps',
      instructions: [
        'Berdiri tegak, pegang bar dengan genggaman underhand setinggi paha.',
        'Tekuk siku untuk mengangkat bar ke arah bahu.',
        'Jaga siku tetap diam di samping tubuh, jangan biarkan maju ke depan.',
        'Turunkan bar secara perlahan ke posisi awal (fase eksentrik).'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Dumbbell Curl',
      title: 'Dumbbell Curl Tutorial',
      youtubeId: 'UekMr6kus4A',
      description: 'Referensi isolasi lengan dengan kontrol penuh.',
      category: 'Biceps',
      instructions: [
        'Pegang dumbbell di masing-masing tangan, telapak tangan menghadap depan.',
        'Angkat beban ke arah bahu secara bergantian atau bersamaan.',
        'Putar pergelangan tangan agar telapak tangan menghadap ke atas saat mengangkat.',
        'Turunkan beban secara perlahan dan rasakan kontraksinya.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Hammer Curl',
      title: 'Hammer Curl Tutorial',
      youtubeId: 'Q2vJdALRmVY',
      description: 'Referensi curl movement yang stabil.',
      category: 'Biceps',
      instructions: [
        'Pegang dumbbell dengan posisi netral (telapak tangan menghadap tubuh).',
        'Angkat dumbbell ke arah bahu tanpa memutar pergelangan tangan.',
        'Jaga tubuh tetap stabil dan hindari mengayunkan beban.',
        'Turunkan perlahan ke posisi semula.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Squat',
      title: 'Squat Tutorial',
      youtubeId: 'xqvCmoLULNY',
      description: 'Referensi posisi tubuh, brace, dan kontrol repetisi.',
      category: 'Legs',
      instructions: [
        'Letakkan bar di pundak (trapezius), bukan di leher.',
        'Berdiri dengan kaki selebar bahu dan jari kaki sedikit menghadap keluar.',
        'Turunkan pinggul seperti hendak duduk sampai paha sejajar lantai.',
        'Dorong kembali ke atas melalui tumit kaki ke posisi berdiri.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Romanian Deadlift',
      title: 'Romanian Deadlift Tutorial',
      youtubeId: '5WxMW-Fu5KU',
      description: 'Referensi hinging movement dan posisi hip.',
      category: 'Legs',
      instructions: [
        'Berdiri tegak memegang bar, kaki selebar pinggul.',
        'Dorong pinggul ke belakang sambil menurunkan bar di sepanjang kaki.',
        'Jaga lutut sedikit ditekuk dan punggung harus tetap lurus.',
        'Rasakan tarikan di hamstring, lalu dorong pinggul maju untuk kembali berdiri.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Leg Press',
      title: 'Leg Press Tutorial',
      youtubeId: 'EfsrbYKsIzY',
      description: 'Referensi leg drive dan kontrol dorongan beban.',
      category: 'Legs',
      instructions: [
        'Duduk di mesin dengan kaki di platform selebar bahu.',
        'Dorong platform hingga kaki hampir lurus (jangan kunci lutut sepenuhnya).',
        'Turunkan platform perlahan hingga lutut membentuk sudut 90 derajat.',
        'Dorong platform kembali menggunakan kekuatan tumit dan kaki.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Leg Curl',
      title: 'Leg Curl Tutorial',
      youtubeId: '61PY7qSW5ng',
      description: 'Referensi isolasi dengan tempo dan kontrol.',
      category: 'Legs',
      instructions: [
        'Berbaring/duduk di mesin, letakkan roller di atas tumit belakang.',
        'Tekuk kaki sekuat mungkin ke arah paha belakang.',
        'Tahan sejenak di puncak kontraksi untuk merasakan otot hamstring.',
        'Kembalikan ke posisi awal secara perlahan dan terkontrol.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Leg Extension',
      title: 'Leg Extension Tutorial',
      youtubeId: 'COMUw5GXHTs',
      description: 'Referensi isolasi quad dengan range of motion penuh.',
      category: 'Legs',
      instructions: [
        'Duduk di mesin, letakkan kaki di bawah roller setinggi pergelangan kaki.',
        'Luruskan kaki ke depan hingga sejajar lantai.',
        'Rasakan kontraksi kuat pada otot paha depan (quadriceps).',
        'Turunkan kaki kembali secara terkontrol tanpa membiarkan beban terbanting.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Calf Raise',
      title: 'Calf Raise Tutorial',
      youtubeId: '-M4-G8p8fmc',
      description: 'Referensi repetisi terkontrol dan stabilitas.',
      category: 'Legs',
      instructions: [
        'Berdiri di tepi anak tangga atau mesin dengan tumit menggantung.',
        'Angkat tubuh setinggi mungkin dengan bertumpu pada ujung jari kaki.',
        'Tahan sejenak di atas, lalu turunkan tumit hingga di bawah level pijakan.',
        'Lakukan gerakan secara perlahan untuk mendapatkan stretch yang maksimal.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Lunges',
      title: 'Lunges Tutorial',
      youtubeId: 'auyE2hZGB9k',
      description: 'Referensi keseimbangan, langkah, dan kontrol tubuh.',
      category: 'Legs',
      instructions: [
        'Berdiri tegak, ambil langkah besar ke depan dengan satu kaki.',
        'Turunkan pinggul hingga kedua lutut membentuk sudut 90 derajat.',
        'Jaga lutut depan agar tidak melewati ujung jari kaki.',
        'Dorong kembali ke posisi awal dan ulangi dengan kaki lainnya.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Plank',
      title: 'Plank Tutorial',
      youtubeId: 'pvIjsG5Svck',
      description: 'Referensi bracing core dan stabilitas tubuh.',
      category: 'Core',
      instructions: [
        'Letakkan lengan bawah di lantai dengan siku tepat di bawah bahu.',
        'Rentangkan kaki ke belakang dan tumpu beban pada jari kaki.',
        'Kontraksikan otot perut dan glutes untuk menjaga tubuh sejajar.',
        'Tahan posisi tanpa membiarkan pinggul turun atau naik terlalu tinggi.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Crunches',
      title: 'Crunches Tutorial',
      youtubeId: 'grk_p6job48',
      description: 'Referensi kontraksi core dan kontrol tempo.',
      category: 'Core',
      instructions: [
        'Berbaring telentang dengan lutut ditekuk dan kaki rata di lantai.',
        'Angkat bahu sedikit dari lantai menggunakan kekuatan otot perut.',
        'Jaga punggung bawah tetap menempel erat di lantai.',
        'Turunkan bahu perlahan tanpa melepaskan ketegangan otot perut.'
      ],
    ),
    ExerciseVideoTutorial(
      exerciseName: 'Cable Crunch',
      title: 'Cable Crunch Tutorial',
      youtubeId: 'VRXp4xQls2U',
      description: 'Referensi fleksi torso dan kontrol gerakan.',
      category: 'Core',
      instructions: [
        'Berlutut di depan mesin kabel, pegang tali di samping kepala.',
        'Tekuk tubuh ke arah bawah menggunakan kekuatan core.',
        'Usahakan untuk mendekatkan siku ke arah lutut Anda.',
        'Kembali ke posisi awal perlahan sambil menjaga kontrol otot perut.'
      ],
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
