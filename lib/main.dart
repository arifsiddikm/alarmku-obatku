import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/seeder.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Init notifikasi — kalau gagal (misal di macOS/web) lanjut aja
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  // Seeder — kalau gagal lanjut aja
  try {
    await Seeder.run();
  } catch (e) {
    debugPrint('Seeder error: $e');
  }

  runApp(const AlarmKuApp());
}

class AlarmKuApp extends StatelessWidget {
  const AlarmKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlarmKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    try {
      final loggedIn = await AuthService.instance.isLoggedIn();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Auth check error: $e');
      if (!mounted) return;
      // Kalau error, langsung ke login aja
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.terracotta,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: AppTheme.terracottaDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: AppTheme.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AlarmKu',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pengingat minum obat',
              style: TextStyle(color: AppTheme.terracottaLight, fontSize: 15),
            ),
            const SizedBox(height: 48),
            if (_errorMsg == null)
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.terracottaLight,
                ),
              )
            else
              Text(_errorMsg!,
                  style: const TextStyle(color: AppTheme.terracottaLight, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
