class Medicine {
  int? id;
  int userId;
  String name;
  String dosage;
  String notes;
  String time; // "HH:mm"
  List<int> days; // 1=Sen..7=Min, kosong = sekali
  bool isRepeat; // true = repeat per hari, false = sekali
  bool isActive;
  String soundKey; // key dari AlarmSound
  DateTime? createdAt;

  Medicine({
    this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    this.notes = '',
    required this.time,
    required this.days,
    this.isRepeat = true,
    this.isActive = true,
    this.soundKey = 'default',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'notes': notes,
      'time': time,
      'days': days.join(','),
      'is_repeat': isRepeat ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'sound_key': soundKey,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      dosage: map['dosage'],
      notes: map['notes'] ?? '',
      time: map['time'],
      days: map['days'] != null && map['days'].toString().isNotEmpty
          ? map['days'].toString().split(',').map((e) => int.parse(e)).toList()
          : [],
      isRepeat: map['is_repeat'] == 1,
      isActive: map['is_active'] == 1,
      soundKey: map['sound_key'] ?? 'default',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Medicine copyWith({
    int? id,
    int? userId,
    String? name,
    String? dosage,
    String? notes,
    String? time,
    List<int>? days,
    bool? isRepeat,
    bool? isActive,
    String? soundKey,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      time: time ?? this.time,
      days: days ?? List.from(this.days),
      isRepeat: isRepeat ?? this.isRepeat,
      isActive: isActive ?? this.isActive,
      soundKey: soundKey ?? this.soundKey,
      createdAt: createdAt,
    );
  }
}

class User {
  int? id;
  String name;
  String email;
  String passwordHash;
  String? phone;
  String? avatar; // initials fallback
  DateTime? createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.phone,
    this.avatar,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'phone': phone,
      'avatar': avatar,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      passwordHash: map['password_hash'],
      phone: map['phone'],
      avatar: map['avatar'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get firstName => name.trim().split(' ').first;
}

class AlarmSound {
  final String key;
  final String label;
  final String? assetPath;

  const AlarmSound({required this.key, required this.label, this.assetPath});

  static const List<AlarmSound> all = [
    AlarmSound(key: 'default', label: 'Default', assetPath: null),
    AlarmSound(key: 'gentle', label: 'Lembut', assetPath: 'assets/sounds/gentle.mp3'),
    AlarmSound(key: 'urgent', label: 'Urgent', assetPath: 'assets/sounds/urgent.mp3'),
    AlarmSound(key: 'classic', label: 'Klasik', assetPath: 'assets/sounds/classic.mp3'),
    AlarmSound(key: 'digital', label: 'Digital', assetPath: 'assets/sounds/digital.mp3'),
  ];

  static AlarmSound findByKey(String key) {
    return all.firstWhere((s) => s.key == key, orElse: () => all.first);
  }
}
