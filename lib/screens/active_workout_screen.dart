import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/workout_log_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/exercise_video_model.dart';
import 'progress_cam_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String planName;
  final String userId;

  const ActiveWorkoutScreen({
    super.key,
    required this.planName,
    required this.userId,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with SingleTickerProviderStateMixin {
  static const int _restMinSeconds = 60;
  static const int _restMaxSeconds = 90;

  late final TabController _tabController;
  final Random _random = Random();

  late List<ExerciseLog> _exercises;
  Timer? _workoutTimer;
  Timer? _restTimer;
  Timer? _plankTimer;

  DateTime? _workoutStartTime;
  int _elapsedSeconds = 0;
  int _restSecondsLeft = 0;
  int _plankSecondsLeft = 0;

  bool _isPlanking = false;
  bool _hasStartedSession = false;
  bool _isResting = false;
  bool _isSaving = false;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _exercises = _buildExercises();
  }

  List<ExerciseLog> _buildExercises() {
    final uuid = const Uuid();
    final templateNames = kWorkoutPlans[widget.planName] ?? [];

    if (templateNames.isEmpty) {
      return <ExerciseLog>[];
    }

    return templateNames.map((name) {
      final template = kExerciseTemplates.firstWhere(
        (item) => item.name == name,
        orElse: () => ExerciseTemplate(
          name: name,
          category: 'Custom',
          description: '',
        ),
      );

      return ExerciseLog(
        id: uuid.v4(),
        name: template.name,
        category: template.category,
        sets: List.generate(
          template.defaultSets,
          (index) => ExerciseSet(
            setNumber: index + 1,
            reps: template.defaultReps,
            weightKg: 0,
          ),
        ),
      );
    }).toList();
  }

  int? get _currentExerciseIndex {
    for (var i = 0; i < _exercises.length; i++) {
      if (_exercises[i].sets.any((set) => !set.isCompleted)) {
        return i;
      }
    }
    return null;
  }

  ExerciseLog? get _currentExercise {
    final index = _currentExerciseIndex;
    if (index == null) return null;
    return _exercises[index];
  }

  int? get _currentSetIndex {
    final exercise = _currentExercise;
    if (exercise == null) return null;
    final index = exercise.sets.indexWhere((set) => !set.isCompleted);
    return index == -1 ? null : index;
  }

  ExerciseSet? get _currentSet {
    final exercise = _currentExercise;
    final setIndex = _currentSetIndex;
    if (exercise == null || setIndex == null) return null;
    return exercise.sets[setIndex];
  }

  bool get _isWorkoutComplete => _currentExercise == null;

  String get _elapsedFormatted {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get _totalSetsCompleted =>
      _exercises.fold<int>(0, (sum, exercise) => sum + exercise.completedSets);

  int get _totalSets =>
      _exercises.fold<int>(0, (sum, exercise) => sum + exercise.sets.length);

  int get _totalExercises => _exercises.length;

  int get _completedExercises =>
      _exercises.where((exercise) => exercise.sets.every((set) => set.isCompleted)).length;

  @override
  void dispose() {
    _tabController.dispose();
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _plankTimer?.cancel();
    super.dispose();
  }

  void _startWorkoutSession() {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambah exercise dulu sebelum mulai latihan'),
          backgroundColor: Color(0xFFFF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_hasStartedSession) {
      setState(() => _isCountingDown = true);
      return;
    }

    _tabController.animateTo(1);
  }

  void _onCountdownFinished() {
    setState(() {
      _isCountingDown = false;
      _hasStartedSession = true;
      _workoutStartTime = DateTime.now();
      _elapsedSeconds = 0;
    });
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
    _tabController.animateTo(1);
  }

  void _updateExercise(int index, {int? sets, int? reps}) {
    setState(() {
      final exercise = _exercises[index];
      if (sets != null) {
        final target = sets.clamp(1, 10);
        if (target > exercise.sets.length) {
          final diff = target - exercise.sets.length;
          final lastReps = exercise.sets.isNotEmpty ? exercise.sets.last.reps : 10;
          for (int i = 0; i < diff; i++) {
            exercise.sets.add(ExerciseSet(
              setNumber: exercise.sets.length + 1,
              reps: lastReps,
              weightKg: 0,
            ));
          }
        } else if (target < exercise.sets.length) {
          exercise.sets.removeRange(target, exercise.sets.length);
        }
      }
      if (reps != null) {
        final target = reps.clamp(1, 300);
        for (var s in exercise.sets) {
          s.reps = target;
        }
      }
    });
  }

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _AddExerciseSheet(
        onAdd: (exercise) {
          setState(() => _exercises.add(exercise));
        },
      ),
    );
  }

  void _removeExercise(int index) {
    if (_hasStartedSession) return;
    setState(() => _exercises.removeAt(index));
  }

  int _nextRestSeconds() => _restMinSeconds + _random.nextInt(
        _restMaxSeconds - _restMinSeconds + 1,
      );

  Future<void> _startRestCycle(String exerciseName) async {
    _restTimer?.cancel();
    final seconds = _nextRestSeconds();

    setState(() {
      _isResting = true;
      _restSecondsLeft = seconds;
    });

    try {
      await NotificationService.instance.scheduleRestTimer(
        seconds: seconds,
        exerciseName: exerciseName,
      );
    } catch (_) {
      // In-app timer tetap jalan walaupun notifikasi gagal.
    }

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restSecondsLeft <= 1) {
        timer.cancel();
        NotificationService.instance.cancelRestTimer();
        setState(() {
          _isResting = false;
          _restSecondsLeft = 0;
        });
        HapticFeedback.mediumImpact();
      } else {
        setState(() => _restSecondsLeft--);
      }
    });
  }

  void _startPlankTimer() {
    final set = _currentSet;
    if (set == null) return;

    setState(() {
      _isPlanking = true;
      _plankSecondsLeft = set.reps;
    });

    _plankTimer?.cancel();
    _plankTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_plankSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _isPlanking = false);
        _completeCurrentSet();
      } else {
        setState(() => _plankSecondsLeft--);
      }
    });
  }

  Future<void> _skipRest() async {
    _restTimer?.cancel();
    await NotificationService.instance.cancelRestTimer();

    if (!mounted) return;
    setState(() {
      _isResting = false;
      _restSecondsLeft = 0;
    });
  }

  Future<void> _completeCurrentSet() async {
    if (_isSaving) return;

    _plankTimer?.cancel();
    setState(() {
      _isPlanking = false;
    });

    final exerciseIndex = _currentExerciseIndex;
    final setIndex = _currentSetIndex;

    if (exerciseIndex == null || setIndex == null) return;

    final exercise = _exercises[exerciseIndex];
    final isLastSetOfExercise = setIndex == exercise.sets.length - 1;
    final isLastExercise = exerciseIndex == _exercises.length - 1;

    setState(() {
      exercise.sets[setIndex].isCompleted = true;
    });

    HapticFeedback.lightImpact();

    if (isLastSetOfExercise && isLastExercise) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _finishWorkout();
      return;
    }

    await _startRestCycle(exercise.name);
  }

  Future<void> _finishWorkout() async {
    if (_isSaving) return;

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambah exercise dulu!'),
          backgroundColor: Color(0xFFFF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    _workoutTimer?.cancel();
    _restTimer?.cancel();
    await NotificationService.instance.cancelRestTimer();

    final startTime = _workoutStartTime ?? DateTime.now();
    final endTime = DateTime.now();
    final durationSeconds = max(1, endTime.difference(startTime).inSeconds);

    final log = WorkoutLog(
      id: '',
      userId: widget.userId,
      planName: widget.planName,
      exercises: _exercises,
      startTime: startTime,
      endTime: endTime,
      durationSeconds: durationSeconds,
    );

    try {
      final logId = await FirestoreService.instance.createWorkoutLog(log);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProgressCamScreen(
            workoutLog: WorkoutLog(
              id: logId,
              userId: widget.userId,
              planName: widget.planName,
              exercises: _exercises,
              startTime: startTime,
              endTime: endTime,
              durationSeconds: durationSeconds,
            ),
            userId: widget.userId,
            isPostWorkout: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan workout: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTimerChip() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Color(0xFFFF6B35), size: 14),
          const SizedBox(width: 4),
          Text(
            _elapsedFormatted,
            style: GoogleFonts.barlow(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planName),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6B35),
          unselectedLabelColor: const Color(0xFF666666),
          indicatorColor: const Color(0xFFFF6B35),
          tabs: const [
            Tab(text: 'Plan'),
            Tab(text: 'Workout'),
          ],
        ),
        actions: [
          if (_hasStartedSession || _elapsedSeconds > 0) _buildTimerChip(),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _SetupTab(
                exercises: _exercises,
                hasStartedSession: _hasStartedSession,
                onAddExercise: _addExercise,
                onUpdateExercise: _updateExercise,
                onRemoveExercise: _removeExercise,
                onStartWorkout: _startWorkoutSession,
              ),
              _WorkoutTab(
                exercises: _exercises,
                isPlanking: _isPlanking,
                plankSecondsLeft: _plankSecondsLeft,
                isWorkoutStarted: _hasStartedSession,
                isResting: _isResting,
                restSecondsLeft: _restSecondsLeft,
                isSaving: _isSaving,
                totalSetsCompleted: _totalSetsCompleted,
                totalSets: _totalSets,
                totalExercises: _totalExercises,
                completedExercises: _completedExercises,
                elapsedFormatted: _elapsedFormatted,
                currentExercise: _currentExercise,
                currentSet: _currentSet,
                isWorkoutComplete: _isWorkoutComplete,
                onStartWorkout: _startWorkoutSession,
                onGoToPlanTab: () => _tabController.animateTo(0),
                onCompleteCurrentSet: _completeCurrentSet,
                onSkipRest: _skipRest,
                onFinishWorkout: _finishWorkout,
                onStartPlank: _startPlankTimer,
              ),
            ],
          ),
          if (_isCountingDown)
            _CountdownOverlay(onFinished: _onCountdownFinished),
        ],
      ),
    );
  }
}

