// Kelas data sesuai Class Diagram (Gambar 3.4):
// User, Produk, Keranjang (CartItem), Pesanan, Pembayaran.

const statusList = [
  'Pesanan Dibuat',
  'Dikonfirmasi',
  'Sedang Diproses',
  'Siap Diambil',
  'Selesai',
];

const metodeList = ['Cash', 'QRIS', 'Bank Transfer', 'E-Wallet'];

String rp(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp$b';
}

String tgl(DateTime d) =>
    '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class User {
  int id;
  String nama, email, password, alamat, noTelp, role; // role: pelanggan | admin
  User({
    required this.id,
    required this.nama,
    required this.email,
    required this.password,
    required this.alamat,
    required this.noTelp,
    required this.role,
  });
  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        nama: j['nama'],
        email: j['email'],
        password: j['password'],
        alamat: j['alamat'],
        noTelp: j['no_telp'],
        role: j['role'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'password': password,
        'alamat': alamat,
        'no_telp': noTelp,
        'role': role,
      };
}

class Produk {
  int id;
  String nama;
  int harga;
  int stok;
  String kategori;
  String gambar; // emoji
  String deskripsi;
  Produk({
    required this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    required this.kategori,
    required this.gambar,
    required this.deskripsi,
  });
  factory Produk.fromJson(Map<String, dynamic> j) => Produk(
        id: j['id'],
        nama: j['nama'],
        harga: j['harga'],
        stok: j['stok'],
        kategori: j['kategori'],
        gambar: j['gambar'],
        deskripsi: j['deskripsi'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'harga': harga,
        'stok': stok,
        'kategori': kategori,
        'gambar': gambar,
        'deskripsi': deskripsi,
      };
}

class CartItem {
  int idProduk;
  int jumlah;
  CartItem(this.idProduk, this.jumlah);
  factory CartItem.fromJson(Map<String, dynamic> j) =>
      CartItem(j['id_produk'], j['jumlah']);
  Map<String, dynamic> toJson() => {'id_produk': idProduk, 'jumlah': jumlah};
}

class OrderItem {
  int idProduk;
  String nama;
  int harga;
  int jumlah;
  OrderItem(this.idProduk, this.nama, this.harga, this.jumlah);
  factory OrderItem.fromJson(Map<String, dynamic> j) =>
      OrderItem(j['id_produk'], j['nama'], j['harga'], j['jumlah']);
  Map<String, dynamic> toJson() =>
      {'id_produk': idProduk, 'nama': nama, 'harga': harga, 'jumlah': jumlah};
}

class Pembayaran {
  String metode;
  String status; // Lunas | Bayar di kasir
  DateTime tanggal;
  Pembayaran(this.metode, this.status, this.tanggal);
  factory Pembayaran.fromJson(Map<String, dynamic> j) =>
      Pembayaran(j['metode'], j['status'], DateTime.parse(j['tanggal']));
  Map<String, dynamic> toJson() => {
        'metode': metode,
        'status': status,
        'tanggal': tanggal.toIso8601String(),
      };
}

class Pesanan {
  int id;
  int idUser;
  DateTime tanggal;
  int total;
  int status; // indeks pada statusList
  String alamatKirim;
  List<OrderItem> items;
  Pembayaran pembayaran;
  Pesanan({
    required this.id,
    required this.idUser,
    required this.tanggal,
    required this.total,
    required this.status,
    required this.alamatKirim,
    required this.items,
    required this.pembayaran,
  });
  factory Pesanan.fromJson(Map<String, dynamic> j) => Pesanan(
        id: j['id'],
        idUser: j['id_user'],
        tanggal: DateTime.parse(j['tanggal']),
        total: j['total'],
        status: j['status'],
        alamatKirim: j['alamat_kirim'],
        items: (j['items'] as List)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        pembayaran:
            Pembayaran.fromJson(j['pembayaran'] as Map<String, dynamic>),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'id_user': idUser,
        'tanggal': tanggal.toIso8601String(),
        'total': total,
        'status': status,
        'alamat_kirim': alamatKirim,
        'items': items.map((e) => e.toJson()).toList(),
        'pembayaran': pembayaran.toJson(),
      };
}
