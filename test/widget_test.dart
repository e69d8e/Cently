import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cently/main.dart';
import 'package:cently/models/category.dart';
import 'package:cently/models/transaction_record.dart';
import 'package:cently/providers/category_provider.dart';
import 'package:cently/providers/transaction_provider.dart';
import 'package:cently/screens/home/home_screen.dart';
import 'package:cently/screens/record/add_record_screen.dart';
import 'package:cently/theme/app_colors.dart';
import 'package:cently/utils/currency_format.dart';
import 'package:cently/widgets/date_or_month_picker_sheet.dart';
import 'package:cently/widgets/record_date_time_picker_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Cently app launches and displays navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const CentlyApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Verify presence of navigation labels
    expect(find.text('明细'), findsOneWidget);
    expect(find.text('统计'), findsOneWidget);
    expect(find.text('分类'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('Category manage screen renders and tabs work without error', (WidgetTester tester) async {
    await tester.pumpWidget(const CentlyApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Tap on 分类 tab
    await tester.tap(find.text('分类'));
    await tester.pump(const Duration(milliseconds: 300));

    // Check tabs
    expect(find.text('支出分类'), findsOneWidget);
    expect(find.text('收入分类'), findsOneWidget);

    // Switch to 收入分类
    await tester.tap(find.text('收入分类'));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap on 设置 tab
    await tester.tap(find.text('设置'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('类型与名称管理'), findsOneWidget);
  });

  testWidgets('Tapping FAB opens AddRecordScreen without Hero or overflow exception', (WidgetTester tester) async {
    await tester.pumpWidget(const CentlyApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Tap the central add icon on the FAB
    final fab = find.byType(FloatingActionButton).first;
    await tester.tap(fab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check that AddRecordScreen is opened
    expect(find.byType(AddRecordScreen), findsOneWidget);
    expect(find.text('选择或输入名称'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('再记'), findsOneWidget);
  });

  testWidgets('Tapping date in AppBar opens DateOrMonthPickerSheet and can select day or month', (WidgetTester tester) async {
    await tester.pumpWidget(const CentlyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap the AppBar title dropdown
    final titleFinder = find.byIcon(Icons.keyboard_arrow_down_rounded);
    expect(titleFinder, findsOneWidget);
    await tester.tap(titleFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check DateOrMonthPickerSheet is shown with quick buttons
    expect(find.byType(DateOrMonthPickerSheet), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('昨天'), findsOneWidget);

    // Tap "今天" to select day view
    await tester.tap(find.text('今天'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify day mode banner is displayed
    expect(find.text('查看整月'), findsOneWidget);

    // Tap "查看整月" to switch back to whole month view
    await tester.tap(find.text('查看整月'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify day mode banner is gone
    expect(find.text('查看整月'), findsNothing);
  });

  testWidgets('In AddRecordScreen, user can customize date and time via RecordDateTimePickerSheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const CentlyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap FAB
    final fab = find.byType(FloatingActionButton).first;
    await tester.tap(fab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Date chip shows default clock icon
    final dateChipFinder = find.byIcon(Icons.access_time_rounded);
    expect(dateChipFinder, findsOneWidget);

    // Tap the date chip
    await tester.tap(dateChipFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check that RecordDateTimePickerSheet is opened
    expect(find.byType(RecordDateTimePickerSheet), findsOneWidget);
    expect(find.text('设置记账日期与时间'), findsOneWidget);
    expect(find.text('设为当前时间'), findsOneWidget);
    expect(find.text('昨天'), findsOneWidget);

    // Tap "昨天"
    await tester.tap(find.text('昨天'));
    await tester.pump();

    // Tap "确认设置时间"
    await tester.tap(find.text('确认设置时间'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check that custom date indicator icon is updated
    expect(find.byIcon(Icons.edit_calendar_rounded), findsOneWidget);
  });

  testWidgets('Editing existing transaction record >= 1000 properly displays raw amount and can be edited/saved', (WidgetTester tester) async {
    final testRecord = TransactionRecord(
      id: 'tx_edit_test',
      amount: 1500.0,
      type: CategoryType.expense,
      categoryId: 'cat_dining',
      categoryName: '餐饮',
      name: '公司团建聚餐',
      dateTime: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: MaterialApp(
          home: AddRecordScreen(initialRecord: testRecord),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial raw amount is displayed as "1500" without commas causing parsing errors
    expect(find.text('1500'), findsOneWidget);
    // In edit mode, "清空" should be present instead of "再记"
    expect(find.text('清空'), findsOneWidget);
    expect(find.text('再记'), findsNothing);

    // Test first key replacement: tap '8' should replace 1500 with 8
    await tester.tap(find.text('8'));
    await tester.pump();
    // Two widgets with '8': the keypad button and the amount display
    expect(find.text('8'), findsNWidgets(2));

    // Tap '0' twice -> 800 (800 only appears in amount display)
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.text('800'), findsOneWidget);

    // Test "清空" button resets to '0'
    await tester.tap(find.text('清空'));
    await tester.pump();
    // Two widgets with '0': the keypad button and the amount display
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('Physical keyboard input works in AddRecordScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const MaterialApp(
          home: AddRecordScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Send physical keyboard events '9', '5'
    await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.pump();
    expect(find.text('95'), findsOneWidget);

    // Send Backspace -> '9'
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(find.text('9'), findsNWidgets(2)); // Keypad key 9 and amount 9
  });

  testWidgets('Delete confirmation dialog displays record details and handles cancel and confirm', (WidgetTester tester) async {
    final record = TransactionRecord(
      id: 'tx_dialog_test',
      amount: 128.50,
      type: CategoryType.expense,
      categoryId: 'cat_dining',
      categoryName: '餐饮',
      name: '朋友聚餐',
      dateTime: DateTime(2026, 8, 18, 19, 0),
    );

    bool? dialogResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                dialogResult = await showDialog<bool>(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('删除此笔记录？'),
                    content: Text('确认删除「${record.name}」¥${CurrencyFormat.format(record.amount, showSymbol: false)} 的记账记录？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
                        onPressed: () => Navigator.pop(confirmCtx, true),
                        child: const Text('确认删除'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    // 1. Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog elements
    expect(find.text('删除此笔记录？'), findsOneWidget);
    expect(find.text('确认删除「朋友聚餐」¥128.50 的记账记录？'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认删除'), findsOneWidget);

    // 2. Tap cancel -> returns false
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(dialogResult, false);

    // 3. Open dialog again and tap confirm -> returns true
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(dialogResult, true);
  });

  testWidgets('Dismissible with confirmDismiss prevents dismissal on cancel and deletes on confirm', (WidgetTester tester) async {
    bool dismissed = false;
    bool shouldConfirm = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: dismissed
                  ? const SizedBox()
                  : Dismissible(
                      key: const ValueKey('item_1'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return shouldConfirm;
                      },
                      onDismissed: (_) {
                        setState(() {
                          dismissed = true;
                        });
                      },
                      child: const SizedBox(
                        width: 100,
                        height: 100,
                        child: Text('测试条目'),
                      ),
                    ),
            );
          },
        ),
      ),
    );

    // 1. When shouldConfirm is false, dragging does not remove the item
    shouldConfirm = false;
    await tester.drag(find.text('测试条目'), const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(find.text('测试条目'), findsOneWidget);
    expect(dismissed, false);

    // 2. When shouldConfirm is true, dragging removes the item
    shouldConfirm = true;
    await tester.drag(find.text('测试条目'), const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(find.text('测试条目'), findsNothing);
    expect(dismissed, true);
  });
}


