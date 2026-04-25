# 🏋️ GymForm

> **Track. Lift. Grow.** — Your personal gym companion app built with Flutter + Firebase.

---

## 📁 Struktur Project

```
lib/
├── models/
│   ├── user_model.dart          # Model user (berat, tinggi, goal)
│   └── workout_log_model.dart  # Model workout log + exercise + set
├── services/
│   ├── firebase_auth_service.dart   # Login, register, reset password
│   ├── firestore_service.dart       # CRUD workout logs & user profile
│   ├── storage_service.dart         # Camera, gallery, compress → base64
│   └── notification_service.dart   # Rest timer & gym reminder notif
├── screens/
│   ├── auth_screen.dart            # Login & Register
│   ├── home_screen.dart            # Dashboard + History + Profile
│   ├── active_workout_screen.dart  # Core workout: set, reps, timer
│   └── progress_cam_screen.dart    # Upload foto progress
├── firebase_options.dart           # ⚠️ GANTI dengan config kamu
└── main.dart
```

---

## ⚙️ Setup Firebase

### 1. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Login Firebase
```bash
firebase login
```

### 3. Buat project di Firebase Console
- Buka https://console.firebase.google.com
- Buat project baru: **GymForm**
- Enable **Authentication** → Email/Password
- Enable **Firestore Database** → Production mode

### 4. Configure
```bash
cd gymform
flutterfire configure
```
> Ini akan **auto-generate** `lib/firebase_options.dart` — hapus file placeholder yang ada.

---

## 🔥 Firestore Rules

Paste ini di Firebase Console → Firestore → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User hanya bisa akses data sendiri
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /workout_logs/{logId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

## 📱 Android Setup

### `android/app/src/main/AndroidManifest.xml`
Tambahkan permissions:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Di dalam <application> -->
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
  </intent-filter>
</receiver>
```

### `android/app/build.gradle`
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

---

## 🍎 iOS Setup

### `ios/Runner/Info.plist`
Tambahkan:
```xml
<key>NSCameraUsageDescription</key>
<string>GymForm butuh akses kamera untuk foto progress.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>GymForm butuh akses galeri untuk foto progress.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>GymForm butuh akses galeri untuk menyimpan foto.</string>
```

---

## 📦 Install Dependencies

```bash
flutter pub get
```

---

## ▶️ Run

```bash
flutter run
```

---

## 🧠 Arsitektur Foto (No Firebase Storage!)

Daripada pakai Firebase Storage (billing), foto disimpan langsung di Firestore sebagai **base64 string**:

```
User Upload Foto
    ↓
image_picker → File lokal
    ↓
StorageService.fileToBase64()
  - Resize ke max 600×600px
  - Compress JPEG quality 60
  - Hasil ~50–150KB binary → ~70–200KB base64
    ↓
FirestoreService.addPhotoToWorkout()
  - Simpan ke field photoBase64List[]
  - Maks 3 foto per workout log
    ↓
Tampil ulang pakai MemoryImage(base64Decode(str))
```

**Limit:**
- Max **3 foto** per workout log (jaga ukuran dokumen Firestore < 1MB)
- Firestore free tier: 1GB storage, 50K reads/day, 20K writes/day

---

## ✅ Core Features

| Feature | Status | Detail |
|---------|--------|--------|
| Auth (Email) | ✅ | Login, Register, Reset password |
| User Profile | ✅ | Nama, BB, TB, Goal (bulking/cutting/maintain) |
| CRUD Workout Log | ✅ | Create, Read, Delete (Edit via active workout) |
| Exercise Templates | ✅ | 28 exercise, 6 kategori |
| Workout Plans | ✅ | Push/Pull/Leg/Upper/Full Body/Custom |
| Set & Reps Tracking | ✅ | Input weight + reps per set |
| Rest Timer | ✅ | Auto 90 detik, skip, notif |
| Workout Timer | ✅ | Elapsed time realtime |
| Progress Photo | ✅ | Camera + Gallery → Firestore base64 |
| Gym Reminder | ✅ | Daily notif schedulable |
| Streak Counter | ✅ | Hitung hari berturut-turut |
| History | ✅ | List semua workout + foto |
| BMI Calculator | ✅ | Auto dari BB + TB |

---

## 🚀 Tips Development

1. **Emulator**: Gunakan Android Emulator API 33+ untuk test notifikasi
2. **Firestore Indexes**: Kalau ada error index, klik link di console untuk auto-create
3. **Image size**: Kalau foto terlalu besar, turunkan `quality` di `StorageService.fileToBase64()`
4. **Quota Firestore**: Monitor di Firebase Console → Usage

---

## 📱 Screenshots Flow

```
Splash → Auth → Home Dashboard
                    ├── Pilih Workout Plan
                    │       └── Active Workout
                    │               ├── Isi Set/Reps
                    │               ├── Rest Timer
                    │               └── Selesai → Progress Cam
                    ├── History (CRUD)
                    │       └── Lihat/Tambah Foto
                    └── Profil
                            └── Gym Reminder Setting
```