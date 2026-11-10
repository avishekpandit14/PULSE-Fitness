import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../domain/models/checkin_model.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/workout_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pulse_fitness.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE daily_summaries ADD COLUMN source TEXT NOT NULL DEFAULT 'local'",
      );
      await db.execute(
        "ALTER TABLE daily_summaries ADD COLUMN data_quality TEXT NOT NULL DEFAULT 'measured'",
      );
    }
    if (oldVersion < 3) {
      // Nightly average heart rate, used as the personal nighttime HR baseline.
      // Kept separate from rhr_history so a nighttime average is never confused
      // with a resting heart rate reading.
      await db.execute(
        'ALTER TABLE daily_summaries ADD COLUMN night_hr_avg REAL',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // User Profile
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        age INTEGER,
        height_cm REAL,
        weight_kg REAL,
        sleep_target_hours REAL,
        configured_max_hr INTEGER,
        training_frequency_days INTEGER,
        is_demo_mode INTEGER,
        onboarding_completed INTEGER
      )
    ''');

    // Daily Check-ins
    await db.execute('''
      CREATE TABLE daily_checkins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key TEXT UNIQUE,
        energy INTEGER,
        muscle_soreness INTEGER,
        fatigue INTEGER,
        notes TEXT,
        timestamp TEXT
      )
    ''');

    // Workouts (Automatic & Manual)
    await db.execute('''
      CREATE TABLE workouts (
        id TEXT PRIMARY KEY,
        title TEXT,
        type TEXT,
        start_time TEXT,
        duration_minutes INTEGER,
        avg_hr INTEGER,
        max_hr INTEGER,
        calories INTEGER,
        rpe INTEGER,
        is_manual INTEGER,
        hr_zones TEXT,
        notes TEXT
      )
    ''');

    // Resting Heart Rate History
    await db.execute('''
      CREATE TABLE rhr_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key TEXT UNIQUE,
        rhr_value REAL,
        source TEXT,
        timestamp TEXT
      )
    ''');

    // Daily Summary Cache
    await db.execute('''
      CREATE TABLE daily_summaries (
        date_key TEXT PRIMARY KEY,
        recovery_score INTEGER,
        strain_score REAL,
        sleep_minutes INTEGER,
        steps INTEGER,
        active_calories INTEGER,
        updated_at TEXT,
        source TEXT NOT NULL DEFAULT 'local',
        data_quality TEXT NOT NULL DEFAULT 'measured',
        night_hr_avg REAL
      )
    ''');
  }

  // User Profile
  Future<UserProfile> getUserProfile() async {
    final db = await database;
    final maps = await db.query('user_profile', limit: 1);
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    const defaultProfile = UserProfile();
    await saveUserProfile(defaultProfile);
    return defaultProfile;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.delete('user_profile');
    await db.insert('user_profile', profile.toMap());
  }

  // Check-ins
  Future<CheckInModel?> getCheckInForDate(String dateKey) async {
    final db = await database;
    final maps = await db.query(
      'daily_checkins',
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    if (maps.isNotEmpty) {
      return CheckInModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveCheckIn(CheckInModel checkIn) async {
    final db = await database;
    await db.insert(
      'daily_checkins',
      checkIn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CheckInModel>> getAllCheckIns({int limit = 30}) async {
    final db = await database;
    final maps = await db.query(
      'daily_checkins',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => CheckInModel.fromMap(m)).toList();
  }

  // Workouts
  Future<void> saveWorkout(WorkoutModel workout) async {
    final db = await database;
    await db.insert(
      'workouts',
      workout.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WorkoutModel>> getWorkoutsForDay(DateTime day) async {
    final db = await database;
    final datePrefix =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'workouts',
      where: "start_time LIKE ?",
      whereArgs: ['$datePrefix%'],
      orderBy: 'start_time DESC',
    );
    return maps.map((m) => WorkoutModel.fromMap(m)).toList();
  }

  Future<List<WorkoutModel>> getAllWorkouts({int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'workouts',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return maps.map((m) => WorkoutModel.fromMap(m)).toList();
  }

  Future<void> deleteWorkout(String id) async {
    final db = await database;
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  // RHR History
  Future<void> recordRhr({
    required String dateKey,
    required double rhr,
    required String source,
  }) async {
    final db = await database;
    await db.insert('rhr_history', {
      'date_key': dateKey,
      'rhr_value': rhr,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<double>> getHistoricalRhrs({int limit = 14}) async {
    final db = await database;
    final maps = await db.query(
      'rhr_history',
      columns: ['rhr_value'],
      orderBy: 'date_key DESC',
      limit: limit,
    );
    return maps.reversed
        .map((m) => (m['rhr_value'] as num).toDouble())
        .toList();
  }

  Future<void> saveDailySummary({
    required String dateKey,
    required int? recoveryScore,
    required double? strainScore,
    required int? sleepMinutes,
    required int? steps,
    required int? activeCalories,
    required String source,
    required String dataQuality,
    double? nightHrAvg,
  }) async {
    final db = await database;
    await db.insert('daily_summaries', {
      'date_key': dateKey,
      'recovery_score': recoveryScore,
      'strain_score': strainScore,
      'sleep_minutes': sleepMinutes,
      'steps': steps,
      'active_calories': activeCalories,
      'updated_at': DateTime.now().toIso8601String(),
      'source': source,
      'data_quality': dataQuality,
      'night_hr_avg': nightHrAvg,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Historical nightly average heart rates (oldest first), excluding the day
  /// being computed so a night never contributes to its own baseline.
  Future<List<double>> getHistoricalNightlyHrAverages({
    int limit = 14,
    String? excludeDateKey,
  }) async {
    final db = await database;
    final maps = await db.query(
      'daily_summaries',
      columns: ['night_hr_avg'],
      where: excludeDateKey == null
          ? 'night_hr_avg IS NOT NULL'
          : 'night_hr_avg IS NOT NULL AND date_key != ?',
      whereArgs: excludeDateKey == null ? null : [excludeDateKey],
      orderBy: 'date_key DESC',
      limit: limit,
    );
    return maps.reversed
        .map((m) => (m['night_hr_avg'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRecentDailySummaries({
    int limit = 7,
  }) async {
    final db = await database;
    return db.query('daily_summaries', orderBy: 'date_key DESC', limit: limit);
  }

  // Clear all local data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('daily_checkins');
    await db.delete('workouts');
    await db.delete('rhr_history');
    await db.delete('daily_summaries');
  }
}
