import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  static final FirebaseAuthService instance = FirebaseAuthService._internal();
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Register with email and password
Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required double weightKg,
    required double heightCm,
    required FitnessGoal goal,
  }) async {
    try {
      print('[Auth] Registering user: $email');
      
      User? user;
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        user = credential.user;
      } catch (e) {
        // Cek jika ini adalah error casting Pigeon yang dikenal
        if (e.toString().contains('PigeonUserDetails')) {
          print('[Auth Warning] Caught Pigeon cast error, attempting to recovery...');
          user = _auth.currentUser;
        } else {
          rethrow;
        }
      }

      if (user == null) throw Exception("Gagal membuat user");
      print('[Auth] User created with uid: ${user.uid}');

      // Buat model data dari parameter yang diinput user
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        name: name.trim(),
        weightKg: weightKg,
        heightCm: heightCm,
        goal: goal,
        createdAt: DateTime.now(),
      );

      // PRIORITAS: Simpan profil ke Firestore secepat mungkin
      print('[Auth] Saving profile to Firestore...');
      await FirestoreService.instance.saveUserProfile(userModel);
      print('[Auth] Profile saved successfully');

      try {
        // Update tambahan (opsional/non-kritis)
        await user.updateDisplayName(name.trim());
        await user.reload();
      } catch (e) {
        print('[Auth Warning] Pigeon error ignored: $e');
      }

      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      print('[Auth Error] Firebase: ${e.code}');
      return AuthResult(success: false, error: _parseAuthError(e.code));
    } catch (e) {
      print('[Auth Error] Register failed: $e');
      return AuthResult(success: false, error: 'Gagal membuat profil: ${e.toString()}');
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('[Auth] Logging in user: $email');
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = _auth.currentUser;
      if (user == null) {
        print('[Auth Error] User is null after sign in');
        return AuthResult(
          success: false,
          error: 'Login gagal: User data tidak ditemukan',
        );
      }

      print('[Auth] User logged in with uid: ${user.uid}');

      // Small delay to ensure auth state is fully propagated
      await Future.delayed(const Duration(milliseconds: 200));

      try {
        print('[Auth] Checking if user profile exists in Firestore');
        final existingProfile =
            await FirestoreService.instance.getUserProfile(user.uid);

        if (existingProfile == null) {
          print('[Auth Warning] Profile missing in Firestore for uid: ${user.uid}');
          // Kita tidak membuat profil template di sini lagi agar tidak mengotori database.
          // UI HomeScreen akan menangani ini dengan tombol "Inisialisasi Ulang".
        } else {
          print('[Auth] Profile exists: ${existingProfile.name}');
        }
      } catch (profileError) {
        print('[Auth Error] Error during profile check: $profileError');
      }

      print('[Auth] Login successful');
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      print('[Auth Error] FirebaseAuthException: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: _parseAuthError(e.code));
    } catch (e) {
      print('[Auth Error] Login error: $e');
      return AuthResult(
        success: false,
        error: 'Login gagal: ${e.toString()}',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _parseAuthError(e.code));
    }
  }

  String _parseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Coba login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah (min. 6 karakter).';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }
}

class AuthResult {
  final bool success;
  final String? error;

  AuthResult({required this.success, this.error});
}