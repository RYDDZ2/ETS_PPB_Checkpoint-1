import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

/// StorageService: no Firebase Storage billing.
/// Photos compressed & stored as base64 in Firestore documents.
class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  Future<File?> pickFromCamera() async {
    final granted = await requestCameraPermission();
    if (!granted) return null;
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<File?> pickFromGallery() async {
    final granted = await requestGalleryPermission();
    if (!granted) return null;
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Compress image and return base64 string safe for Firestore (<900KB).
  Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      final resized = img.copyResize(
        original,
        width: original.width > 600 ? 600 : original.width,
        height: original.height > 600 ? 600 : original.height,
      );
      final compressed = img.encodeJpg(resized, quality: 60);
      final base64Str = base64Encode(compressed);

      if (base64Str.length > 900000) {
        final smaller = img.copyResize(original, width: 400);
        final recompressed = img.encodeJpg(smaller, quality: 50);
        return base64Encode(recompressed);
      }
      return base64Str;
    } catch (e) {
      return null;
    }
  }

  static Uint8List base64ToBytes(String base64Str) => base64Decode(base64Str);
}
