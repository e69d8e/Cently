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
import 'package:cently/screens/main_navigation_screen.dart';
import 'package:cently/screens/record/add_record_screen.dart';
import 'package:cently/screens/settings/data_backup_screen.dart';
import 'package:cently/screens/settings/recycle_bin_screen.dart';
import 'package:cently/screens/stats/stats_screen.dart';
import 'package:cently/theme/app_colors.dart';
import 'package:cently/utils/currency_format.dart';
import 'package:cently/widgets/date_or_month_picker_sheet.dart';
import 'package:cently/widgets/numeric_keyboard.dart';
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

  testWidgets('Editing existing transaction record remark and clearing remark works', (WidgetTester tester) async {
    final testRecord = TransactionRecord(
      id: 'tx_edit_remark_test',
      amount: 88.0,
      type: CategoryType.expense,
      categoryId: 'cat_dining',
      categoryName: '餐饮',
      name: '咖啡甜品',
      dateTime: DateTime.now(),
      remark: '原备注：少糖加冰',
    );

    final txProvider = TransactionProvider();
    final catProvider = CategoryProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: catProvider),
          ChangeNotifierProvider.value(value: txProvider),
        ],
        child: MaterialApp(
          home: AddRecordScreen(initialRecord: testRecord),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial remark is populated in TextField
    expect(find.text('原备注：少糖加冰'), findsOneWidget);

    // Find the remark TextField by finding TextField with hint '添加备注 (选填)...'
    final remarkFieldFinder = find.widgetWithText(TextField, '原备注：少糖加冰');
    expect(remarkFieldFinder, findsOneWidget);

    // 1. Clear remark via clear button icon
    final clearButtonFinder = find.byIcon(Icons.clear);
    expect(clearButtonFinder, findsWidgets); // May have clear buttons for name and remark
    // Tap the last clear button which corresponds to remark
    await tester.tap(clearButtonFinder.last);
    await tester.pumpAndSettle();

    expect(find.text('原备注：少糖加冰'), findsNothing);

    // 2. Enter new remark text containing numbers and verify amount remains 88
    await tester.enterText(find.byType(TextField).last, '2人份 外带 102号');
    await tester.pumpAndSettle();

    expect(find.text('2人份 外带 102号'), findsOneWidget);
    // Verify amount '88' is untouched
    expect(find.text('88'), findsOneWidget);
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

  testWidgets('Settings screen contains Recycle Bin entry and navigates to RecycleBinScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const CentlyApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Tap on 设置 tab
    await tester.tap(find.text('设置'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify presence of 账单回收站
    expect(find.text('账单回收站'), findsOneWidget);

    // Tap on 账单回收站
    await tester.tap(find.text('账单回收站'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify RecycleBinScreen is opened
    expect(find.byType(RecycleBinScreen), findsOneWidget);
  });

  testWidgets('RecycleBinScreen renders correctly with empty and deleted records', (WidgetTester tester) async {
    final txProvider = TransactionProvider();
    final catProvider = CategoryProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: catProvider),
          ChangeNotifierProvider.value(value: txProvider),
        ],
        child: const MaterialApp(
          home: RecycleBinScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Initially empty
    expect(find.text('回收站为空'), findsOneWidget);
  });

  testWidgets('In AddRecordScreen with initial record, pressing dot resets to 0.', (WidgetTester tester) async {
    final catProvider = CategoryProvider();
    final txProvider = TransactionProvider();

    final testRecord = TransactionRecord(
      id: 'tx_init_dot_test',
      amount: 1500.0,
      type: CategoryType.expense,
      categoryId: 'cat_dining',
      categoryName: '餐饮',
      name: '正餐',
      dateTime: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: catProvider),
          ChangeNotifierProvider.value(value: txProvider),
        ],
        child: MaterialApp(
          home: AddRecordScreen(initialRecord: testRecord),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initial expression is '1500'
    expect(find.text('1500'), findsOneWidget);

    // Tap '.'
    await tester.tap(find.text('.'));
    await tester.pumpAndSettle();

    // Verify it changed to '0.' instead of '1500.'
    expect(find.text('0.'), findsOneWidget);
  });

  testWidgets('StatsScreen displays empty state when no transactions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const MaterialApp(
          home: StatsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('暂无支出数据'), findsOneWidget);
    expect(find.text('本月还没有支出记录'), findsOneWidget);
  });

  testWidgets('AddRecordScreen pre-populates initialCategory and initialName for repeat record flow', (WidgetTester tester) async {
    final cat = Category(
      id: 'cat_dining',
      name: '餐饮',
      type: CategoryType.expense,
      iconKey: 'restaurant',
      colorValue: 0xFFE11D48,
      sortOrder: 0,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: MaterialApp(
          home: AddRecordScreen(
            initialCategory: cat,
            initialName: '星巴克美式',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('星巴克美式'), findsOneWidget);
    expect(find.text('餐饮'), findsWidgets);
  });

  testWidgets('MainNavigationScreen.switchToTab switches active tab programmatically', (WidgetTester tester) async {
    await tester.pumpWidget(const CentlyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final BuildContext context = tester.element(find.byType(HomeScreen));
    MainNavigationScreen.switchToTab(context, 1); // Switch to Stats
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(StatsScreen), findsOneWidget);
  });

  testWidgets('AddRecordScreen pops directly without prompt if amount is 0', (WidgetTester tester) async {
    final catProvider = CategoryProvider();
    final txProvider = TransactionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: catProvider),
          ChangeNotifierProvider.value(value: txProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddRecordScreen.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open AddRecordScreen
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AddRecordScreen), findsOneWidget);

    // Tap close button directly without entering amount
    final closeBtn = find.byIcon(Icons.close_rounded);
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // No dialog should appear and screen pops back to Open button
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AddRecordScreen), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('AddRecordScreen prompts user when amount > 0 and handles Cancel and Discard', (WidgetTester tester) async {
    final catProvider = CategoryProvider();
    final txProvider = TransactionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: catProvider),
          ChangeNotifierProvider.value(value: txProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddRecordScreen.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder numKey(String label) {
      return find.descendant(
        of: find.byType(NumericKeyboard),
        matching: find.text(label),
      );
    }

    // 1. Open AddRecordScreen
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AddRecordScreen), findsOneWidget);

    // Enter amount 25
    await tester.tap(numKey('2'));
    await tester.pump();
    await tester.tap(numKey('5'));
    await tester.pump();
    expect(find.text('25'), findsOneWidget);

    // Tap close button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('保存本次记录？'), findsOneWidget);
    expect(find.text('您已输入金额 ¥25，是否需要保存？'), findsOneWidget);

    // Tap "取消" (Cancel)
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // Dialog should be gone, AddRecordScreen still open with amount 25
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AddRecordScreen), findsOneWidget);
    expect(find.text('25'), findsOneWidget);

    // 2. Test Discard ("不保存") flow
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('保存本次记录？'), findsOneWidget);
    await tester.tap(find.text('不保存'));
    await tester.pumpAndSettle();

    // Screen should be closed and returned to root
    expect(find.byType(AddRecordScreen), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('AddRecordScreen in edit mode prompts when modified', (WidgetTester tester) async {
    final catProvider = CategoryProvider();
    final txProvider = TransactionProvider();

    final testRecord = TransactionRecord(
      id: 'tx_edit_prompt_test',
      amount: 50.0,
      type: CategoryType.expense,
      categoryId: 'cat_exp_food',
      categoryName: '餐饮',
      name: '午餐',
      dateTime: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: catProvider),
          ChangeNotifierProvider.value(value: txProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddRecordScreen.show(context, initialRecord: testRecord),
              child: const Text('Edit Record'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Without modifications, tap close -> pops directly
    await tester.tap(find.text('Edit Record'));
    await tester.pumpAndSettle();

    expect(find.byType(AddRecordScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AddRecordScreen), findsNothing);

    // 2. With modifications, tap close -> shows prompt
    await tester.tap(find.text('Edit Record'));
    await tester.pumpAndSettle();

    // Modify amount
    final key8 = find.descendant(of: find.byType(NumericKeyboard), matching: find.text('8'));
    await tester.tap(key8);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('保存修改？'), findsOneWidget);
    expect(find.text('当前修改尚未保存，是否保存后再退出？'), findsOneWidget);

    await tester.tap(find.text('不保存'));
    await tester.pumpAndSettle();

    expect(find.byType(AddRecordScreen), findsNothing);
    expect(find.text('Edit Record'), findsOneWidget);
  });

  testWidgets('DataBackupScreen renders Export and Import tabs without overflow on mobile constraints', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375 * 2.0, 667 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const MaterialApp(
          home: DataBackupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Export Tab
    expect(find.text('导出备份'), findsOneWidget);
    expect(find.text('保存文件'), findsNWidgets(2)); // JSON and CSV
    expect(find.text('复制备份'), findsOneWidget);
    expect(find.text('复制表格'), findsOneWidget);

    // Switch to Import Tab
    await tester.tap(find.text('导入恢复'));
    await tester.pumpAndSettle();

    expect(find.text('备份数据来源'), findsOneWidget);
    expect(find.text('选取文件'), findsOneWidget);
    expect(find.text('剪贴板粘贴'), findsOneWidget);

    // Enter text to trigger the '清空内容' button
    await tester.enterText(find.byType(TextField), '{"app":"Cently"}');
    await tester.pumpAndSettle();

    expect(find.text('清空内容'), findsOneWidget);

    // Tap '清空内容'
    await tester.tap(find.text('清空内容'));
    await tester.pumpAndSettle();

    expect(find.text('清空内容'), findsNothing);
  });
}



