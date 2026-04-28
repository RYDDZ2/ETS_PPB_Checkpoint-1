import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class WorkoutAudioService {
  static final WorkoutAudioService instance = WorkoutAudioService._internal();

  WorkoutAudioService._internal();

  final Random _random = Random();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  static const String _countdownAsset =
      'assets/audio/TunePocket-3-2-1-Go-Preview.mp3';
  static const String _finishAsset =
      'assets/audio/freesound_community-decidemp3-14575.mp3';

  static const List<String> _workoutAssets = [
    'assets/audio/TunePocket-80s-Workout-Preview.mp3',
    'assets/audio/TunePocket-Dubstep-Sport-EDM-Preview-1.mp3',
    'assets/audio/TunePocket-Ultimate-90s-Workout-Preview.mp3',
  ];

  Future<void> startWorkoutMusic() async {
    if (_workoutAssets.isEmpty) return;

    final startIndex = _random.nextInt(_workoutAssets.length);
    final orderedAssets = <String>[
      ..._workoutAssets.sublist(startIndex),
      ..._workoutAssets.sublist(0, startIndex),
    ];

    try {
      await _musicPlayer.stop();
      await _musicPlayer.setAudioSource(
        ConcatenatingAudioSource(
          children: orderedAssets
              .map((path) => AudioSource.asset(path))
              .toList(growable: false),
        ),
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
      await _musicPlayer.setLoopMode(LoopMode.all);
      await _musicPlayer.setVolume(0.2); // Contoh: Set ke 0.5 untuk volume 50%
      await _musicPlayer.play();
    } catch (e) {
      debugPrint('WorkoutAudioService.startWorkoutMusic failed: $e');
    }
  }

  Future<void> stopWorkoutMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (e) {
      debugPrint('WorkoutAudioService.stopWorkoutMusic failed: $e');
    }
  }

  /// Mengatur volume musik secara dinamis (nilai antara 0.0 - 1.0)
  Future<void> setMusicVolume(double volume) async {
    try {
      await _musicPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('WorkoutAudioService.setMusicVolume failed: $e');
    }
  }

  Future<void> playCountdownSfx() async {
    await _playSfx(_countdownAsset);
  }

  Future<void> playWorkoutCompleteSfx() async {
    await _playSfx(_finishAsset);
  }

  Future<void> _playSfx(String assetPath) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setAsset(assetPath);
      await _sfxPlayer.setVolume(1.0); // Volume untuk efek suara (SFX)
      await _sfxPlayer.setLoopMode(LoopMode.off);
      await _sfxPlayer.play();
    } catch (e) {
      debugPrint('WorkoutAudioService._playSfx failed for $assetPath: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      await _sfxPlayer.dispose();
    } catch (e) {
      debugPrint('WorkoutAudioService.dispose failed: $e');
    }
  }
}
