import 'package:flutter/material.dart';
import 'main.dart' show snack;
import 'models.dart';
import 'store.dart';

/// Kerangka aplikasi pelanggan: Menu, Keranjang, Pesanan, Profil.
class CustomerShell extends StatefulWidget {
  final AppStore s;
  const CustomerShell(this.s, {super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final n = s.cartCount;
    final pages = <Widget>[
      MenuPage(s),
      KeranjangPage(s, (i) => setState(() => idx = i)),
      PesananPage(s),
      ProfilPage(s),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Bakso Kang Maman')),
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(
            icon: Badge(label: Text('$n'), isLabelVisible: n > 0, child: const Icon(Icons.shopping_cart_outlined)),
            label: 'Keranjang',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Pesanan'),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Menu Utama
class MenuPage extends StatelessWidget {
  final AppStore s;
  const MenuPage(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Halo, ${s.user!.nama.split(' ').first}', style: t.headlineSmall),
        const SizedBox(height: 4),
        const Text('Mau makan apa hari ini?'),
        const SizedBox(height: 16),
        Text('Menu Favorit', style: t.titleMedium),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.7,
          children: [for (final p in s.produk) _KartuProduk(s, p)],
        ),
      ],
    );
  }
}

class _KartuProduk extends StatelessWidget {
  final AppStore s;
  final Produk p;
  const _KartuProduk(this.s, this.p);

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _detail(context, s, p),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Center(child: Text(p.gambar, style: const TextStyle(fontSize: 48)))),
              Text(p.nama, style: th.textTheme.titleSmall),
              Text(rp(p.harga), style: TextStyle(fontWeight: FontWeight.bold, color: th.colorScheme.primary)),
              Text(p.stok > 0 ? 'Stok ${p.stok}' : 'Habis', style: th.textTheme.bodySmall),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: p.stok > 0 ? () => snack(context, s.tambahKeranjang(p.id, 1) ?? '${p.nama} masuk keranjang') : null,
                  child: const Text('+ Keranjang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Melihat Detail Produk (use case 4) + Memesan Produk (use case 5).
void _detail(BuildContext context, AppStore s, Produk p) {
  int q = 1;
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(p.gambar, style: const TextStyle(fontSize: 64))),
            Text(p.nama, style: Theme.of(ctx).textTheme.headlineSmall),
            Text(rp(p.harga), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary)),
            const SizedBox(height: 8),
            Text(p.deskripsi),
            const SizedBox(height: 4),
            Text('Kategori ${p.kategori} · stok ${p.stok}', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (p.stok > 0)
              Row(children: [
                IconButton.outlined(onPressed: q > 1 ? () => set(() => q--) : null, icon: const Icon(Icons.remove)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$q', style: Theme.of(ctx).textTheme.titleMedium)),
                IconButton.outlined(onPressed: q < p.stok ? () => set(() => q++) : null, icon: const Icon(Icons.add)),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final e = s.tambahKeranjang(p.id, q);
                      Navigator.pop(ctx);
                      snack(context, e ?? '${p.nama} masuk keranjang');
                    },
                    child: const Text('Masukkan ke keranjang'),
                  ),
                ),
              ])
            else
              const SizedBox(width: double.infinity, child: FilledButton(onPressed: null, child: Text('Stok habis'))),
          ],
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------------ Keranjang
class KeranjangPage extends StatelessWidget {
  final AppStore s;
  final void Function(int) goto;
  const KeranjangPage(this.s, this.goto, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = s.cart;
    if (c.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Keranjang masih kosong.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => goto(0), child: const Text('Pilih menu')),
        ]),
      );
    }
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          for (final i in c)
            if (s.produkById(i.idProduk) != null)
              Card(
                child: ListTile(
                  leading: Text(s.produkById(i.idProduk)!.gambar, style: const TextStyle(fontSize: 30)),
                  title: Text(s.produkById(i.idProduk)!.nama),
                  subtitle: Text('${rp(s.produkById(i.idProduk)!.harga)} · subtotal ${rp(s.produkById(i.idProduk)!.harga * i.jumlah)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => s.ubahJumlah(i.idProduk, -1), icon: const Icon(Icons.remove_circle_outline)),
                    Text('${i.jumlah}'),
                    IconButton(
                      onPressed: () {
                        final e = s.ubahJumlah(i.idProduk, 1);
                        if (e != null) snack(context, e);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ]),
                ),
              ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            Text(rp(s.cartTotal), style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PembayaranPage(s, () => goto(2)))),
              child: const Text('Checkout'),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ----------------------------------------------------------------- Pembayaran
class PembayaranPage extends StatefulWidget {
  final AppStore s;
  final VoidCallback onSukses;
  const PembayaranPage(this.s, this.onSukses, {super.key});
  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  late final TextEditingController alamat = TextEditingController(text: widget.s.user!.alamat);
  String metode = metodeList.first;
  String err = '';

  void buat() {
    final e = widget.s.buatPesanan(metode, alamat.text);
    if (e != null) {
      setState(() => err = e); // gagal: pelanggan boleh pilih metode lain / bayar ulang
      return;
    }
    Navigator.pop(context);
    widget.onSukses();
    snack(context, 'Pesanan dibuat');
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Jumlah Pesanan'),
              Text(rp(widget.s.cartTotal), style: th.textTheme.headlineMedium?.copyWith(color: th.colorScheme.primary)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: alamat,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Alamat pengiriman', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Text('Metode pembayaran', style: th.textTheme.titleSmall),
        for (final m in metodeList)
          // ignore: deprecated_member_use
          RadioListTile<String>(
            value: m,
            // ignore: deprecated_member_use
            groupValue: metode,
            // ignore: deprecated_member_use
            onChanged: (v) => setState(() => metode = v ?? metode),
            title: Text(m),
          ),
        if (err.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(err, style: TextStyle(color: th.colorScheme.error))),
        const SizedBox(height: 8),
        FilledButton(onPressed: buat, child: const Text('Buat Pesanan')),
      ]),
    );
  }
}

