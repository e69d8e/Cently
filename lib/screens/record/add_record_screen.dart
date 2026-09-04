import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/default_data.dart';
import '../../models/category.dart';
import '../../models/preset_item.dart';
import '../../models/transaction_record.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_format_helper.dart';
import '../../widgets/category_icon_widget.dart';
import '../../widgets/numeric_keyboard.dart';
import '../../widgets/record_date_time_picker_sheet.dart';
import '../category_manage/category_detail_screen.dart';

class AddRecordScreen extends StatefulWidget {
  final TransactionRecord? initialRecord; // If editing
  final Category? initialCategory; // If pre-filling category (e.g. repeat record)
  final String? initialName; // If pre-filling item name

  const AddRecordScreen({
    super.key,
    this.initialRecord,
    this.initialCategory,
    this.initialName,
  });

  static Future<bool?> show(
    BuildContext context, {
    TransactionRecord? initialRecord,
    Category? initialCategory,
    String? initialName,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddRecordScreen(
          initialRecord: initialRecord,
          initialCategory: initialCategory,
          initialName: initialName,
        ),
      ),
    );
  }

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  late CategoryType _type;
  Category? _selectedCategory;
  late TextEditingController _nameController;
  late TextEditingController _remarkController;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _remarkFocusNode = FocusNode();
  late DateTime _selectedDateTime;
  bool _isCustomDateTime = false;
  String _amountExpression = '0';
  bool _isCustomNameActive = false;
  bool _isInitialAmountState = false;
  final FocusNode _keyboardFocusNode = FocusNode();
  String? _cachedPresetCategoryId;
  List<PresetItem> _cachedSortedPresets = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecord;
    if (initial != null) {
      _type = initial.type;
      _nameController = TextEditingController(text: initial.name);
      _remarkController = TextEditingController(text: initial.remark ?? '');
      _selectedDateTime = initial.dateTime;
      _isCustomDateTime = true;
      _amountExpression = CurrencyFormat.formatRaw(initial.amount);
      _isInitialAmountState = true;
      _isCustomNameActive = true;
    } else {
      _type = widget.initialCategory?.type ?? CategoryType.expense;
      _selectedCategory = widget.initialCategory;
      _nameController = TextEditingController(text: widget.initialName ?? '');
      _remarkController = TextEditingController();
      _selectedDateTime = DateTime.now();
      _isCustomDateTime = false;
      _amountExpression = '0';
      _isInitialAmountState = false;
      _isCustomNameActive = (widget.initialName != null && widget.initialName!.isNotEmpty);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (initial != null) {
        final found = catProvider.getCategoryById(initial.categoryId);
        if (found != null) {
          setState(() {
            _selectedCategory = found;
          });
        }
      } else if (widget.initialCategory != null) {
        final found = catProvider.getCategoryById(widget.initialCategory!.id);
        if (found != null) {
          setState(() {
            _selectedCategory = found;
          });
        }
      }
      if (_selectedCategory == null) {
        final defaultList = _type == CategoryType.expense
            ? catProvider.expenseCategories
            : catProvider.incomeCategories;
        if (defaultList.isNotEmpty) {
          _onCategorySelected(defaultList.first);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _remarkFocusNode.dispose();
    _keyboardFocusNode.dispose();
    _nameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _onTypeChanged(CategoryType type) {
    if (_type == type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _isCustomNameActive = false;
      _cachedPresetCategoryId = null;
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      final list = type == CategoryType.expense
          ? catProvider.expenseCategories
          : catProvider.incomeCategories;
      if (list.isNotEmpty) {
        _onCategorySelected(list.first);
      } else {
        _selectedCategory = null;
        _nameController.text = '';
      }
    });
  }

  void _onCategorySelected(Category category) {
    setState(() {
      _selectedCategory = category;
      _cachedPresetCategoryId = null;
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      final presets = catProvider.getPresetsForCategory(category.id);
      if (!_isCustomNameActive) {
        if (presets.isNotEmpty) {
          _nameController.text = presets.first.name;
        } else {
          _nameController.text = category.name;
        }
      }
    });
  }

  void _onPresetChipTapped(PresetItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = item.name;
      _isCustomNameActive = false;
    });
  }

  void _handleKeyPress(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      _amountExpression = CurrencyFormat.processKeyInput(
        currentExpression: _amountExpression,
        key: key,
        isInitialState: _isInitialAmountState,
      );
      _isInitialAmountState = false;
    });
  }

  bool _isShowingExitDialog = false;
  bool _isForceClosing = false;

  bool _hasUnsavedChanges() {
    if (_isForceClosing) return false;

    if (widget.initialRecord != null) {
      final initial = widget.initialRecord!;
      final currentAmount = _parseAmount();
      final currentName = _nameController.text.trim().isEmpty
          ? (_selectedCategory?.name ?? '')
          : _nameController.text.trim();
      final currentRemark = _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim();

      if (currentAmount != initial.amount) return true;
      if (_type != initial.type) return true;
      if (_selectedCategory != null && _selectedCategory!.id != initial.categoryId) return true;
      if (currentName != initial.name) return true;
      if (currentRemark != initial.remark) return true;
      if (_selectedDateTime != initial.dateTime) return true;
      return false;
    } else {
      final currentAmount = _parseAmount();
      if (currentAmount > 0 || _amountExpression != '0') {
        return true;
      }
      if (_remarkController.text.trim().isNotEmpty) {
        return true;
      }
      return false;
    }
  }

  Future<void> _handlePopScope() async {
    if (_isShowingExitDialog || _isForceClosing) return;
    _isShowingExitDialog = true;

    try {
      final amount = _parseAmount();
      final isEditing = widget.initialRecord != null;

      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isEditing ? '保存修改？' : '保存本次记录？'),
          content: Text(
            isEditing
                ? '当前修改尚未保存，是否保存后再退出？'
                : '您已输入金额 ¥${CurrencyFormat.formatRaw(amount)}，是否需要保存？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.expense,
              ),
              child: const Text('不保存'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('保存'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (action == 'save') {
        final success = await _saveRecord();
        if (success && mounted) {
          _isForceClosing = true;
          setState(() {});
          Navigator.of(context).pop(true);
        }
      } else if (action == 'discard') {
        _isForceClosing = true;
        setState(() {});
        Navigator.of(context).pop();
      }
    } finally {
      _isShowingExitDialog = false;
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final logicalKey = event.logicalKey;

    if (logicalKey == LogicalKeyboardKey.escape) {
      if (_nameFocusNode.hasFocus || _remarkFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
        _keyboardFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      Navigator.maybePop(context);
      return KeyEventResult.handled;
    }

    // If focus is inside a TextField (name or remark), do NOT intercept keypad events
    if (!_keyboardFocusNode.hasPrimaryFocus || _nameFocusNode.hasFocus || _remarkFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
      _onDoneSave();
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.backspace) {
      _handleKeyPress('⌫');
      return KeyEventResult.handled;
    }

    if (logicalKey == LogicalKeyboardKey.delete) {
      setState(() {
        _amountExpression = '0';
        _isInitialAmountState = false;
      });
      return KeyEventResult.handled;
    }

    // Direct logical key mappings for numbers and operators
    if (logicalKey == LogicalKeyboardKey.digit0 || logicalKey == LogicalKeyboardKey.numpad0) {
      _handleKeyPress('0');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit1 || logicalKey == LogicalKeyboardKey.numpad1) {
      _handleKeyPress('1');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit2 || logicalKey == LogicalKeyboardKey.numpad2) {
      _handleKeyPress('2');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit3 || logicalKey == LogicalKeyboardKey.numpad3) {
      _handleKeyPress('3');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit4 || logicalKey == LogicalKeyboardKey.numpad4) {
      _handleKeyPress('4');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit5 || logicalKey == LogicalKeyboardKey.numpad5) {
      _handleKeyPress('5');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit6 || logicalKey == LogicalKeyboardKey.numpad6) {
      _handleKeyPress('6');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit7 || logicalKey == LogicalKeyboardKey.numpad7) {
      _handleKeyPress('7');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit8 || logicalKey == LogicalKeyboardKey.numpad8) {
      _handleKeyPress('8');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.digit9 || logicalKey == LogicalKeyboardKey.numpad9) {
      _handleKeyPress('9');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.add || logicalKey == LogicalKeyboardKey.numpadAdd) {
      _handleKeyPress('+');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.minus || logicalKey == LogicalKeyboardKey.numpadSubtract) {
      _handleKeyPress('-');
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.period || logicalKey == LogicalKeyboardKey.numpadDecimal) {
      _handleKeyPress('.');
      return KeyEventResult.handled;
    }

    final keyLabel = event.character;
    if (keyLabel != null && keyLabel.isNotEmpty) {
      if (RegExp(r'^[0-9+\-\.]$').hasMatch(keyLabel)) {
        _handleKeyPress(keyLabel);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  double _parseAmount() {
    return CurrencyFormat.parseExpression(_amountExpression);
  }

  Future<bool> _saveRecord() async {
    final amount = _parseAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效金额'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }

    if (_selectedCategory == null) {
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      final currentCategories = _type == CategoryType.expense
          ? catProvider.expenseCategories
          : catProvider.incomeCategories;
      if (currentCategories.isNotEmpty) {
        _selectedCategory = currentCategories.first;
      } else {
        final defaultCats = DefaultData.getDefaultCategories();
        final list = _type == CategoryType.expense
            ? defaultCats.where((c) => c.type == CategoryType.expense).toList()
            : defaultCats.where((c) => c.type == CategoryType.income).toList();
        if (list.isNotEmpty) {
          _selectedCategory = list.first;
        }
      }
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择分类类型'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final name = _nameController.text.trim().isEmpty
        ? _selectedCategory!.name
        : _nameController.text.trim();

    final recordTime = (_isCustomDateTime || widget.initialRecord != null)
        ? _selectedDateTime
        : DateTime.now();

    final remarkText = _remarkController.text.trim();
    final remarkValue = remarkText.isNotEmpty ? remarkText : null;

    if (widget.initialRecord != null) {
      final updated = widget.initialRecord!.copyWith(
        amount: amount,
        type: _type,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        name: name,
        dateTime: recordTime,
        remark: remarkValue,
        clearRemark: remarkValue == null,
      );
      await txProvider.updateTransaction(updated);
    } else {
      await txProvider.addTransaction(
        amount: amount,
        type: _type,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        name: name,
        dateTime: recordTime,
        remark: remarkValue,
      );
    }
    return true;
  }

  void _onDoneSave() async {
    final success = await _saveRecord();
    if (success && mounted) {
      _isForceClosing = true;
      setState(() {});
      Navigator.pop(context, true);
    }
  }

  void _onSaveAndContinue() async {
    final success = await _saveRecord();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已记录：${_nameController.text} ¥${_parseAmount().toStringAsFixed(2)}'),
          duration: const Duration(milliseconds: 1000),
        ),
      );
      setState(() {
        _amountExpression = '0';
        _isInitialAmountState = false;
        _remarkController.clear();
        _cachedPresetCategoryId = null;
      });
    }
  }

  List<PresetItem> _getSortedPresets(
    Category? category,
    CategoryProvider catProvider,
    TransactionProvider txProvider,
  ) {
    if (category == null) return const [];
    if (_cachedPresetCategoryId == category.id) {
      return _cachedSortedPresets;
    }

    final rawPresets = catProvider.getPresetsForCategory(category.id);
    if (rawPresets.isEmpty) {
      _cachedPresetCategoryId = category.id;
      _cachedSortedPresets = const [];
      return const [];
    }

    final sorted = List<PresetItem>.from(rawPresets);
    final frequencyMap = <String, int>{};
    for (final r in txProvider.monthRecords) {
      if (r.categoryId == category.id) {
        frequencyMap[r.name] = (frequencyMap[r.name] ?? 0) + 1;
      }
    }
    sorted.sort((a, b) {
      final countA = frequencyMap[a.name] ?? 0;
      final countB = frequencyMap[b.name] ?? 0;
      if (countA != countB) {
        return countB.compareTo(countA); // Higher frequency first
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });

    _cachedPresetCategoryId = category.id;
    _cachedSortedPresets = sorted;
    return sorted;
  }

  Future<void> _selectDateTime() async {
    final picked = await RecordDateTimePickerSheet.show(context, _selectedDateTime);
    if (picked != null && mounted) {
      setState(() {
        _selectedDateTime = picked;
        _isCustomDateTime = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catProvider = Provider.of<CategoryProvider>(context);

    final currentCategories = _type == CategoryType.expense
        ? catProvider.expenseCategories
        : catProvider.incomeCategories;

    // Synchronize selected category if none selected or if not in current category list
    if (currentCategories.isNotEmpty) {
      if (_selectedCategory == null || !currentCategories.any((c) => c.id == _selectedCategory!.id)) {
        if (widget.initialRecord != null && _selectedCategory == null) {
          final matched = catProvider.getCategoryById(widget.initialRecord!.categoryId);
          _selectedCategory = matched ?? currentCategories.first;
        } else {
          _selectedCategory = currentCategories.first;
        }
        if (!_isCustomNameActive && _nameController.text.isEmpty) {
          final presets = catProvider.getPresetsForCategory(_selectedCategory!.id);
          _nameController.text = presets.isNotEmpty ? presets.first.name : _selectedCategory!.name;
        }
      }
    }

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final currentPresets = _getSortedPresets(_selectedCategory, catProvider, txProvider);

    final accentColor = _type == CategoryType.expense
        ? AppColors.expense
        : AppColors.income;

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePopScope();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: _buildTypeSegmentedToggle(),
          actions: [
            IconButton(
              tooltip: '管理分类与名称',
              icon: const Icon(Icons.tune_rounded, size: 20),
              onPressed: () {
                if (_selectedCategory != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailScreen(
                        category: _selectedCategory!,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_nameFocusNode.hasFocus || _remarkFocusNode.hasFocus) {
              FocusScope.of(context).unfocus();
              _keyboardFocusNode.requestFocus();
            }
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Focus(
                focusNode: _keyboardFocusNode,
                autofocus: true,
                onKeyEvent: _handleKeyEvent,
                child: Column(
                  children: [
                    // Amount & Info Banner
                    _buildAmountDisplay(accentColor, isDark),

                    // Category Selector (Horizontal Scroll / Grid)
                    _buildCategoryList(currentCategories, isDark),

                    // Preset Names and Custom Input Area
                    Expanded(
                      child: _buildNameAndRemarkSection(currentPresets, isDark),
                    ),

                    // Integrated Custom Calculator Keyboard
                    if (!isKeyboardOpen)
                      NumericKeyboard(
                        amountText: _amountExpression,
                        accentColor: accentColor,
                        isEditing: widget.initialRecord != null,
                        isInitialState: _isInitialAmountState,
                        onChanged: (newVal) {
                          setState(() {
                            _amountExpression = newVal;
                            _isInitialAmountState = false;
                          });
                        },
                        onSave: _onDoneSave,
                        onSaveAndContinue: _onSaveAndContinue,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegmentedToggle() {
    final isExpense = _type == CategoryType.expense;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceMutedDark
            : AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem('支出', isExpense, AppColors.expense, () {
            _onTypeChanged(CategoryType.expense);
          }),
          _buildToggleItem('收入', !isExpense, AppColors.income, () {
            _onTypeChanged(CategoryType.income);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    String label,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay(Color accentColor, bool isDark) {
    final clean = _amountExpression.replaceAll(',', '').trim();
    final hasOp = CurrencyFormat.hasPendingCalculation(clean);
    final calculated = hasOp ? CurrencyFormat.parseExpression(clean) : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category tag + Date picker chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_selectedCategory != null)
                Row(
                  children: [
                    CategoryIconWidget(
                      iconKey: _selectedCategory!.iconKey,
                      color: _selectedCategory!.color,
                      size: 26,
                      iconSize: 15,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory!.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(),
              // Date Chip Button
              InkWell(
                onTap: _selectDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isCustomDateTime
                        ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight),
                    borderRadius: BorderRadius.circular(12),
                    border: _isCustomDateTime
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCustomDateTime ? Icons.edit_calendar_rounded : Icons.access_time_rounded,
                        size: 13,
                        color: _isCustomDateTime
                            ? AppColors.primary
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatHelper.formatRelativeDateTime(_selectedDateTime),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _isCustomDateTime ? FontWeight.w600 : FontWeight.w500,
                          color: _isCustomDateTime
                              ? AppColors.primary
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Amount typography
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _amountExpression,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      if (calculated != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '= ${CurrencyFormat.formatRaw(calculated)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: accentColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, bool isDark) {
    if (categories.isEmpty) {
      return const SizedBox(height: 60);
    }

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory?.id == cat.id;

          return GestureDetector(
            onTap: () => _onCategorySelected(cat),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected ? cat.color : cat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? Border.all(color: cat.color, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      AppIcons.getIcon(cat.iconKey),
                      color: isSelected ? Colors.white : cat.color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNameAndRemarkSection(List<PresetItem> presets, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset chips title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择或输入名称',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              if (_selectedCategory != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailScreen(
                          category: _selectedCategory!,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '管理预设',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Preset Chips Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...presets.map((item) {
                final isSelected = _nameController.text == item.name;
                return ChoiceChip(
                  label: Text(item.name),
                  selected: isSelected,
                  onSelected: (_) => _onPresetChipTapped(item),
                  selectedColor: isDark ? AppColors.primaryLight : AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  backgroundColor: isDark
                      ? AppColors.surfaceMutedDark
                      : AppColors.surfaceMutedLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide.none,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                );
              }),
            ],
          ),

          const SizedBox(height: 14),

          // Custom Name Input Field
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textInputAction: TextInputAction.next,
            onChanged: (text) {
              setState(() {
                _isCustomNameActive = true;
              });
            },
            onSubmitted: (_) {
              _remarkFocusNode.requestFocus();
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: '自定义名称 (如：生椰拿铁 / 打车回学校)',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
              prefixIcon: const Icon(Icons.edit_outlined, size: 18),
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _nameController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          const SizedBox(height: 10),

          // Optional Remark Input Field
          TextField(
            controller: _remarkController,
            focusNode: _remarkFocusNode,
            textInputAction: TextInputAction.done,
            onChanged: (text) {
              setState(() {});
            },
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              _keyboardFocusNode.requestFocus();
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: '添加备注 (选填)...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
              prefixIcon: const Icon(Icons.notes_rounded, size: 18),
              suffixIcon: _remarkController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _remarkController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
