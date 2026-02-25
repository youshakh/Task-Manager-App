import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:task_management/models/task.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';



class DBHelper {
  static Database? _db;
  static final int _version = 1;
  static final String _tableName = 'tasks';
  static final String _tableUser = 'users';
  static final String user_photos = 'photo';
  static final dynamic _columnName = 'username';
  static final dynamic _columnPassword = 'password';

  static int? loggedInUserId;

  static Future<void> initDb() async {
    if (_db != null) {
      debugPrint("not null db");
      return;
    }
    try {
      String _path = join(await getDatabasesPath(), 'tasks.db');
      debugPrint("Database path: $_path");
      _db = await openDatabase(
        _path,
        version: _version,
        onCreate: (db, version) async {
          debugPrint("Creating a new database");
          await db.execute('''
            CREATE TABLE $_tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              note TEXT,
              date TEXT,
              startTime TEXT,
              endTime TEXT,
              remind INTEGER,
              repeat TEXT,
              color INTEGER,
              isCompleted INTEGER,
              userId INTEGER,
              FOREIGN KEY (userId) REFERENCES users(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE $_tableUser( 
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              $_columnName TEXT, 
              $_columnPassword TEXT)
          ''');
          await db.execute('''
      CREATE TABLE  $user_photos (
           id INTEGER PRIMARY KEY AUTOINCREMENT,
          photo_path TEXT,
          userId INTEGER,
          FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');
          await db.execute('''
  INSERT INTO $_tableUser (id, $_columnName, $_columnPassword)
  VALUES (1, 'Username', 'Passwort')
''');
        },
      );
    } catch (e) {
      print(e);
    }
  }

  static Database? get db => _db;
  static String get tableUser => _tableUser;

  static Future<int> insert(Task task, int userId) async {
    print("insert function called");
    task.userId = userId;

    return await _db!.insert(_tableName, task.toJson());
  }

  static Future<int> delete(Task task) async =>
      await _db!.delete(_tableName, where: 'id = ?', whereArgs: [task.id]);

  static Future<List<Task>> query() async {
    print("query function called");
    final List<Map<String, dynamic>> result = await _db!.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [loggedInUserId],

    );
    List<Task> tasks = result.map((map) => Task.fromJson(map)).toList();
    print (tasks);
    return tasks;
  }


  static Future<int> update(int? id) async {
    print("update function called");
    return await _db!.rawUpdate('''
      UPDATE $_tableName  
      SET isCompleted = ?
      WHERE id = ?
    ''', [1, id]);
  }

  static Future<List<Task>> getTasksFromCurrentMonth(int userId) async {
    List<Task> tasks = [];
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateFormat formatter = DateFormat.yMd();
    final List<Map<String, dynamic>> result = await _db!.query(
      _tableName,
      where: 'userId = ? AND date >= ?',
      whereArgs: [userId, formatter.format(startOfMonth)],
    );
    if (result.isNotEmpty) {
      tasks = result.map((map) => Task.fromJson(map)).toList();
    }
    return tasks;
  }

  static Future<List<Task>> getWeeklyTasks(int userId) async {
    List<Task> weeklyTasks = [];
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    Duration mondayOffset = Duration(days: currentWeekday - 1);
    DateTime monday = now.subtract(mondayOffset);
    Duration sundayOffset = Duration(days: DateTime.daysPerWeek - currentWeekday);
    DateTime sunday = now.add(sundayOffset);
    DateFormat formatter = DateFormat.yMd();
    final List<Map<String, dynamic>> result = await _db!.query(
      _tableName,
      where: 'userId = ? AND date >= ? AND date <= ?',
      whereArgs: [loggedInUserId, formatter.format(monday), formatter.format(sunday)],
    );
    if (result.isNotEmpty) {
      weeklyTasks = result.map((map) => Task.fromJson(map)).toList();
    }
    return weeklyTasks;
  }
  Future<void> deleteExpiredTasks() async {
    List<Task> tasks = await query();
    DateTime currentDate = DateTime.now();
    List<Task> expiredTasks = [];

    int currentYear = currentDate.year;
    int currentMonth = currentDate.month;
    int currentDay = currentDate.day;


    for (Task task in tasks) {
      try {
        DateTime taskDate = DateFormat.yMd().parse(task.date!);
        int taskYear = taskDate.year;

        int taskMonth = taskDate.month;

        int taskDay = taskDate.day;

        if ((currentMonth > taskMonth || (currentMonth == taskMonth && currentDay > taskDay)) || currentYear != taskYear) {
          expiredTasks.add(task);
        }
      } catch (e) {
        // Skip tasks with invalid date format
      }
    }
    // Perform the deletion operation in the database
    for (Task task in expiredTasks) {
      await delete(task);
    }
  }





  static Future<int?> saveUser(User user, {bool isCurrentUser = false}) async {
    await initDb();
    final Map<String, dynamic> userData = user.toMap();

    user.id = await _db!.insert(_tableUser, userData);
    print('Benutzer mit ID ${user.id} wurde erfolgreich gespeichert!');

    return user.id;
  }

  static Future<User?> loginUser(dynamic username, dynamic password) async {
    var res = await _db!.rawQuery(
        "SELECT * FROM $_tableUser WHERE $_columnName = '$username' AND $_columnPassword = '$password'");
    if (res!.isNotEmpty) {
      User user = User.fromMap(res.first);
      loggedInUserId = user.id; // Speichern der Benutzer-ID in der Variable
      print("Eingeloggter Benutzer-ID: $loggedInUserId"); // Ausgabe der Benutzer-ID auf der Konsole

      return user;
    }
    return null;
  }
  Future<int?> insertPhoto(int userId, String photoPath) async {
    final db = _db;
    return await db?.insert(user_photos, {
      ' userId': userId,
      'photo_path': photoPath,
    });
  }
  Future<String?> getPhotoPath(int userId) async {

    final result = await _db!.query(
      user_photos,
      where: ' userId = ?',
      whereArgs: [userId],
    );
    if (result!.isNotEmpty) {
      return result.first['photo_path'] as String?;
    }
    return null;
  }
}

class User {
  int? id;
  dynamic username;
  dynamic password;


  User({required this.username, required this.password});

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'username': username,
      'password': password,

    };
    return map;
  }

  User.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        username = map['username']!,
        password = map['password']!;

}



