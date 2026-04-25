import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../models/workout_log_model.dart';
import '../services/storage_service.dart';
import 'active_workout_screen.dart';
import 'progress_cam_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(userId: widget.userId),
          _HistoryTab(userId: widget.userId),
          _ProfileTab(userId: widget.userId),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: const Color(0xFF0A0A0A),
          selectedItemColor: const Color(0xFFFF6B35),
          unselectedItemColor: const Color(0xFF444444),
          selectedLabelStyle: GoogleFonts.barlow(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.barlow(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DASHBOARD TAB ────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final String userId;

  const _DashboardTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final uid = userId;

    return SafeArea(
      child: StreamBuilder<UserModel?>(
        stream: FirestoreService.instance.userProfileStream(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          return CustomScrollView(
            slivers: [
              // ── App Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yo, ${user?.name.split(' ').first ?? 'Bro'} 👋',
                              style: GoogleFonts.barlow(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              user?.goalLabel ?? '',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Color(0xFFFF6B35),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            FutureBuilder<int>(
                              future: FirestoreService.instance.getStreak(uid),
                              builder: (ctx, snap) => Text(
                                '${snap.data ?? 0} streak',
                                style: GoogleFonts.barlow(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF6B35),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats Row ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: FutureBuilder<int>(
                    future: FirestoreService.instance.getDaysActiveThisWeek(
                      uid,
                    ),
                    builder: (ctx, snap) {
                      return Row(
                        children: [
                          _StatCard(
                            label: 'Hari ini Minggu',
                            value: '${snap.data ?? 0}/7',
                            icon: Icons.calendar_today_outlined,
                            color: const Color(0xFF00C896),
                          ),
                          const SizedBox(width: 12),
                          if (user != null) ...[
                            _StatCard(
                              label: 'BMI',
                              value: user.bmi.toStringAsFixed(1),
                              icon: Icons.monitor_weight_outlined,
                              color: const Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              label: 'Berat',
                              value: '${user.weightKg.toStringAsFixed(0)}kg',
                              icon: Icons.fitness_center,
                              color: const Color(0xFFFF6B35),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Start Workout ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MULAI WORKOUT',
                            style: GoogleFonts.barlow(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF666666),
                              letterSpacing: 2,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddPlanDialog(context, uid),
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF6B35)),
                            label: Text(
                              'Custom Plan',
                              style: GoogleFonts.barlow(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...kWorkoutPlans.keys.map((plan) {
                        if (plan == 'Custom') return const SizedBox.shrink();
                        return _WorkoutPlanCard(planName: plan, userId: uid);
                      }),
                      _WorkoutPlanCard(planName: 'Custom', userId: uid),
                    ],
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }

  void _showAddPlanDialog(BuildContext context, String uid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text('Custom Workout Plan', style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Plan (misal: Abs Day)'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveWorkoutScreen(
                    planName: controller.text.trim(),
                    userId: uid,
                  ),
                ),
              );
            },
            child: const Text('Buat & Setup'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.barlow(
                fontSize: 20,
                fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

class _WorkoutPlanCard extends StatelessWidget {
  final String planName;
  final String userId;

  const _WorkoutPlanCard({required this.planName, required this.userId});

  IconData get _icon {
    switch (planName) {
      case 'Push Day':
        return Icons.arrow_upward;
      case 'Pull Day':
        return Icons.arrow_downward;
      case 'Leg Day':
        return Icons.directions_run;
      case 'Upper Body':
        return Icons.accessibility_new;
      case 'Full Body':
        return Icons.sports_gymnastics;
      default:
        return Icons.add;
    }
  }

  Color get _color {
    switch (planName) {
      case 'Push Day':
        return const Color(0xFFFF6B35);
      case 'Pull Day':
        return const Color(0xFF6B9EFF);
      case 'Leg Day':
        return const Color(0xFF00C896);
      case 'Upper Body':
        return const Color(0xFFFFD700);
      case 'Full Body':
        return const Color(0xFFFF6B9D);
      default:
        return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = kWorkoutPlans[planName] ?? [];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ActiveWorkoutScreen(planName: planName, userId: userId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                color: _color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName,
                    style: GoogleFonts.barlow(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    exercises.isEmpty
                        ? 'Buat latihan sendiri'
                        : exercises.take(3).join(', ') +
                              (exercises.length > 3 ? '...' : ''),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _color),
          ],
        ),
      ),
    );
  }
}

// ─── HISTORY TAB ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final String userId;

  const _HistoryTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final uid = userId;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'HISTORY',
              style: GoogleFonts.barlow(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WorkoutLog>>(
              stream: FirestoreService.instance.workoutLogsStream(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  );
                }
                final logs = snap.data ?? [];
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Color(0xFF2A2A2A),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada workout',
                          style: GoogleFonts.barlow(
                            fontSize: 18,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        Text(
                          'Yuk mulai workout pertamamu!',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) =>
                      _WorkoutHistoryCard(log: logs[i], userId: uid),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  final WorkoutLog log;
  final String userId;

  const _WorkoutHistoryCard({required this.log, required this.userId});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy', 'id').format(log.startTime);
    final timeStr = DateFormat('HH:mm').format(log.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.planName,
                        style: GoogleFonts.barlow(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$dateStr · $timeStr',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFF444444),
                    size: 20,
                  ),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          // ── Stats row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                _Chip(Icons.timer_outlined, log.durationFormatted),
                const SizedBox(width: 8),
                _Chip(
                  Icons.check_circle_outline,
                  '${log.totalSetsCompleted} sets',
                ),
                const SizedBox(width: 8),
                _Chip(
                  Icons.bar_chart,
                  '${log.totalVolume.toStringAsFixed(0)} kg vol',
                ),
              ],
            ),
          ),
          // ── Photos preview ──
          if (log.hasPhotos) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: log.photoBase64List.length,
                itemBuilder: (ctx, i) {
                  final bytes = StorageService.base64ToBytes(log.photoBase64List[i]);
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: MemoryImage(bytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          // ── Add photo button ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProgressCamScreen(workoutLog: log, userId: userId),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_a_photo_outlined,
                    size: 16,
                    color: Color(0xFFFF6B35),
                  ),
                  label: Text(
                    'Tambah Foto',
                    style: GoogleFonts.barlow(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF6B35),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Workout?',
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Workout "${log.planName}" akan dihapus permanen.',
          style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirestoreService.instance.deleteWorkoutLog(
                userId: userId,
                logId: log.id,
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF666666)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PROFILE TAB ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  final String userId;

  const _ProfileTab({required this.userId});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _reminderHoursCtrl = TextEditingController(text: '0');
  final _reminderMinutesCtrl = TextEditingController(text: '30');
  final _reminderSecondsCtrl = TextEditingController(text: '0');
  bool _reminderEnabled = false;
  Timer? _reminderTimer;

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _reminderHoursCtrl.dispose();
    _reminderMinutesCtrl.dispose();
    _reminderSecondsCtrl.dispose();
    super.dispose();
  }

  int _parseDurationValue(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  int get _reminderDurationSeconds =>
      (_parseDurationValue(_reminderHoursCtrl) * 3600) +
      (_parseDurationValue(_reminderMinutesCtrl) * 60) +
      _parseDurationValue(_reminderSecondsCtrl);

  String get _reminderDurationLabel =>
      '${_parseDurationValue(_reminderHoursCtrl)} jam '
      '${_parseDurationValue(_reminderMinutesCtrl)} menit '
      '${_parseDurationValue(_reminderSecondsCtrl)} detik';

  Future<void> _scheduleReminderTimer() async {
    final totalSeconds = _reminderDurationSeconds;
    if (totalSeconds <= 0) {
      throw ArgumentError.value(
        totalSeconds,
        'duration',
        'Reminder duration must be greater than zero',
      );
    }

    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(Duration(seconds: totalSeconds), (
      timer,
    ) async {
      if (!mounted || !_reminderEnabled) {
        timer.cancel();
        return;
      }

      await NotificationService.instance.showMotivationNotification();
    });
  }

  Future<void> _showImageSourceActionSheet(UserModel user) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFFF6B35)),
              title: const Text('Ambil Foto', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final file = await StorageService.instance.pickFromCamera();
                if (file != null) _updateProfilePhoto(user, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFFF6B35)),
              title: const Text('Pilih dari Galeri', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final file = await StorageService.instance.pickFromGallery();
                if (file != null) _updateProfilePhoto(user, file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfilePhoto(UserModel user, File file) async {
    final base64 = await StorageService.instance.fileToBase64(file);
    if (base64 != null) {
      await FirestoreService.instance.updateUserProfile(user.uid, {'photoBase64': base64});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui!')));
      }
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin notifikasi belum aktif. Aktifkan dulu untuk test notifikasi.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await NotificationService.instance.showMotivationNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi test sudah dikirim.'),
          backgroundColor: Color(0xFF00C896),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim notifikasi test: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditProfileDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final weightController = TextEditingController(text: user.weightKg.toString());
    final heightController = TextEditingController(text: user.heightCm.toString());
    FitnessGoal selectedGoal = user.goal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Edit Profil', style: GoogleFonts.barlow(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Berat (kg)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(labelText: 'Tinggi (cm)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FitnessGoal>(
                  value: selectedGoal,
                  dropdownColor: const Color(0xFF1A1A1A),
                  items: FitnessGoal.values.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
                  onChanged: (v) => setDialogState(() => selectedGoal = v!),
                  decoration: const InputDecoration(labelText: 'Goal'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final updatedUser = user.copyWith(
                  name: nameController.text,
                  weightKg: double.tryParse(weightController.text) ?? user.weightKg,
                  heightCm: double.tryParse(heightController.text) ?? user.heightCm,
                  goal: selectedGoal,
                );
                await FirestoreService.instance.saveUserProfile(updatedUser);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.userId;

    return SafeArea(
      child: StreamBuilder<UserModel?>(
        stream: FirestoreService.instance.userProfileStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            );
          }
          
          // Jika terjadi error (seperti PERMISSION_DENIED saat logout), 
          // tetap izinkan user untuk logout dengan menampilkan UI sederhana
          if (snap.hasError || !snap.hasData) {
            return _buildErrorOrEmptyProfile(uid, snap.hasError);
          }

          final user = snap.data;
          return _buildProfileContent(user!);
        },
      ),
    );
  }

  Widget _buildErrorOrEmptyProfile(String uid, bool isError) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.cloud_off : Icons.person_off_outlined,
            size: 64,
            color: isError ? Colors.orange : const Color(0xFF2A2A2A),
          ),
          const SizedBox(height: 16),
          Text(
            isError ? 'Sinkronisasi Selesai' : 'Profil Tidak Ditemukan',
            style: GoogleFonts.barlow(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => FirebaseAuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Konfirmasi Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROFIL',
                style: GoogleFonts.barlow(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF6B35)),
                onPressed: () => _showEditProfileDialog(user),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── User card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showImageSourceActionSheet(user),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.2),
                      shape: BoxShape.circle,
                      image: user.photoBase64 != null
                          ? DecorationImage(
                              image: MemoryImage(StorageService.base64ToBytes(user.photoBase64!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: user.photoBase64 == null
                        ? const Icon(Icons.add_a_photo, color: Color(0xFFFF6B35), size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : '-',
                        style: GoogleFonts.barlow(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.goalLabel,
                        style: GoogleFonts.barlow(
                          fontSize: 13,
                          color: const Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Stats ──
          Row(
            children: [
              _ProfileStat(
                'Berat',
                '${user.weightKg.toStringAsFixed(0)} kg',
              ),
              const SizedBox(width: 12),
              _ProfileStat(
                'Tinggi',
                '${user.heightCm.toStringAsFixed(0)} cm',
              ),
              const SizedBox(width: 12),
              _ProfileStat('BMI', user.bmi.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              user.bmiCategory,
              style: GoogleFonts.barlow(
                fontSize: 13,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // ── Gym Reminder ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REMINDER GYM',
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.alarm, color: Color(0xFFFF6B35)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _reminderDurationLabel,
                        style: GoogleFonts.barlow(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Switch(
                      value: _reminderEnabled,
                      activeColor: const Color(0xFFFF6B35),
                      onChanged: (v) async {
                        if (!v) {
                          _reminderTimer?.cancel();
                          await NotificationService.instance.cancelGymReminder();
                          if (!mounted) return;
                          setState(() => _reminderEnabled = false);
                          return;
                        }

                        final totalSeconds = _reminderDurationSeconds;
                        if (totalSeconds <= 0) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Isi durasi reminder dulu, minimal 1 detik.'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        final granted =
                            await NotificationService.instance.requestPermission();
                        if (!granted) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Izin notifikasi belum aktif. Aktifkan dulu supaya reminder jalan.',
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        try {
                          await NotificationService.instance.cancelGymReminder();
                          await _scheduleReminderTimer();
                          if (!mounted) return;
                          setState(() => _reminderEnabled = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reminder aktif, notifikasi akan muncul dalam $_reminderDurationLabel.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal mengatur reminder: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _reminderHoursCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Jam',
                          suffixText: 'j',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _reminderMinutesCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Menit',
                          suffixText: 'm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _reminderSecondsCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Detik',
                          suffixText: 'd',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── Notification Test ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEST NOTIFIKASI',
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Kirim Notifikasi Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── Logout ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await FirebaseAuthService.instance.signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal logout: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Color(0xFFFF4444)),
              label: Text(
                'LOGOUT',
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF4444),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2A2A2A)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.barlow(
                fontSize: 20,
                fontWeight: FontWeight.w800,
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
      ),
    );
  }
}
