import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import 'confirm_dialog.dart';

class EditProfileSheet extends StatefulWidget {
  final User user;
  final VoidCallback onSaved;

  const EditProfileSheet({super.key, required this.user, required this.onSaved});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = User(
      id: widget.user.id,
      name: _nameCtrl.text.trim(),
      email: widget.user.email,
      passwordHash: widget.user.passwordHash,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      createdAt: widget.user.createdAt,
    );

    await DatabaseService.instance.updateUser(updated);

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
      showSnackBar(context, 'Profil berhasil diperbarui');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.warmGrayLight, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Profil', style: AppText.h2),
            const SizedBox(height: 8),
            Text(widget.user.email, style: AppText.bodyMuted),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v!.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'No. HP (opsional)',
                hintText: '08xxxxxxxxxx',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                      )
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
