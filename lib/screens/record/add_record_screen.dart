import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

  const AddRecordScreen({super.key, this.initialRecord});

  static Future<bool?> show(BuildContext context, {TransactionRecord? initialRecord}) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddRecordScreen(initialRecord: initialRecord),
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
  late DateTime _selectedDateTime;
  bool _isCustomDateTime = false;
  String _amountExpression = '0';
  bool _isCustomNameActive = false;
  bool _isInitialAmountState = false;
  final FocusNode _keyboardFocusNode = FocusNode();

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
    } else {
      _type = CategoryType.expense;
      _nameController = TextEditingController();
      _remarkController = TextEditingController();
      _selectedDateTime = DateTime.now();
      _isCustomDateTime = false;
      _amountExpression = '0';
      _isInitialAmountState = false;
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

    String current = _amountExpression.replaceAll(',', '');

    if (key == '⌫') {
      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
        if (current.isEmpty) {
          current = '0';
        }
      } else {
        current = '0';
      }
      setState(() {
        _amountExpression = current;
        _isInitialAmountState = false;
      });
      return;
    }

    if (key == '+' || key == '-') {
      if (current.endsWith('+') || current.endsWith('-')) {
        current = current.substring(0, current.length - 1) + key;
      } else {
        if (_hasPendingCalculation(current)) {
          final result = CurrencyFormat.parseExpression(current);
          current = CurrencyFormat.formatRaw(result) + key;
        } else {
          current += key;
        }
      }
      setState(() {
        _amountExpression = current;
        _isInitialAmountState = false;
      });
      return;
    }

    if (key == '.') {
      final segments = current.split(RegExp(r'[+\-]'));
      final lastSegment = segments.isNotEmpty ? segments.last : '';
      if (!lastSegment.contains('.')) {
        if (lastSegment.isEmpty) {
          current += '0.';
        } else {
          current += '.';
        }
        setState(() {
          _amountExpression = current;
          _isInitialAmountState = false;
        });
      }
      return;
    }

    // Numbers: 0..9
    if (current == '0' || _isInitialAmountState) {
      current = key;
    } else {
      final segments = current.split(RegExp(r'[+\-]'));
      final lastSegment = segments.isNotEmpty ? segments.last : '';
      if (lastSegment.contains('.')) {
        final decimals = lastSegment.split('.').last;
        if (decimals.length >= 2) {
          return;
        }
      }
      if (current.length < 16) {
        current += key;
      }
    }
    setState(() {
      _amountExpression = current;
      _isInitialAmountState = false;
    });
  }

  bool _hasPendingCalculation(String text) {
    final clean = text.trim();
    if (clean.length < 2) return false;
    final body = clean.startsWith('-') ? clean.substring(1) : clean;
    return body.contains('+') || body.contains('-');
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final logicalKey = event.logicalKey;

    if (logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
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

    if (widget.initialRecord != null) {
      final updated = widget.initialRecord!.copyWith(
        amount: amount,
        type: _type,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        name: name,
        dateTime: recordTime,
        remark: _remarkController.text.trim().isNotEmpty
            ? _remarkController.text.trim()
            : null,
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
        remark: _remarkController.text.trim().isNotEmpty
            ? _remarkController.text.trim()
            : null,
      );
    }
    return true;
  }

  void _onDoneSave() async {
    final success = await _saveRecord();
    if (success && mounted) {
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
      });
    }
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

    final currentPresets = _selectedCategory != null
        ? catProvider.getPresetsForCategory(_selectedCategory!.id)
        : <PresetItem>[];

    final accentColor = _type == CategoryType.expense
        ? AppColors.expense
        : AppColors.income;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
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
      body: Center(
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
    final hasOp = clean.contains('+') || (clean.contains('-') && !clean.startsWith('-'));
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
            onChanged: (text) {
              setState(() {
                _isCustomNameActive = true;
              });
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
            decoration: InputDecoration(
              isDense: true,
              hintText: '添加备注 (选填)...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
              prefixIcon: const Icon(Icons.notes_rounded, size: 18),
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
