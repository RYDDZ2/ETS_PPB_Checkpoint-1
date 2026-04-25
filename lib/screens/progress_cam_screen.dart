import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/workout_log_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProgressCamScreen extends StatefulWidget {
  final WorkoutLog workoutLog;
  final String userId;
  final bool isPostWorkout; // true = came from finishing workout

  const ProgressCamScreen({
    super.key,
    required this.workoutLog,
    required this.userId,
    this.isPostWorkout = false,
  });

  @override
  State<ProgressCamScreen> createState() => _ProgressCamScreenState();
}

class _ProgressCamScreenState extends State<ProgressCamScreen> {
  // Pending local files (not yet uploaded)
  final List<File> _pendingFiles = [];
  // Already saved base64 (from existing log)
  List<String> _savedBase64 = [];

  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _savedBase64 = List.from(widget.workoutLog.photoBase64List);
  }

  bool get _canAddMore => (_savedBase64.length + _pendingFiles.length) < 3;

  Future<void> _pickFromCamera() async {
    if (!_canAddMore) {
      _showMaxPhotosSnackbar();
      return;
    }
    final file = await StorageService.instance.pickFromCamera();
    if (file != null) setState(() => _pendingFiles.add(file));
  }

  Future<void> _pickFromGallery() async {
    if (!_canAddMore) {
      _showMaxPhotosSnackbar();
      return;
    }
    final file = await StorageService.instance.pickFromGallery();
    if (file != null) setState(() => _pendingFiles.add(file));
  }

  void _showMaxPhotosSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maksimal 3 foto per workout'),
        backgroundColor: Color(0xFFFF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _savePhotos() async {
    if (_pendingFiles.isEmpty) {
      _done();
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatus = 'Mengompresi foto...';
    });

    int processed = 0;
    for (final file in _pendingFiles) {
      setState(
        () => _uploadStatus =
            'Mengompresi foto ${processed + 1}/${_pendingFiles.length}...',
      );

      final base64 = await StorageService.instance.fileToBase64(file);
      if (base64 == null) continue;

      setState(
        () => _uploadStatus =
            'Menyimpan foto ${processed + 1}/${_pendingFiles.length}...',
      );

      final success = await FirestoreService.instance.addPhotoToWorkout(
        userId: widget.userId,
        logId: widget.workoutLog.id,
        base64Photo: base64,
      );

      if (success) {
        setState(() {
          _savedBase64.add(base64);
          processed++;
          _uploadProgress = processed / _pendingFiles.length;
        });
      }
    }

    setState(() {
      _isUploading = false;
      _pendingFiles.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$processed foto berhasil disimpan!'),
          backgroundColor: const Color(0xFF00C896),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _done();
  }

  Future<void> _removeExistingPhoto(int index) async {
    await FirestoreService.instance.removePhotoFromWorkout(
      userId: widget.userId,
      logId: widget.workoutLog.id,
      photoIndex: index,
    );
    setState(() => _savedBase64.removeAt(index));
  }

  void _removePending(int index) {
    setState(() => _pendingFiles.removeAt(index));
  }

  void _done() {
    if (widget.isPostWorkout) {
      // Kembali ke route pertama agar AuthGate tetap aktif.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPostWorkout ? 'Foto Progress 📸' : 'Edit Foto'),
        leading: widget.isPostWorkout
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _done),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header info ──
            if (widget.isPostWorkout) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF00C896).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.celebration,
                      color: Color(0xFF00C896),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workout Selesai! 🔥',
                            style: GoogleFonts.barlow(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.workoutLog.planName} · ${widget.workoutLog.durationFormatted}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: const Color(0xFF00C896),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FOTO PROGRESS',
                    style: GoogleFonts.barlow(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    '${_savedBase64.length + _pendingFiles.length}/3',
                    style: GoogleFonts.barlow(
                      fontSize: 12,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),

            // ── Photo grid ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount:
                      _savedBase64.length +
                      _pendingFiles.length +
                      (_canAddMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    // ── Add button ──
                    if (i == _savedBase64.length + _pendingFiles.length) {
                      return _AddPhotoTile(
                        onCamera: _pickFromCamera,
                        onGallery: _pickFromGallery,
                      );
                    }

                    // ── Saved photo ──
                    if (i < _savedBase64.length) {
                      final bytes = Uint8List.fromList(
                        StorageService.base64ToBytes(_savedBase64[i]),
                      );
                      return _PhotoTile(
                        imageBytes: bytes,
                        label: 'Tersimpan',
                        onDelete: () => _removeExistingPhoto(i),
                      );
                    }

                    // ── Pending photo ──
                    final pendingIdx = i - _savedBase64.length;
                    return _PhotoTile(
                      file: _pendingFiles[pendingIdx],
                      label: 'Belum disimpan',
                      isPending: true,
                      onDelete: () => _removePending(pendingIdx),
                    );
                  },
                ),
              ),
            ),

            // ── Upload progress ──
            if (_isUploading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            color: const Color(0xFF00C896),
                            backgroundColor: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.barlow(
                            color: const Color(0xFF00C896),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _uploadStatus,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Bottom buttons ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(
                children: [
                  if (widget.isPostWorkout)
                    Expanded(
                      child: TextButton(
                        onPressed: _isUploading ? null : _done,
                        child: Text(
                          'Lewati',
                          style: GoogleFonts.barlow(
                            color: const Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (widget.isPostWorkout) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : (_pendingFiles.isEmpty ? _done : _savePhotos),
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _pendingFiles.isEmpty
                                  ? Icons.check
                                  : Icons.cloud_upload_outlined,
                            ),
                      label: Text(
                        _isUploading
                            ? 'Menyimpan...'
                            : _pendingFiles.isEmpty
                            ? 'Selesai'
                            : 'Simpan ${_pendingFiles.length} Foto',
                      ),
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

// ─── PHOTO TILE ───────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final Uint8List? imageBytes;
  final File? file;
  final String label;
  final bool isPending;
  final VoidCallback onDelete;

  const _PhotoTile({
    this.imageBytes,
    this.file,
    required this.label,
    this.isPending = false,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPending
                  ? const Color(0xFFFFD700).withOpacity(0.5)
                  : const Color(0xFF00C896).withOpacity(0.3),
            ),
            image: DecorationImage(
              image: imageBytes != null
                  ? MemoryImage(imageBytes!) as ImageProvider
                  : FileImage(file!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Badge
        Positioned(
          bottom: 6,
          left: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 9,
                color: isPending
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF00C896),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ADD PHOTO TILE ───────────────────────────────────────────────────────────

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _AddPhotoTile({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF141414),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFFF6B35),
                  ),
                  title: Text(
                    'Kamera',
                    style: GoogleFonts.barlow(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFFF6B35),
                  ),
                  title: Text(
                    'Galeri',
                    style: GoogleFonts.barlow(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onGallery();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF333333),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              color: Color(0xFF444444),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              'Tambah\nFoto',
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 11,
                color: const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
