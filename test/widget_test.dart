import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:th5_2324801030055/data/note_database.dart';
import 'package:th5_2324801030055/main.dart';
import 'package:th5_2324801030055/models/note.dart';
import 'package:th5_2324801030055/utils/text_utils.dart';

NoteDatabase openTestDatabase() {
  return NoteDatabase(
    dbFactory: databaseFactoryFfiNoIsolate,
    dbPath: inMemoryDatabasePath,
  );
}

Note sampleNote(String title, String content, {int minute = 0}) {
  final time = DateTime(2026, 10, 12, 8, minute);
  return Note(title: title, content: content, createdAt: time, updatedAt: time);
}

Future<void> addNoteFromUi(
  WidgetTester tester,
  String title,
  String content,
) async {
  await tester.tap(find.text('Thêm ghi chú'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Tiêu đề'), title);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Nội dung'),
    content,
  );
  await tester.tap(find.text('Lưu'));
  await tester.pumpAndSettle();
}

void testApp(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    final database = openTestDatabase();
    try {
      await tester.pumpWidget(NotesApp(database: database));
      await tester.pumpAndSettle();
      await body(tester);
    } finally {
      await database.close();
    }
  });
}

void main() {
  setUpAll(sqfliteFfiInit);

  group('text utils', () {
    test('normalizeText bỏ dấu và giữ nguyên độ dài', () {
      const input = 'Đi Chợ Mua Sắm, Học Tiếng Việt';
      final output = normalizeText(input);
      expect(output, 'di cho mua sam, hoc tieng viet');
      expect(output.length, input.length);
    });

    test('previewAround cắt đoạn gần từ khóa', () {
      const content =
          'Dòng mở đầu khá dài để đẩy từ khóa ra xa khỏi phần xem trước, '
          'sau đó mới nhắc tới cuộc họp nhóm';
      final preview = previewAround(content, 'cuoc hop');
      expect(preview.startsWith('...'), isTrue);
      expect(preview.length, lessThan(content.length));
      expect(normalizeText(preview), contains('cuoc hop'));
      expect(previewAround(content, ''), content);
    });

    test('formatDateTime', () {
      expect(formatDateTime(DateTime(2026, 3, 5, 7, 9)), '05/03/2026 07:09');
    });
  });

  group('NoteDatabase', () {
    late NoteDatabase database;

    setUp(() => database = openTestDatabase());
    tearDown(() => database.close());

    test('thêm, sửa và sắp xếp theo thời gian tạo', () async {
      final first = await database.insert(sampleNote('A', 'một'));
      await database.insert(sampleNote('B', 'hai', minute: 5));

      var notes = await database.activeNotes();
      expect(notes.map((note) => note.title), ['B', 'A']);

      await database.update(
        first.copyWith(title: 'A mới', updatedAt: DateTime(2026, 10, 12, 9)),
      );
      notes = await database.activeNotes();
      expect(notes.last.title, 'A mới');
      expect(notes.last.isEdited, isTrue);
      expect(notes.last.createdAt, first.createdAt);
    });

    test('thùng rác, khôi phục và xóa vĩnh viễn', () async {
      final first = await database.insert(sampleNote('A', 'một'));
      final second = await database.insert(sampleNote('B', 'hai', minute: 5));

      await database.moveToTrash(first.id!);
      expect((await database.activeNotes()).single.title, 'B');
      expect((await database.trashedNotes()).single.deletedAt, isNotNull);
      expect(await database.trashCount(), 1);

      await database.restore(first.id!);
      expect(await database.activeNotes(), hasLength(2));
      expect(await database.trashCount(), 0);

      await database.moveToTrash(first.id!);
      await database.deleteForever(first.id!);
      expect(await database.trashCount(), 0);

      await database.moveToTrash(second.id!);
      await database.emptyTrash();
      expect(await database.activeNotes(), isEmpty);
      expect(await database.trashedNotes(), isEmpty);
    });
  });

  group('giao diện', () {
    testApp('thêm, sửa và tìm kiếm không dấu', (tester) async {
      expect(find.text('Chưa có ghi chú nào'), findsOneWidget);

      await tester.tap(find.text('Thêm ghi chú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
      expect(find.text('Vui lòng nhập nội dung'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await addNoteFromUi(tester, 'Đi chợ', 'Mua rau và trái cây');
      await addNoteFromUi(tester, 'Học Flutter', 'Ôn lại SQLite');
      expect(find.text('Đi chợ'), findsOneWidget);
      expect(find.text('Học Flutter'), findsOneWidget);

      await tester.tap(find.text('Đi chợ'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh sửa ghi chú'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tiêu đề'),
        'Đi siêu thị',
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Đi chợ'), findsNothing);
      expect(find.text('Đi siêu thị'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'sieu thi');
      await tester.pump();
      expect(find.text('Tìm thấy 1 ghi chú'), findsOneWidget);
      expect(find.text('Đi siêu thị'), findsOneWidget);
      expect(find.text('Học Flutter'), findsNothing);

      await tester.enterText(find.byType(TextField), 'khong co');
      await tester.pump();
      expect(find.text('Không tìm thấy ghi chú'), findsOneWidget);

      await tester.tap(find.byTooltip('Xóa từ khóa'));
      await tester.pump();
      expect(find.text('Học Flutter'), findsOneWidget);
    });

    testApp('giữ lâu để xóa rồi hoàn tác', (tester) async {
      await addNoteFromUi(tester, 'Đi chợ', 'Mua rau và trái cây');

      await tester.longPress(find.text('Đi chợ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa ghi chú'));
      await tester.pumpAndSettle();
      expect(find.text('Xóa ghi chú?'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Đi chợ'), findsOneWidget);

      await tester.longPress(find.text('Đi chợ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa ghi chú'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await tester.pumpAndSettle();
      expect(find.text('Đi chợ'), findsNothing);
      expect(find.text('Đã chuyển vào thùng rác'), findsOneWidget);

      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(find.text('Đi chợ'), findsOneWidget);
    });

    testApp('vuốt để hiện nút xóa rồi khôi phục từ thùng rác', (tester) async {
      await addNoteFromUi(tester, 'Đi chợ', 'Mua rau và trái cây');

      await tester.drag(find.text('Đi chợ'), const Offset(-250, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có ghi chú nào'), findsOneWidget);

      await tester.tap(find.byTooltip('Thùng rác'));
      await tester.pumpAndSettle();
      expect(find.text('Đi chợ'), findsOneWidget);
      await tester.tap(find.text('Khôi phục'));
      await tester.pumpAndSettle();
      expect(find.text('Thùng rác trống'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Đi chợ'), findsOneWidget);
    });

    testApp('xóa vĩnh viễn và dọn sạch thùng rác', (tester) async {
      for (final title in ['Đi chợ', 'Học Flutter', 'Họp nhóm']) {
        await addNoteFromUi(tester, title, 'Nội dung');
        await tester.longPress(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xóa ghi chú'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byTooltip('Thùng rác'));
      await tester.pumpAndSettle();
      expect(find.text('Khôi phục'), findsNWidgets(3));

      await tester.tap(find.text('Xóa vĩnh viễn').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa vĩnh viễn'));
      await tester.pumpAndSettle();
      expect(find.text('Khôi phục'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Dọn sạch thùng rác'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dọn sạch'));
      await tester.pumpAndSettle();
      expect(find.text('Thùng rác trống'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Chưa có ghi chú nào'), findsOneWidget);
    });
  });
}
