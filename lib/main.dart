import 'package:flutter/material.dart';

import 'data/note_database.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(NotesApp(database: NoteDatabase()));
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key, required this.database});

  final NoteDatabase database;

  ThemeData _theme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00796B),
        brightness: brightness,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghi chú',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: HomeScreen(database: database),
    );
  }
}
