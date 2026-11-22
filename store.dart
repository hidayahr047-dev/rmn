import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Pusat data & logika aplikasi (peran "Aplikasi + Database" pada Sequence Diagram).
/// Data disimpan lokal di perangkat memakai shared_preferences.
class AppStore extends ChangeNotifier {
  static const _key = 'bkm_v1';
  late SharedPreferences _prefs;

  List<User> users = [];
  List<Produk> produk = [];
  List<Pesanan> pesanan = [];
  Map<int, List<CartItem>> keranjang = {};
  int? sessionId;
  int _nu = 3, _np = 5, _no = 1;

  // ---------- util ----------
  T? _find<T>(Iterable<T> l, bool Function(T) f) {
    for (final x in l) {
      if (f(x)) return x;
    }
    return null;
  }

  User? get user => sessionId == null ? null : userById(sessionId!);
  User? userById(int id) => _find(users, (u) => u.id == id);
  Produk? produkById(int id) => _find(produk, (p) => p.id == id);

  // ---------- penyimpanan ----------
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _seed();
    } else {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _seed();
      }
    }
    notifyListeners();
  }

  void _save() {
    _prefs.setString(_key, jsonEncode(_toJson()));
    notifyListeners();
  }

  void _seed() {
    users = [
      User(id: 1, nama: 'Admin Kang Maman', email: 'admin@kangmaman.id', password: 'admin123', alamat: 'Jl. Bakso No. 1', noTelp: '081200000000', role: 'admin'),
      User(id: 2, nama: 'Rahman', email: 'rahman@mail.com', password: '123456', alamat: 'Batam Center', noTelp: '081211112222', role: 'pelanggan'),
    ];
    produk = [
      Produk(id: 1, nama: 'Bakso Urat', harga: 15000, stok: 40, kategori: 'Bakso', gambar: '🍲', deskripsi: 'Bakso urat kenyal dengan kuah kaldu sapi gurih.'),
      Produk(id: 2, nama: 'Bakso Setan', harga: 25000, stok: 30, kategori: 'Bakso', gambar: '🌶️', deskripsi: 'Bakso isi cabai rawit, kuah pedas menggigit.'),
      Produk(id: 3, nama: 'Mie Ayam', harga: 15000, stok: 40, kategori: 'Mie Ayam', gambar: '🍜', deskripsi: 'Mie kenyal dengan topping ayam kecap dan sawi.'),
      Produk(id: 4, nama: 'Mie Ayam Bakso', harga: 25000, stok: 30, kategori: 'Mie Ayam', gambar: '🥢', deskripsi: 'Mie ayam lengkap dengan bakso halus dan bakso urat.'),
    ];
    pesanan = [];
    keranjang = {};
    sessionId = null;
    _nu = 3;
    _np = 5;
    _no = 1;
  }

  Map<String, dynamic> _toJson() => {
        'users': users.map((e) => e.toJson()).toList(),
        'produk': produk.map((e) => e.toJson()).toList(),
        'pesanan': pesanan.map((e) => e.toJson()).toList(),
        'keranjang': keranjang.map((k, v) =>
            MapEntry(k.toString(), v.map((e) => e.toJson()).toList())),
        'session': sessionId,
        'nu': _nu,
        'np': _np,
        'no': _no,
      };

  void _fromJson(Map<String, dynamic> j) {
    users = (j['users'] as List).map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    produk = (j['produk'] as List).map((e) => Produk.fromJson(e as Map<String, dynamic>)).toList();
    pesanan = (j['pesanan'] as List).map((e) => Pesanan.fromJson(e as Map<String, dynamic>)).toList();
    keranjang = (j['keranjang'] as Map<String, dynamic>).map((k, v) => MapEntry(
        int.parse(k),
        (v as List).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList()));
    sessionId = j['session'];
    _nu = j['nu'];
    _np = j['np'];
    _no = j['no'];
  }

  // ---------- akun (use case Daftar, Login) ----------
  String? login(String kunci, String password) {
    final k = kunci.trim().toLowerCase();
    final u = _find(users, (u) =>
        (u.email.toLowerCase() == k || u.nama.toLowerCase() == k) &&
        u.password == password);
    if (u == null) return 'Username/email atau password salah.';
    sessionId = u.id;
    _save();
    return null;
  }

  String? daftar(String nama, String email, String pass, String alamat, String telp) {
    if (nama.trim().isEmpty || email.trim().isEmpty || alamat.trim().isEmpty || telp.trim().isEmpty || pass.length < 6) {
      return 'Lengkapi semua kolom. Password minimal 6 karakter.';
    }
    if (_find(users, (u) => u.email.toLowerCase() == email.trim().toLowerCase()) != null) {
      return 'Email sudah terdaftar.';
    }
    final u = User(id: _nu++, nama: nama.trim(), email: email.trim(), password: pass, alamat: alamat.trim(), noTelp: telp.trim(), role: 'pelanggan');
    users.add(u);
    sessionId = u.id;
    _save();
    return null;
  }

  void logout() {
    sessionId = null;
    _save();
  }

  String? ubahProfil(String nama, String email, String telp, String alamat, String passBaru) {
    if (nama.trim().isEmpty || email.trim().isEmpty) return 'Nama dan email wajib diisi.';
    if (passBaru.isNotEmpty && passBaru.length < 6) return 'Password minimal 6 karakter.';
    final u = user!;
    u.nama = nama.trim();
    u.email = email.trim();
    u.noTelp = telp.trim();
    u.alamat = alamat.trim();
    if (passBaru.isNotEmpty) u.password = passBaru;
    _save();
    return null;
  }

  // ---------- keranjang (use case Memesan Produk, Melihat Keranjang) ----------
  List<CartItem> get cart => keranjang.putIfAbsent(sessionId!, () => []);
  int get cartCount => cart.fold(0, (a, b) => a + b.jumlah);
  int get cartTotal => cart.fold(0, (a, i) => a + (produkById(i.idProduk)?.harga ?? 0) * i.jumlah);

  String? tambahKeranjang(int idProduk, int qty) {
    final p = produkById(idProduk);
    if (p == null) return 'Produk tidak ditemukan.';
    final item = _find(cart, (i) => i.idProduk == idProduk);
    final baru = (item?.jumlah ?? 0) + qty;
    if (baru > p.stok) return 'Stok ${p.nama} tinggal ${p.stok}.';
    if (item != null) {
      item.jumlah = baru;
    } else {
      cart.add(CartItem(idProduk, qty));
    }
    _save();
    return null;
  }

  String? ubahJumlah(int idProduk, int delta) {
    final item = _find(cart, (i) => i.idProduk == idProduk);
    final p = produkById(idProduk);
    if (item == null || p == null) return null;
    final baru = item.jumlah + delta;
    if (baru > p.stok) return 'Stok tidak cukup.';
    if (baru < 1) {
      cart.remove(item);
    } else {
      item.jumlah = baru;
    }
    _save();
    return null;
  }

  // ---------- checkout & pembayaran ----------
  /// Mengembalikan pesan error, atau null jika pesanan berhasil dibuat.
  /// Pembayaran non-tunai disimulasikan gagal 25% agar perulangan pada
  /// Activity Diagram (Pembayaran Berhasil? -> Tidak) dapat dicoba.
  String? buatPesanan(String metode, String alamat) {
    if (cart.isEmpty) return 'Keranjang kosong.';
    if (alamat.trim().isEmpty) return 'Alamat pengiriman wajib diisi.';
    for (final i in cart) {
      final p = produkById(i.idProduk);
      if (p == null || i.jumlah > p.stok) return 'Stok berubah, periksa keranjang.';
    }
    if (metode != 'Cash' && Random().nextDouble() < 0.25) {
      return 'Pembayaran $metode gagal. Pilih metode lain atau coba bayar ulang.';
    }
    final now = DateTime.now();
    final items = <OrderItem>[];
    for (final i in cart) {
      final p = produkById(i.idProduk)!;
      p.stok -= i.jumlah;
      items.add(OrderItem(p.id, p.nama, p.harga, i.jumlah));
    }
    pesanan.add(Pesanan(
      id: _no++,
      idUser: sessionId!,
      tanggal: now,
      total: cartTotal,
      status: 0,
      alamatKirim: alamat.trim(),
      items: items,
      pembayaran: Pembayaran(metode, metode == 'Cash' ? 'Bayar di kasir' : 'Lunas', now),
    ));
    keranjang[sessionId!] = [];
    _save();
    return null;
  }

  List<Pesanan> pesananSaya({required bool selesai}) => pesanan
      .where((o) => o.idUser == sessionId && (o.status == 4) == selesai)
      .toList()
      .reversed
      .toList();

  // ---------- admin ----------
  int get pesananBaru => pesanan.where((o) => o.status == 0).length;

  void lanjutStatus(int id) {
    final o = _find(pesanan, (o) => o.id == id);
    if (o == null || o.status >= 4) return;
    o.status++;
    if (o.status == 4) o.pembayaran.status = 'Lunas';
    _save();
  }

  void ubahStok(int id, int delta) {
    final p = produkById(id);
    if (p == null) return;
    p.stok = max(0, p.stok + delta);
    _save();
  }

  void simpanProduk(Produk? lama, String nama, int harga, int stok, String kategori, String gambar, String deskripsi) {
    if (lama == null) {
      produk.add(Produk(id: _np++, nama: nama, harga: harga, stok: stok, kategori: kategori, gambar: gambar, deskripsi: deskripsi));
    } else {
      lama
        ..nama = nama
        ..harga = harga
        ..stok = stok
        ..kategori = kategori
        ..gambar = gambar
        ..deskripsi = deskripsi;
    }
    _save();
  }

  void hapusProduk(int id) {
    produk.removeWhere((p) => p.id == id);
    for (final c in keranjang.values) {
      c.removeWhere((i) => i.idProduk == id);
    }
    _save();
  }

  void hapusPelanggan(int id) {
    users.removeWhere((u) => u.id == id);
    keranjang.remove(id);
    _save();
  }

  void resetData() {
    _seed();
    _save();
  }
}
