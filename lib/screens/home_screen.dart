import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/medicine.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import '../widgets/add_edit_medicine_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/edit_profile_sheet.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  List<Medicine> _medicines = [];
  bool _loading = true;
  Timer? _countdownTimer;

  final _dayNames = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadData();
    await _checkPermissions();
    _startCountdownTimer();
  }

  Future<void> _loadData() async {
    final user = await AuthService.instance.getLoggedUser();
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }
    final medicines = await DatabaseService.instance.getMedicinesByUser(user.id!);
    setState(() {
      _user = user;
      _medicines = medicines;
      _loading = false;
    });
  }

  Future<void> _checkPermissions() async {
    final granted = await NotificationService.instance.checkPermission();
    if (!granted && mounted) {
      await _showPermissionDialog();
    }
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.terracottaLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_outlined, color: AppTheme.terracotta, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Izin diperlukan', style: AppText.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi ini butuh izin notifikasi agar alarm pengingat obat bisa berfungsi.',
              style: AppText.body,
            ),
            const SizedBox(height: 12),
            _PermissionRow(
              icon: Icons.notifications_outlined,
              label: 'Notifikasi',
              desc: 'Untuk kirim alarm pengingat obat',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti saja', style: TextStyle(color: AppTheme.warmGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await NotificationService.instance.requestPermission();
            },
            child: const Text('Izinkan'),
          ),
        ],
      ),
    );
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _logout() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Keluar akun',
      message: 'Kamu yakin mau logout? Semua alarm lokal akan tetap tersimpan.',
      confirmText: 'Ya, logout',
      cancelText: 'Batal',
    );
    if (confirm) {
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _deleteMedicine(Medicine m) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Hapus alarm',
      message: 'Alarm "${m.name}" akan dihapus permanen.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDanger: true,
    );
    if (confirm) {
      await NotificationService.instance.cancelForMedicine(m);
      await DatabaseService.instance.deleteMedicine(m.id!);
      await _loadData();
      if (mounted) showSnackBar(context, 'Alarm dihapus');
    }
  }

  Future<void> _toggleMedicine(Medicine m) async {
    final newState = !m.isActive;
    await DatabaseService.instance.toggleMedicineActive(m.id!, newState);
    final updated = m.copyWith(isActive: newState);
    if (newState) {
      await NotificationService.instance.scheduleForMedicine(updated);
    } else {
      await NotificationService.instance.cancelForMedicine(updated);
    }
    await _loadData();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditMedicineSheet(
        userId: _user!.id!,
        onSaved: _loadData,
      ),
    );
  }

  void _openEditSheet(Medicine m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditMedicineSheet(
        userId: _user!.id!,
        medicine: m,
        onSaved: _loadData,
      ),
    );
  }

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        user: _user!,
        onSaved: _loadData,
      ),
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.cream,
        body: Center(child: CircularProgressIndicator(color: AppTheme.terracotta)),
      );
    }

    final active = _medicines.where((m) => m.isActive).length;
    final total = _medicines.length;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: RefreshIndicator(
        color: AppTheme.terracotta,
        backgroundColor: AppTheme.white,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              backgroundColor: AppTheme.cream,
              floating: true,
              snap: true,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta, borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication_rounded, color: AppTheme.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('AlarmKu', style: AppText.h3.copyWith(color: AppTheme.terracotta)),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.warmGray, size: 22),
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // Profile card
                  GestureDetector(
                    onTap: _openEditProfile,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.terracottaDark,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _user!.initials,
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()},',
                                  style: const TextStyle(
                                    color: AppTheme.terracottaLight,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  _user!.firstName,
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_user?.phone != null)
                                  Text(
                                    _user!.phone!,
                                    style: const TextStyle(
                                      color: AppTheme.terracottaLight,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$active aktif',
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'dari $total alarm',
                                style: const TextStyle(
                                  color: AppTheme.terracottaLight,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.terracottaDark.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Edit profil',
                                  style: TextStyle(color: AppTheme.white, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol tambah alarm
                  Row(
                    children: [
                      Text('Alarm obat', style: AppText.h3),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openAddSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.terracotta,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: AppTheme.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Tambah',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // List alarm atau empty state
                  if (_medicines.isEmpty)
                    _EmptyState(onAdd: _openAddSheet)
                  else
                    ..._medicines.map((m) => _MedicineCard(
                      medicine: m,
                      dayNames: _dayNames,
                      countdown: NotificationService.instance.countdownText(m),
                      onToggle: () => _toggleMedicine(m),
                      onEdit: () => _openEditSheet(m),
                      onDelete: () => _deleteMedicine(m),
                    )),
                ]),
              ),
            ),
          ],
        ),
      ),

      // FAB tambah alarm
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.terracotta,
        foregroundColor: AppTheme.white,
        elevation: 2,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ===== Widget komponen =====

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  const _PermissionRow({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.sageLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.sage, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.label),
              Text(desc, style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warmGrayLight.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppTheme.creamDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.medication_outlined, color: AppTheme.warmGray, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Belum ada alarm obat', style: AppText.h3.copyWith(color: AppTheme.warmGray)),
          const SizedBox(height: 6),
          Text(
            'Tambah alarm pertamamu dan jangan\nsampai lupa minum obat!',
            style: AppText.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah alarm pertama'),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final List<String> dayNames;
  final String? countdown;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicineCard({
    required this.medicine,
    required this.dayNames,
    required this.countdown,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final m = medicine;
    final isActive = m.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppTheme.terracottaLight.withOpacity(0.3)
              : AppTheme.warmGrayLight.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.terracottaLight.withOpacity(0.15)
                        : AppTheme.creamDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: isActive ? AppTheme.terracotta : AppTheme.warmGray,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: AppText.h3.copyWith(
                          color: isActive ? AppTheme.warmBrown : AppTheme.warmGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(m.dosage, style: AppText.caption),
                      if (m.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(m.notes, style: AppText.caption.copyWith(
                          color: AppTheme.warmGray.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        )),
                      ],
                    ],
                  ),
                ),

                // Toggle
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 26,
                    padding: EdgeInsets.only(left: isActive ? 20 : 2),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.terracotta : AppTheme.warmGrayLight,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                        color: AppTheme.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom info
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
            decoration: BoxDecoration(
              color: AppTheme.creamDark.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Jam
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 14,
                        color: isActive ? AppTheme.terracotta : AppTheme.warmGray),
                    const SizedBox(width: 4),
                    Text(
                      m.time,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppTheme.terracotta : AppTheme.warmGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // Hari / sekali
                Expanded(
                  child: m.isRepeat && m.days.isNotEmpty
                      ? Wrap(
                          spacing: 4,
                          children: m.days.map((d) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.terracottaLight.withOpacity(0.2)
                                  : AppTheme.warmGrayLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dayNames[d],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? AppTheme.terracottaDark : AppTheme.warmGray,
                              ),
                            ),
                          )).toList(),
                        )
                      : Text(
                          m.isRepeat ? 'Setiap hari' : 'Sekali',
                          style: AppText.caption.copyWith(
                            color: isActive ? AppTheme.terracottaDark : AppTheme.warmGray,
                          ),
                        ),
                ),

                // Countdown
                if (isActive && countdown != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.sage.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      countdown!,
                      style: const TextStyle(
                        color: AppTheme.sageDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(width: 6),

                // Aksi edit & hapus
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.warmGray),
                  color: AppTheme.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: AppTheme.warmBrown),
                          SizedBox(width: 10),
                          Text('Edit alarm', style: AppText.body),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                          SizedBox(width: 10),
                          Text('Hapus', style: TextStyle(color: AppTheme.error, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