class _SetupTab extends StatelessWidget {
  final List<ExerciseLog> exercises;
  final bool hasStartedSession;
  final VoidCallback onAddExercise;
  final Function(int, {int? sets, int? reps}) onUpdateExercise;
  final ValueChanged<int> onRemoveExercise;
  final VoidCallback onStartWorkout;

  const _SetupTab({
    required this.exercises,
    required this.hasStartedSession,
    required this.onAddExercise,
    required this.onUpdateExercise,
    required this.onRemoveExercise,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: exercises.isEmpty
              ? _EmptyExerciseState(
                  title: 'Belum ada exercise',
                  subtitle: 'Tambahkan exercise dulu untuk mulai workout.',
                  actionLabel: 'Tambah Exercise',
                  onAction: onAddExercise,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return _SetupExerciseCard(
                      exercise: exercise,
                      index: index,
                      onUpdate: ({int? sets, int? reps}) {
                        if (hasStartedSession) return;
                        onUpdateExercise(index, sets: sets, reps: reps);
                      },
                      canRemove: !hasStartedSession,
                      onRemove: () => onRemoveExercise(index),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
            ),
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasStartedSession ? null : onAddExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Exercise'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF333333)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onStartWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C896),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasStartedSession ? 'LANJUT WORKOUT' : 'MULAI LATIHAN',
                      style: GoogleFonts.barlow(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutTab extends StatelessWidget {
  final List<ExerciseLog> exercises;
  final bool isPlanking;
  final int plankSecondsLeft;
  final bool isWorkoutStarted;
  final bool isResting;
  final int restSecondsLeft;
  final bool isSaving;
  final int totalSetsCompleted;
  final int totalSets;
  final int totalExercises;
  final int completedExercises;
  final String elapsedFormatted;
  final ExerciseLog? currentExercise;
  final ExerciseSet? currentSet;
  final bool isWorkoutComplete;
  final VoidCallback onStartWorkout;
  final VoidCallback onGoToPlanTab;
  final Future<void> Function() onCompleteCurrentSet;
  final Future<void> Function() onSkipRest;
  final Future<void> Function() onFinishWorkout;
  final VoidCallback onStartPlank;

  const _WorkoutTab({
    required this.exercises,
    required this.isWorkoutStarted,
    required this.isResting,
    required this.isPlanking,
    required this.plankSecondsLeft,
    required this.restSecondsLeft,
    required this.isSaving,
    required this.totalSetsCompleted,
    required this.totalSets,
    required this.totalExercises,
    required this.completedExercises,
    required this.elapsedFormatted,
    required this.currentExercise,
    required this.currentSet,
    required this.isWorkoutComplete,
    required this.onStartWorkout,
    required this.onGoToPlanTab,
    required this.onCompleteCurrentSet,
    required this.onSkipRest,
    required this.onFinishWorkout,
    required this.onStartPlank,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWorkoutStarted) {
      return _WorkoutIntroState(onStartWorkout: onStartWorkout);
    }

    if (exercises.isEmpty) {
      return _EmptyExerciseState(
        title: 'Belum ada exercise',
        subtitle: 'Tambahkan exercise di tab Plan dulu.',
        actionLabel: 'Ke Tab Plan',
        onAction: onGoToPlanTab,
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _WorkoutProgressCard(
            elapsedFormatted: elapsedFormatted,
            completedExercises: completedExercises,
            totalExercises: totalExercises,
            totalSetsCompleted: totalSetsCompleted,
            totalSets: totalSets,
          ),
          const SizedBox(height: 16),
          if (isResting)
            _RestCountdownBanner(
              secondsLeft: restSecondsLeft,
              onSkip: onSkipRest,
            ),
          if (isResting) const SizedBox(height: 16),
          if (isWorkoutComplete)
            _WorkoutCompleteCard(
              isSaving: isSaving,
              onFinishWorkout: onFinishWorkout,
            )
          else if (currentExercise != null && currentSet != null)
            _CurrentExerciseCard(
              exercise: currentExercise!,
              set: currentSet!,
              isResting: isResting,
              isSaving: isSaving,
              isPlanking: isPlanking,
              plankSecondsLeft: plankSecondsLeft,
              onCompleteCurrentSet: onCompleteCurrentSet,
              onStartPlank: onStartPlank,
            ),
          const SizedBox(height: 16),
          Text(
            'Rangkuman latihan',
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 10),
          ...exercises.asMap().entries.map(
                (entry) => _WorkoutSummaryCard(
                  exercise: entry.value,
                  isActive: entry.value == currentExercise,
                ),
              ),
        ],
      ),
    );
  }
}

class _WorkoutIntroState extends StatelessWidget {
  final VoidCallback onStartWorkout;

  const _WorkoutIntroState({required this.onStartWorkout});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 64,
              color: Color(0xFF2A2A2A),
            ),
            const SizedBox(height: 16),
            Text(
              'Siap mulai latihan?',
              style: GoogleFonts.barlow(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol di bawah untuk pindah ke mode workout.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onStartWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: Text(
                'MULAI LATIHAN',
                style: GoogleFonts.barlow(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutProgressCard extends StatelessWidget {
  final String elapsedFormatted;
  final int completedExercises;
  final int totalExercises;
  final int totalSetsCompleted;
  final int totalSets;

  const _WorkoutProgressCard({
    required this.elapsedFormatted,
    required this.completedExercises,
    required this.totalExercises,
    required this.totalSetsCompleted,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSets == 0 ? 0.0 : totalSetsCompleted / totalSets;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text(
                elapsedFormatted,
                style: GoogleFonts.barlow(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Exercise',
                  value: '$completedExercises/$totalExercises',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  label: 'Set',
                  value: '$totalSetsCompleted/$totalSets',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFF222222),
              color: const Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.barlow(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentExerciseCard extends StatelessWidget {
  final ExerciseLog exercise;
  final ExerciseSet set;
  final bool isResting;
  final bool isSaving;
  final bool isPlanking;
  final int plankSecondsLeft;
  final VoidCallback onStartPlank;
  final Future<void> Function() onCompleteCurrentSet;

  const _CurrentExerciseCard({
    required this.exercise,
    required this.set,
    required this.isResting,
    required this.isSaving,
    required this.isPlanking,
    required this.plankSecondsLeft,
    required this.onStartPlank,
    required this.onCompleteCurrentSet,
  });

  @override
  Widget build(BuildContext context) {
    final totalSets = exercise.sets.length;
    final currentSetNumber = set.setNumber;
    final isLastSet = currentSetNumber == totalSets;
    final buttonLabel = isLastSet ? 'SELESAI LATIHAN' : 'SELESAI SET';
    final isTimed = exercise.isTimedExercise;

    final displayButtonLabel = isPlanking
        ? 'HOLD... ($plankSecondsLeft s)'
        : (isTimed ? 'MULAI PLANK' : buttonLabel);
    
    final tutorial = ExerciseVideoCatalog.findByExerciseName(exercise.name);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LATIHAN AKTIF',
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.name,
            style: GoogleFonts.barlow(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            exercise.category,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: const Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 12),
          if (tutorial != null)
            _ExerciseVideoPlayer(tutorial: tutorial),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DetailBox(
                  label: 'SET',
                  value: '${set.setNumber}/$totalSets',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailBox(
                  label: 'REPS',
                  value: '${set.reps}${isTimed ? "s" : ""}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailBox(
                  label: 'BEBAN',
                  value: set.weightKg > 0
                      ? '${set.weightKg.toStringAsFixed(set.weightKg == set.weightKg.roundToDouble() ? 0 : 1)} kg'
                      : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isResting
                ? 'Istirahat dulu sebelum set berikutnya'
                : (isPlanking
                    ? 'Tahan posisi tubuhmu, jangan menyerah!'
                    : 'Tekan tombol untuk memulai latihan'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isResting || isSaving || isPlanking)
                  ? null
                  : (isTimed ? onStartPlank : onCompleteCurrentSet),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlanking ? const Color(0xFF1A1A1A) : const Color(0xFF00C896),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isPlanking
                      ? Icons.hourglass_bottom
                      : (isLastSet ? Icons.flag : Icons.check_circle_outline)),
              label: Text(displayButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseVideoPlayer extends StatefulWidget {
  final ExerciseVideoTutorial tutorial;

  const _ExerciseVideoPlayer({required this.tutorial});

  @override
  State<_ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<_ExerciseVideoPlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.tutorial.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        controlsVisibleAtStart: true,
        enableCaption: true,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _ExerciseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tutorial.youtubeId != widget.tutorial.youtubeId) {
      _controller.load(widget.tutorial.youtubeId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openTutorialExternally() async {
    final uri = Uri.parse(
      'https://www.youtube.com/watch?v=${widget.tutorial.youtubeId}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildWebFallback() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://img.youtube.com/vi/${widget.tutorial.youtubeId}/hqdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Color(0xFFFF6B35),
                    size: 72,
                  ),
                ),
              ),
              Container(color: Colors.black.withOpacity(0.35)),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressed: _openTutorialExternally,
                          tooltip: 'Buka tutorial YouTube',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.tutorial.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.barlow(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ketuk untuk membuka video tutorial',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openTutorialExternally,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Buka Tutorial'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFFF6B35)),
                          backgroundColor:
                              const Color(0xFFFF6B35).withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebFallback();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFFFF6B35),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tutorial.title,
                    style: GoogleFonts.barlow(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tutorial.description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                  if (widget.tutorial.instructions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...widget.tutorial.instructions.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("• ",
                                  style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFFFF6B35),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              Expanded(
                                child: Text(
                                  step,
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11, color: const Color(0xFFDDDDDD)),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openTutorialExternally,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Buka di YouTube'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF6B35)),
                      backgroundColor:
                          const Color(0xFFFF6B35).withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  final String label;
  final String value;

  const _DetailBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.barlow(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const _CountdownOverlay({required this.onFinished});

  @override
  State<_CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<_CountdownOverlay> with SingleTickerProviderStateMixin {
  int _count = 3;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 60,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _runCountdown();
  }

  Future<void> _runCountdown() async {
    for (int i = 3; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _count = i);
      HapticFeedback.mediumImpact();
      await _controller.forward(from: 0.0);
    }
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _count == 0 ? 'GO!' : '$_count';
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                text,
                style: GoogleFonts.barlow(fontSize: 140, fontWeight: FontWeight.w900, color: const Color(0xFFFF6B35), fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RestCountdownBanner extends StatelessWidget {
  final int secondsLeft;
  final Future<void> Function() onSkip;

  const _RestCountdownBanner({
    required this.secondsLeft,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C896).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Color(0xFF00C896), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REST TIME',
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: const Color(0xFF00C896),
                  ),
                ),
                Text(
                  '$secondsLeft detik lagi',
                  style: GoogleFonts.barlow(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00C896),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              backgroundColor: const Color(0xFF00C896).withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'SKIP',
              style: GoogleFonts.barlow(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCompleteCard extends StatelessWidget {
  final bool isSaving;
  final Future<void> Function() onFinishWorkout;

  const _WorkoutCompleteCard({
    required this.isSaving,
    required this.onFinishWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00C896).withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration, size: 52, color: Color(0xFF00C896)),
          const SizedBox(height: 12),
          Text(
            'Workout selesai!',
            style: GoogleFonts.barlow(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua set sudah selesai. Simpan ke history sekarang.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onFinishWorkout,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Menyimpan...' : 'Simpan ke History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C896),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSummaryCard extends StatelessWidget {
  final ExerciseLog exercise;
  final bool isActive;

  const _WorkoutSummaryCard({
    required this.exercise,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final completedSets = exercise.completedSets;
    final totalSets = exercise.sets.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF141414) : const Color(0xFF101010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFF6B35).withOpacity(0.35)
              : const Color(0xFF222222),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFF6B35).withOpacity(0.14)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isActive ? Icons.play_arrow : Icons.fitness_center,
              color: isActive
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.category} · $completedSets/$totalSets set selesai',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupExerciseCard extends StatelessWidget {
  final ExerciseLog exercise;
  final int index;
  final Function({int? sets, int? reps}) onUpdate;
  final bool canRemove;
  final VoidCallback onRemove;

  const _SetupExerciseCard({
    required this.exercise,
    required this.index,
    required this.onUpdate,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final setCount = exercise.sets.length;
    final reps = setCount > 0 ? exercise.sets.first.reps : 0;
    final isTimed = exercise.isTimedExercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.barlow(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF6B35),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.category} · $setCount set × $reps ${isTimed ? "detik" : "reps"}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                  ),
                ),
                if (canRemove) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildCounter(
                        label: 'Sets',
                        value: setCount,
                        onDecrement: () => onUpdate(sets: setCount - 1),
                        onIncrement: () => onUpdate(sets: setCount + 1),
                      ),
                      const SizedBox(width: 16),
                      _buildCounter(
                        label: isTimed ? 'Detik' : 'Reps',
                        value: reps,
                        onDecrement: () => onUpdate(reps: reps - (isTimed ? 5 : 1)),
                        onIncrement: () => onUpdate(reps: reps + (isTimed ? 5 : 1)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  Widget _buildCounter({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.barlow(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _counterBtn(Icons.remove, onDecrement),
              SizedBox(
                width: 30,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.barlow(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _counterBtn(Icons.add, onIncrement),
            ],
          ),
        ),
      ],
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: const Color(0xFFFF6B35)),
      ),
    );
  }
}

class _EmptyExerciseState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyExerciseState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 64,
              color: Color(0xFF2A2A2A),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.barlow(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseSheet extends StatefulWidget {
  final Function(ExerciseLog) onAdd;

  const _AddExerciseSheet({required this.onAdd});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  String _search = '';
  String _selectedCategory = 'All';

  List<String> get _categories => [
        'All',
        ...kExerciseTemplates.map((item) => item.category).toSet().toList(),
      ];

  List<ExerciseTemplate> get _filteredExercises => kExerciseTemplates.where((item) {
        final matchesCategory =
            _selectedCategory == 'All' || item.category == _selectedCategory;
        final matchesSearch =
            item.name.toLowerCase().contains(_search.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'PILIH EXERCISE',
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari exercise...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF555555)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (_, index) {
                final category = _categories[index];
                final selected = category == _selectedCategory;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFF2A2A2A),
                      ),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.barlow(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : const Color(0xFF888888),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredExercises.length,
              itemBuilder: (_, index) {
                final template = _filteredExercises[index];
                return ListTile(
                  onTap: () {
                    final uuid = const Uuid();
                    final exercise = ExerciseLog(
                      id: uuid.v4(),
                      name: template.name,
                      category: template.category,
                      sets: List.generate(
                        template.defaultSets,
                        (setIndex) => ExerciseSet(
                          setNumber: setIndex + 1,
                          reps: template.defaultReps,
                          weightKg: 0,
                        ),
                      ),
                    );
                    widget.onAdd(exercise);
                    Navigator.pop(context);
                  },
                  title: Text(
                    template.name,
                    style: GoogleFonts.barlow(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${template.category} · ${template.defaultSets} sets × ${template.defaultReps} reps',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.add_circle,
                    color: Color(0xFFFF6B35),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
