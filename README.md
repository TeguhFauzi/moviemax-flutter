# Budget Manager

Aplikasi manajemen keuangan pribadi. Dibuat dengan Flutter, data tersimpan lokal menggunakan SQLite.

## Fitur

- Catat pemasukan & pengeluaran
- 13 kategori bawaan (Makanan, Transportasi, Gaji, Freelance, dll)
- Dashboard: saldo, ringkasan bulanan, grafik kategori
- Daftar transaksi: grup per tanggal, swipe hapus, filter tipe
- Statistik: pie chart, bar chart harian, breakdown kategori
- Tema gelap/terang
- Bahasa Indonesia / English
- Data 100% lokal (SQLite), tanpa login

## Tech Stack

- **Flutter** (Dart)
- **SQLite** via `sqflite`
- **Provider** state management
- **fl_chart** untuk grafik
- **intl** format mata uang & tanggal

## Run

```bash
flutter pub get
flutter run
```

## Struktur

```
lib/
├── main.dart
├── models/
│   ├── transaction_model.dart
│   └── category_model.dart
├── providers/
│   ├── budget_provider.dart
│   └── settings_provider.dart
├── services/
│   └── database_service.dart
└── views/
    ├── home_screen.dart
    ├── dashboard_screen.dart
    ├── add_transaction_screen.dart
    ├── transaction_list_screen.dart
    ├── stats_screen.dart
    └── settings_screen.dart
```