// -------------------------------------------------------------- Status Pesanan
class Tahap extends StatelessWidget {
  final int status;
  const Tahap(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      for (int i = 0; i < statusList.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Icon(
              (i < status || status == 4) ? Icons.check_circle : (i == status ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              color: (i < status || status == 4) ? Colors.green : (i == status ? cs.primary : cs.outline),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(statusList[i], style: TextStyle(fontWeight: i == status && status < 4 ? FontWeight.bold : FontWeight.normal)),
          ]),
        ),
    ]);
  }
}

class KartuPesanan extends StatelessWidget {
  final Pesanan o;
  final bool tahap;
  final Widget? aksi;
  final String? judul;
  const KartuPesanan(this.o, {super.key, this.tahap = false, this.aksi, this.judul});
  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(judul ?? 'Order #${o.id.toString().padLeft(3, '0')}', style: th.textTheme.titleSmall)),
            Text(rp(o.total), style: TextStyle(fontWeight: FontWeight.bold, color: th.colorScheme.primary)),
          ]),
          Text('${tgl(o.tanggal)} · ${o.pembayaran.metode} · ${o.pembayaran.status}', style: th.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(o.items.map((i) => '${i.jumlah}× ${i.nama}').join(', ')),
          const SizedBox(height: 8),
          if (tahap) Tahap(o.status) else Chip(label: Text(statusList[o.status])),
          if (aksi != null) aksi!,
        ]),
      ),
    );
  }
}

class PesananPage extends StatelessWidget {
  final AppStore s;
  const PesananPage(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final l = s.pesananSaya(selesai: false);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Pesanan Saya', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      if (l.isEmpty) const Text('Belum ada pesanan aktif.'),
      for (final o in l) KartuPesanan(o, tahap: true),
    ]);
  }
}

// --------------------------------------------------------------------- Profil
class ProfilPage extends StatelessWidget {
  final AppStore s;
  const ProfilPage(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final u = s.user!;
    final th = Theme.of(context);
    void buka(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(
        child: CircleAvatar(
          radius: 38,
          backgroundColor: th.colorScheme.primary,
          child: Text(u.nama[0].toUpperCase(), style: TextStyle(fontSize: 30, color: th.colorScheme.onPrimary)),
        ),
      ),
      const SizedBox(height: 8),
      Text(u.nama, textAlign: TextAlign.center, style: th.textTheme.titleLarge),
      Text(u.email, textAlign: TextAlign.center, style: th.textTheme.bodySmall),
      const SizedBox(height: 16),
      Card(child: ListTile(title: const Text('Edit Profile'), trailing: const Icon(Icons.chevron_right), onTap: () => buka(EditProfilPage(s)))),
      Card(child: ListTile(title: const Text('Riwayat Pesanan'), trailing: const Icon(Icons.chevron_right), onTap: () => buka(RiwayatPage(s)))),
      Card(child: ListTile(title: const Text('Bantuan'), trailing: const Icon(Icons.chevron_right), onTap: () => buka(const BantuanPage()))),
      Card(child: ListTile(title: Text('Logout', style: TextStyle(color: th.colorScheme.error)), onTap: s.logout)),
    ]);
  }
}

class EditProfilPage extends StatefulWidget {
  final AppStore s;
  const EditProfilPage(this.s, {super.key});
  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late final nama = TextEditingController(text: widget.s.user!.nama);
  late final email = TextEditingController(text: widget.s.user!.email);
  late final telp = TextEditingController(text: widget.s.user!.noTelp);
  late final alamat = TextEditingController(text: widget.s.user!.alamat);
  final pass = TextEditingController();
  String err = '';

  Widget _f(TextEditingController c, String l, {bool obs = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, obscureText: obs, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _f(nama, 'Nama'),
        _f(email, 'Email'),
        _f(telp, 'No. telepon'),
        _f(alamat, 'Alamat'),
        _f(pass, 'Password baru (kosongkan jika tidak diganti)', obs: true),
        if (err.isNotEmpty) Text(err, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            final e = widget.s.ubahProfil(nama.text, email.text, telp.text, alamat.text, pass.text);
            if (e != null) {
              setState(() => err = e);
            } else {
              Navigator.pop(context);
              snack(context, 'Profil disimpan');
            }
          },
          child: const Text('Simpan perubahan'),
        ),
      ]),
    );
  }
}

class RiwayatPage extends StatelessWidget {
  final AppStore s;
  const RiwayatPage(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final l = s.pesananSaya(selesai: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (l.isEmpty) const Text('Belum ada pesanan yang selesai.'),
        for (final o in l) KartuPesanan(o),
      ]),
    );
  }
}

class BantuanPage extends StatelessWidget {
  const BantuanPage({super.key});
  @override
  Widget build(BuildContext context) {
    Widget k(String j, String i) => Card(child: ListTile(title: Text(j), subtitle: Text(i)));
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        k('Cara memesan', 'Pilih menu, masukkan ke keranjang, checkout, pilih metode pembayaran, lalu pantau tahap pesanan di tab Pesanan.'),
        k('Pembayaran gagal?', 'Pilih metode lain atau coba bayar ulang. Isi keranjang tidak hilang.'),
        k('Hubungi kami', 'Telepon 081200000000 setiap hari, 10.00–21.00.'),
      ]),
    );
  }
}
