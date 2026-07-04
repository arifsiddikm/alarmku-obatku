import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';
import 'confirm_dialog.dart';

class AddEditMedicineSheet extends StatefulWidget {
  final int userId;
  final Medicine? medicine;
  final VoidCallback onSaved;

  const AddEditMedicineSheet({
    super.key,
    required this.userId,
    this.medicine,
    required this.onSaved,
  });

  @override
  State<AddEditMedicineSheet> createState() => _AddEditMedicineSheetState();
}

class _AddEditMedicineSheetState extends State<AddEditMedicineSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _dosageCtrl;
  late TextEditingController _notesCtrl;
  TimeOfDay _time = TimeOfDay.now();
  List<int> _days = [1, 2, 3, 4, 5, 6, 7];
  bool _isRepeat = true;
  String _soundKey = 'default';
  bool _saving = false;
  bool _previewPlaying = false;
  final _player = AudioPlayer();

  bool get isEdit => widget.medicine != null;
  final _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _dosageCtrl = TextEditingController(text: m?.dosage ?? '');
    _notesCtrl = TextEditingController(text: m?.notes ?? '');
    if (m != null) {
      final parts = m.time.split(':');
      _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      _days = List.from(m.days);
      _isRepeat = m.isRepeat;
      _soundKey = m.soundKey;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  String get _timeStr =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      initialEntryMode: TimePickerEntryMode.inputOnly, // langsung ketik, lebih jelas
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: true, // paksa 24 jam
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.terracotta),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _previewSound(String key) async {
    setState(() {
      _soundKey = key;
      _previewPlaying = true;
    });
    try {
      await _player.stop();
      if (!kIsWeb && key != 'default') {
        await _player.play(AssetSource('sounds/$key.mp3'));
        await Future.delayed(const Duration(seconds: 2));
        await _player.stop();
      }
    } catch (e) {
      debugPrint('[AlarmKu] Preview error: $e');
    } finally {
      if (mounted) setState(() => _previewPlaying = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRepeat && _days.isEmpty) {
      showSnackBar(context, 'Pilih minimal 1 hari', isError: true);
      return;
    }
    setState(() => _saving = true);

    final medicine = Medicine(
      id: widget.medicine?.id,
      userId: widget.userId,
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      time: _timeStr,
      days: _isRepeat ? (_days..sort()) : [],
      isRepeat: _isRepeat,
      isActive: widget.medicine?.isActive ?? true,
      soundKey: _soundKey,
      createdAt: widget.medicine?.createdAt ?? DateTime.now(),
    );

    Medicine saved;
    if (isEdit) {
      await DatabaseService.instance.updateMedicine(medicine);
      saved = medicine;
    } else {
      saved = await DatabaseService.instance.insertMedicine(medicine);
    }

    await NotificationService.instance.scheduleForMedicine(saved);

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
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
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.warmGrayLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(isEdit ? 'Edit Alarm' : 'Tambah Alarm', style: AppText.h2),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama obat',
                  hintText: 'cth: Paracetamol, Vitamin C',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Nama obat wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosis',
                  hintText: 'cth: 1 tablet, 5ml, 2 kapsul',
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Dosis wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'cth: Setelah makan, hindari susu',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    border: Border.all(color: AppTheme.warmGrayLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppTheme.terracotta, size: 20),
                      const SizedBox(width: 10),
                      Text('Jam minum', style: AppText.bodyMuted),
                      const Spacer(),
                      Text(_timeStr,
                          style: AppText.h3
                              .copyWith(color: AppTheme.terracotta)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Text('Mode pengingat', style: AppText.label),
                  const Spacer(),
                  _ModeChip(
                    label: 'Sekali',
                    selected: !_isRepeat,
                    onTap: () => setState(() {
                      _isRepeat = false;
                      _days = [];
                    }),
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: 'Berulang',
                    selected: _isRepeat,
                    onTap: () => setState(() {
                      _isRepeat = true;
                      if (_days.isEmpty) _days = [1, 2, 3, 4, 5, 6, 7];
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isRepeat) ...[
                Text('Hari pengingat', style: AppText.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final selected = _days.contains(day);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _days.remove(day);
                        } else {
                          _days.add(day);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.terracotta
                              : AppTheme.creamDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppTheme.white
                                : AppTheme.warmGray,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],

              // Nada dering
              Row(
                children: [
                  Text('Nada dering', style: AppText.label),
                  if (_previewPlaying) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.terracotta),
                    ),
                    Text('  memutar...',
                        style: AppText.caption
                            .copyWith(color: AppTheme.terracotta)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: AlarmSound.all.map((s) {
                    final sel = _soundKey == s.key;
                    return GestureDetector(
                      onTap: () => _previewSound(s.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.terracotta
                              : AppTheme.creamDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sel) ...[
                              Icon(
                                _previewPlaying
                                    ? Icons.volume_up_rounded
                                    : Icons.music_note_rounded,
                                size: 13,
                                color: AppTheme.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              s.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: sel
                                    ? AppTheme.white
                                    : AppTheme.warmGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.white),
                        )
                      : Text(isEdit ? 'Simpan perubahan' : 'Tambah alarm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.terracotta : AppTheme.creamDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppTheme.white : AppTheme.warmGray,
          ),
        ),
      ),
    );
  }
}
