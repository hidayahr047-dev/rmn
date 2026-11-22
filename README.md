# Bakso Kang Maman (Flutter)

Implementasi makalah "Perancangan Sistem Informasi Pemesanan Bakso Kang Maman Berbasis Aplikasi".

## Cara menjalankan di VS Code
1. Pasang Flutter SDK (https://docs.flutter.dev/get-started/install) dan ekstensi **Flutter** + **Dart** di VS Code.
2. Jalankan `flutter doctor` sampai Android toolchain / emulator siap.
3. Buka terminal, lalu:
   ```
   flutter create bakso_kang_maman
   cd bakso_kang_maman
   ```
4. Ganti `pubspec.yaml` dan isi folder `lib/` dengan file dari proyek ini
   (`main.dart`, `models.dart`, `store.dart`, `customer.dart`, `admin.dart`).
5. Hapus file `test/widget_test.dart` (bawaan Flutter, merujuk ke kode lama).
6. `flutter pub get`
7. Pilih emulator/HP di pojok kanan bawah VS Code, lalu tekan **F5** (atau `flutter run`).

## Akun demo
- Pelanggan: rahman@mail.com / 123456
- Admin: admin@kangmaman.id / admin123

## Pemetaan ke makalah
| Makalah | Kode |
| --- | --- |
| Class diagram (User, Produk, Keranjang, Pesanan, Pembayaran) | lib/models.dart |
| Sequence diagram (aplikasi + database) | lib/store.dart |
| Menu Login | AuthPage di lib/main.dart |
| Menu Utama, Pembayaran, Status Pesanan, Profile | lib/customer.dart |
| Use case admin (produk, stok, pesanan, pelanggan, laporan) | lib/admin.dart |
