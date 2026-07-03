# AlarmKu — Pengingat Minum Obat

Aplikasi mobile Flutter untuk pengingat jadwal minum obat harian.  
Local notification, offline-first, no backend server.

---

## Fitur

- Register & login akun (data lokal SQLite)
- Dashboard home dengan profil & greeting
- Tambah, edit, hapus alarm obat
- Mode alarm: **sekali** atau **berulang** (pilih hari)
- Countdown real-time ke alarm berikutnya
- Toggle aktif / nonaktif per alarm
- 5 pilihan nada dering alarm
- Permission check notifikasi otomatis
- Edit profil (nama, no HP)
- Konfirmasi dialog untuk hapus & logout
- Warna warm terracotta & sage, minimalis

---

## Tech Stack

| Komponen | Library |
|---|---|
| Database lokal | `sqflite` + `path` |
| Notifikasi lokal | `flutter_local_notifications` |
| Timezone | `timezone` + `flutter_timezone` |
| Session | `shared_preferences` |
| Permission | `permission_handler` |
| Enkripsi password | `crypto` (SHA-256) |

---

## Prasyarat

Pastikan sudah terinstall:

- **Flutter SDK** 3.19+ → [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install)
- **Android Studio** atau **VS Code** dengan Flutter extension
- **Android SDK** (API level 21+)
- **Java 17** (biasanya sudah bundled di Android Studio)

Cek instalasi:
```bash
flutter doctor
```
Semua harus centang hijau sebelum lanjut.

---

## Cara Setup Project

### 1. Clone / extract project

Kalau dari ZIP:
```
Ekstrak file zip → buka folder `pengingat_obat`
```

Kalau dari GitHub:
```bash
git clone https://github.com/username/pengingat-obat.git
cd pengingat-obat
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Cek device

Sambungkan HP Android via USB, aktifkan **Developer Options** dan **USB Debugging**.

```bash
flutter devices
```
Pastikan HP kamu muncul di list.

### 4. Jalankan di HP (development)

```bash
flutter run
```

Atau pilih device di VS Code / Android Studio lalu tekan ▶

---

## Build APK Release

```bash
flutter build apk --release
```

File APK ada di:
```
build/app/outputs/flutter-apk/app-release.apk
```

Install ke HP:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Atau transfer file APK ke HP, lalu install manual (pastikan "Install dari sumber tidak dikenal" diaktifkan di Settings HP).

---

## Setup Izin Alarm di Android 12+

Setelah install APK, kalau alarm tidak bunyi:

1. Buka **Settings HP** → Apps → AlarmKu → Permissions
2. Aktifkan **Notifications**
3. Settings → Apps → AlarmKu → Battery → pilih **Unrestricted**
4. Settings → Alarms & Reminders → aktifkan untuk AlarmKu

---

## Struktur File Project

```
pengingat_obat/
├── lib/
│   ├── main.dart                    # Entry point, splash screen
│   ├── models/
│   │   └── medicine.dart            # Model Medicine, User, AlarmSound
│   ├── services/
│   │   ├── auth_service.dart        # Register, login, logout, session
│   │   ├── database_service.dart    # CRUD SQLite
│   │   └── notification_service.dart # Schedule & cancel alarm
│   ├── screens/
│   │   ├── home_screen.dart         # Dashboard utama
│   │   ├── login_screen.dart        # Halaman login
│   │   └── register_screen.dart     # Halaman register
│   ├── widgets/
│   │   ├── add_edit_medicine_sheet.dart  # Bottom sheet tambah/edit alarm
│   │   ├── confirm_dialog.dart      # Reusable dialog konfirmasi
│   │   └── edit_profile_sheet.dart  # Bottom sheet edit profil
│   └── utils/
│       └── app_theme.dart           # Warna, font, theme
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      # Permissions Android
├── assets/
│   └── sounds/                      # (opsional) file audio nada dering
│       ├── gentle.mp3
│       ├── urgent.mp3
│       ├── classic.mp3
│       └── digital.mp3
└── pubspec.yaml                     # Dependencies
```

---

## Menambahkan Nada Dering Custom (Opsional)

1. Siapkan file MP3 pendek (maks 10 detik)
2. Rename sesuai key: `gentle.mp3`, `urgent.mp3`, `classic.mp3`, `digital.mp3`
3. Taruh di folder `assets/sounds/`
4. **Juga** copy ke `android/app/src/main/res/raw/` (tanpa subfolder) — ini wajib untuk notifikasi Android

Kalau tidak ada file audio, notifikasi akan pakai suara default sistem.

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| `flutter pub get` error | Cek koneksi internet, jalankan ulang |
| Notifikasi tidak muncul | Cek permission di Settings HP |
| Build APK gagal | Jalankan `flutter clean` lalu `flutter pub get` lagi |
| Alarm tidak bunyi saat app ditutup | Aktifkan "Battery Unrestricted" di Settings |
| Gradle error | Pastikan Java 17, update Android Studio |

---

## Akun Demo

Tidak ada akun demo — langsung daftar akun baru via Register.  
Semua data tersimpan lokal di HP, tidak ada server.

---

## Lisensi

MIT — bebas digunakan untuk tugas kuliah dan dikembangkan lebih lanjut.
