import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';

class NoteDatabase {
  NoteDatabase({this.dbFactory, this.dbPath});

  static const _table = 'notes';

  final DatabaseFactory? dbFactory;
  final String? dbPath;
  Future<Database>? _opening;

  Future<Database> get _db => _opening ??= _open();

  Future<Database> _open() async {
    final factory = dbFactory ?? databaseFactory;
    final path = dbPath ?? join(await factory.getDatabasesPath(), 'notes.db');
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) {
          return db.execute('''
            CREATE TABLE $_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted_at INTEGER
            )
          ''');
        },
      ),
    );
  }

  Future<List<Note>> activeNotes() async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<List<Note>> trashedNotes() async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC, id DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<int> trashCount() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM $_table WHERE deleted_at IS NOT NULL',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<Note> insert(Note note) async {
    final db = await _db;
    final id = await db.insert(_table, note.toMap()..remove('id'));
    return note.copyWith(id: id);
  }

  Future<void> update(Note note) async {
    final db = await _db;
    await db.update(
      _table,
      note.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> moveToTrash(int id) async {
    final db = await _db;
    await db.update(
      _table,
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(int id) async {
    final db = await _db;
    await db.update(
      _table,
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteForever(int id) async {
    final db = await _db;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> emptyTrash() async {
    final db = await _db;
    await db.delete(_table, where: 'deleted_at IS NOT NULL');
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    _opening = null;
    await (await opening).close();
  }
}
