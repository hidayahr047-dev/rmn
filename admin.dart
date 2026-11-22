import 'package:flutter/material.dart';
import 'main.dart' show snack;
import 'models.dart';
import 'store.dart';
import 'customer.dart' show KartuPesanan;

/// Kerangka aplikasi admin: Produk & Stok, Pesanan, Pelanggan, Laporan.
class AdminShell extends StatefulWidget {
  final AppStore s;
  const AdminShell(this.s, {super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final n = s.pesananBaru;
    final pages = <Widget>[ProdukAdmin(s), PesananAdmin(s), PelangganAdmin(s), LaporanAdmin(s)];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin · Kang Maman'),
        actions: [TextButton(onPressed: s.logout, child: const Text('Keluar'))],
      ),
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Produk'),
          NavigationDestination(
            icon: Badge(label: Text('$n'), isLabelVisible: n > 0, child: const Icon(Icons.receipt_long)),
            label: 'Pesanan',
          ),
          const NavigationDestination(icon: Icon(Icons.people_outline), label: 'Pelanggan'),
          const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- Kelola Produk & Stok
class ProdukAdmin extends StatelessWidget {
  final AppStore s;
  const ProdukAdmin(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: Text('Produk & Stok', style: th.textTheme.headlineSmall)),
        FilledButton.icon(onPressed: () => _form(context, s, null), icon: const Icon(Icons.add), label: const Text('Produk')),
      ]),
      const SizedBox(height: 8),
      for (final p in s.produk)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                Text(p.gambar, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.nama, style: th.textTheme.titleSmall),
                    Text('${p.kategori} · ${rp(p.harga)}', style: th.textTheme.bodySmall),
                  ]),
                ),
                IconButton(onPressed: () => s.ubahStok(p.id, -1), icon: const Icon(Icons.remove_circle_outline)),
                Text('${p.stok}', style: TextStyle(fontWeight: FontWeight.bold, color: p.stok < 5 ? Colors.orange : null)),
                IconButton(onPressed: () => s.ubahStok(p.id, 1), icon: const Icon(Icons.add_circle_outline)),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => _form(context, s, p), child: const Text('Edit')),
                TextButton(
                  onPressed: () async {
                    final ok = await _konfirmasi(context, 'Hapus produk ${p.nama}?');
                    if (ok) s.hapusProduk(p.id);
                  },
                  child: const Text('Hapus'),
                ),
              ]),
            ]),
          ),
        ),
    ]);
  }
}

Future<bool> _konfirmasi(BuildContext context, String pesan) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(pesan),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
      ],
    ),
  );
  return r ?? false;
}

void _form(BuildContext context, AppStore s, Produk? p) {
  final nama = TextEditingController(text: p?.nama ?? '');
  final harga = TextEditingController(text: p == null ? '' : '${p.harga}');
  final stok = TextEditingController(text: p == null ? '0' : '${p.stok}');
  final kat = TextEditingController(text: p?.kategori ?? 'Bakso');
  final gbr = TextEditingController(text: p?.gambar ?? '🍜');
  final des = TextEditingController(text: p?.deskripsi ?? '');
  String err = '';
  Widget f(TextEditingController c, String l, {bool num = false, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: lines,
          keyboardType: num ? TextInputType.number : null,
          decoration: InputDecoration(labelText: l, border: const OutlineInputBorder()),
        ),
      );
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(p == null ? 'Tambah Produk' : 'Edit Produk', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            f(nama, 'Nama'),
            f(harga, 'Harga (Rp)', num: true),
            f(stok, 'Stok', num: true),
            f(kat, 'Kategori'),
            f(gbr, 'Gambar (emoji)'),
            f(des, 'Deskripsi', lines: 2),
            if (err.isNotEmpty) Text(err, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                final h = int.tryParse(harga.text) ?? 0;
                final st = int.tryParse(stok.text) ?? -1;
                if (nama.text.trim().isEmpty || h <= 0 || st < 0) {
                  set(() => err = 'Isi nama, harga lebih dari 0, dan stok 0 atau lebih.');
                  return;
                }
                s.simpanProduk(p, nama.text.trim(), h, st, kat.text.trim().isEmpty ? 'Lainnya' : kat.text.trim(), gbr.text.trim().isEmpty ? '🍜' : gbr.text.trim(), des.text.trim());
                Navigator.pop(ctx);
                snack(context, 'Produk disimpan');
              },
              child: const Text('Simpan produk'),
            ),
          ]),
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------- Kelola Pesanan
class PesananAdmin extends StatelessWidget {
  final AppStore s;
  const PesananAdmin(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final l = s.pesanan.reversed.toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Kelola Pesanan', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      if (l.isEmpty) const Text('Belum ada pesanan masuk.'),
      for (final o in l)
        KartuPesanan(
          o,
          judul: '#${o.id.toString().padLeft(3, '0')} · ${s.userById(o.idUser)?.nama ?? '(dihapus)'}',
          aksi: o.status < 4
              ? Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: () => s.lanjutStatus(o.id), child: Text(statusList[o.status + 1])),
                )
              : null,
        ),
    ]);
  }
}

// ----------------------------------------------------------- Kelola Pelanggan
class PelangganAdmin extends StatelessWidget {
  final AppStore s;
  const PelangganAdmin(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final l = s.users.where((u) => u.role == 'pelanggan').toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Pelanggan', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      if (l.isEmpty) const Text('Belum ada pelanggan.'),
      for (final u in l)
        Card(
          child: ListTile(
            title: Text(u.nama),
            subtitle: Text('${u.email} · ${u.noTelp}\n${u.alamat} · ${s.pesanan.where((o) => o.idUser == u.id).length} pesanan'),
            isThreeLine: true,
            trailing: TextButton(
              onPressed: () async {
                if (await _konfirmasi(context, 'Hapus pelanggan ${u.nama}? Riwayat pesanannya tetap tersimpan.')) s.hapusPelanggan(u.id);
              },
              child: const Text('Hapus'),
            ),
          ),
        ),
    ]);
  }
}

// ------------------------------------------------------------------- Laporan
class LaporanAdmin extends StatelessWidget {
  final AppStore s;
  const LaporanAdmin(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final rev = s.pesanan.fold<int>(0, (a, o) => a + o.total);
    final m = <String, List<int>>{}; // nama -> [porsi, pendapatan]
    for (final o in s.pesanan) {
      for (final i in o.items) {
        final x = m.putIfAbsent(i.nama, () => [0, 0]);
        x[0] += i.jumlah;
        x[1] += i.jumlah * i.harga;
      }
    }
    final keys = m.keys.toList()..sort((a, b) => m[b]![0].compareTo(m[a]![0]));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Laporan Penjualan', style: th.textTheme.headlineSmall),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Pendapatan'), Text(rp(rev), style: th.textTheme.titleLarge)])))),
        Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Pesanan'), Text('${s.pesanan.length}', style: th.textTheme.titleLarge)])))),
      ]),
      const SizedBox(height: 8),
      Text('Produk terjual', style: th.textTheme.titleMedium),
      if (keys.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Belum ada transaksi.')),
      for (final k in keys) Card(child: ListTile(title: Text(k), subtitle: Text('${m[k]![0]} porsi'), trailing: Text(rp(m[k]![1]), style: const TextStyle(fontWeight: FontWeight.bold)))),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () async {
          if (await _konfirmasi(context, 'Reset semua data ke awal?')) s.resetData();
        },
        child: const Text('Reset data demo'),
      ),
    ]);
  }
}
