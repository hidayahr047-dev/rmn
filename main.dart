import 'package:flutter/material.dart';
import 'store.dart';
import 'customer.dart';
import 'admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.init();
  runApp(BaksoApp(store));
}

void snack(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

class BaksoApp extends StatelessWidget {
  final AppStore store;
  const BaksoApp(this.store, {super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFC8202F);
    return MaterialApp(
      title: 'Bakso Kang Maman',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      themeMode: ThemeMode.system,
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final u = store.user;
          if (u == null) return AuthPage(store);
          return u.role == 'admin' ? AdminShell(store) : CustomerShell(store);
        },
      ),
    );
  }
}

/// Menu Login (3.6.1) + pendaftaran akun baru.
class AuthPage extends StatefulWidget {
  final AppStore s;
  const AuthPage(this.s, {super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool daftar = false;
  String err = '';
  final nama = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final alamat = TextEditingController();
  final telp = TextEditingController();

  void kirim() {
    final s = widget.s;
    final e = daftar
        ? s.daftar(nama.text, email.text, pass.text, alamat.text, telp.text)
        : s.login(email.text, pass.text);
    setState(() => err = e ?? '');
  }

  Widget _f(TextEditingController c, String label, {bool obs = false, TextInputType? t}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          obscureText: obs,
          keyboardType: t,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('🍜', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
                  Text('Bakso Kang Maman', textAlign: TextAlign.center, style: th.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Pesan bakso dan mie ayam tanpa antre', textAlign: TextAlign.center, style: th.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  if (daftar) _f(nama, 'Nama'),
                  _f(email, daftar ? 'Email' : 'Username / Email', t: TextInputType.emailAddress),
                  _f(pass, 'Password', obs: true),
                  if (daftar) ...[
                    _f(alamat, 'Alamat'),
                    _f(telp, 'No. telepon', t: TextInputType.phone),
                  ],
                  if (err.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(err, style: TextStyle(color: th.colorScheme.error)),
                    ),
                  FilledButton(onPressed: kirim, child: Text(daftar ? 'Daftar' : 'Masuk')),
                  TextButton(
                    onPressed: () => setState(() {
                      daftar = !daftar;
                      err = '';
                    }),
                    child: Text(daftar ? 'Sudah punya akun? Masuk' : 'Belum Punya Akun? Daftar'),
                  ),
                  if (!daftar)
                    Text(
                      'Demo pelanggan: rahman@mail.com / 123456\nDemo admin: admin@kangmaman.id / admin123',
                      textAlign: TextAlign.center,
                      style: th.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
