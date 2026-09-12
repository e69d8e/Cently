import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_format_helper.dart';
import '../../widgets/month_picker_dialog.dart';

enum ExportScope { all, month }

class DataBackupScreen extends StatefulWidget {
  final int initialTabIndex;

  const DataBackupScreen({super.key, this.initialTabIndex = 0});

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataBackupScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importTextController = TextEditingController();
  bool _overwriteMode = false;
  bool _isImporting = false;

  ExportScope _exportScope = ExportScope.all;
  DateTime _selectedExportMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _totalTransactionsCount;
  int? _monthTransactionsCount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final total = await txProvider.getTotalTransactionsCount();
    final monthCount = await txProvider.getTransactionsCountByMonth(_selectedExportMonth);
    if (mounted) {
      setState(() {
        _totalTransactionsCount = total;
        _monthTransactionsCount = monthCount;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importTextController.dispose();
    super.dispose();
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _importTextController.text = data.text!;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已从剪贴板粘贴备份内容'),
            duration: Duration(milliseconds: 1200),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('剪贴板中没有文本内容'),
            duration: Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }

  Future<void> _pickJsonFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final content = utf8.decode(bytes);

        if (content.trim().isNotEmpty) {
          setState(() {
            _importTextController.text = content;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已载入文件「${file.name}」'),
                duration: const Duration(milliseconds: 1500),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取备份文件失败: $e')),
        );
      }
    }
  }

  void _executeImport() async {
    final text = _importTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先粘贴或选取 JSON 备份数据')),
      );
      return;
    }

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);

    final preview = txProvider.parseBackupPreview(text);
    if (!preview.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(preview.errorMessage ?? '备份数据解析失败')),
      );
      return;
    }

    if (_overwriteMode) {
      final isSingle = preview.isSingleMonth && preview.targetMonth != null;
      final scopeTitle = isSingle ? '「${preview.targetMonth}」单月数据' : '完整全量数据';
      final scopeDetail = isSingle
          ? '您选择了「完全覆盖模式」。检测到此备份为 $scopeTitle，系统将仅清空并覆盖该月份的账单流水，其他月份历史记录与分类配置将完整保留。'
          : '您选择了「完全覆盖模式」，这将清除当前设备中的所有分类、预设名称和记账记录，并完全恢复为备份内容。此操作无法撤销！';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('确认覆盖$scopeTitle？'),
          content: Text(scopeDetail),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认覆盖'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {
      _isImporting = true;
    });

    final result = await txProvider.importFromJson(text, overwrite: _overwriteMode);
    await catProvider.loadData();
    await _loadCounts();

    setState(() {
      _isImporting = false;
    });

    if (!mounted) return;

    if (result.isSuccess) {
      final isSingle = preview.isSingleMonth && preview.targetMonth != null;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.income),
              SizedBox(width: 8),
              Text('导入成功'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• 记账流水：${result.transactionsCount} 条'),
              Text('• 分类类型：${result.categoriesCount} 个'),
              Text('• 预设名称：${result.presetsCount} 个'),
              if (isSingle)
                Text('• 备份范围：${preview.targetMonth} (单月数据)'),
              const SizedBox(height: 10),
              Text(
                _overwriteMode
                    ? (isSingle ? '已覆盖恢复 ${preview.targetMonth} 流水，其他月份已保留。' : '数据已全部覆盖还原。')
                    : '数据已成功合并追加。',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: ${result.message}')),
      );
    }
  }

  void _showPreviewDialog(String title, String content) {
    const int maxDisplayChars = 15000;
    final bool isTruncated = content.length > maxDisplayChars;
    final String displayContent = isTruncated
        ? '${content.substring(0, maxDisplayChars)}\n\n...[数据量较多已截断预览，共计 ${content.length} 字符。点击下方「复制内容」将复制完整数据]...'
        : content;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 280,
          child: SingleChildScrollView(
            child: SelectableText(
              displayContent,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('复制内容'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制完整内容到剪贴板')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份与迁移'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
          tabs: const [
            Tab(text: '导出备份'),
            Tab(text: '导入恢复'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExportTab(isDark),
          _buildImportTab(isDark),
        ],
      ),
    );
  }

  // ===================== EXPORT TAB =====================

  Widget _buildExportTab(bool isDark) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    final isMonthScope = _exportScope == ExportScope.month;
    final targetMonth = isMonthScope ? _selectedExportMonth : null;
    final currentTxCount = isMonthScope ? _monthTransactionsCount : _totalTransactionsCount;
    final countLabel = isMonthScope ? '单月流水' : '全部流水';
    final scopeDesc = isMonthScope
        ? '${DateFormatHelper.formatMonth(_selectedExportMonth)} 流水'
        : '全量历史记录';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Export Scope Selector Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '导出范围设置',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (isMonthScope)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          final picked = await MonthPickerDialog.show(context, _selectedExportMonth);
                          if (picked != null) {
                            setState(() => _selectedExportMonth = picked);
                            _loadCounts();
                          }
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                        label: Text(
                          DateFormatHelper.formatMonth(_selectedExportMonth),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<ExportScope>(
                  segments: const [
                    ButtonSegment(
                      value: ExportScope.all,
                      label: Text('全部历史数据'),
                      icon: Icon(Icons.all_inclusive_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ExportScope.month,
                      label: Text('指定单月数据'),
                      icon: Icon(Icons.date_range_rounded, size: 16),
                    ),
                  ],
                  selected: {_exportScope},
                  onSelectionChanged: (set) {
                    setState(() => _exportScope = set.first);
                    _loadCounts();
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. JSON Full Backup Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.backup_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMonthScope ? '单月数据备份 (JSON)' : '完整数据备份 (JSON)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMonthScope ? '包含分类配置与指定月份记账流水' : '包含所有分类、预设名称与全部流水记录',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBadge('分类数', '${catProvider.categories.length} 个'),
                      _buildStatBadge('预设名称', '${catProvider.presetItemsMap.values.fold(0, (sum, l) => sum + l.length)} 个'),
                      _buildStatBadge(countLabel, currentTxCount != null ? '$currentTxCount 笔' : '...'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        icon: const Icon(Icons.save_alt_rounded, size: 16),
                        label: const Text('保存文件'),
                        onPressed: () async {
                          try {
                            final uri = await txProvider.saveJsonFile(month: targetMonth);
                            if (uri != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('已成功保存 JSON 备份文件'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('保存文件失败: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('复制备份'),
                        onPressed: () async {
                          final json = await txProvider.exportAsJson(month: targetMonth);
                          await Clipboard.setData(ClipboardData(text: json));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isMonthScope ? '已复制单月 JSON 备份到剪贴板' : '已复制完整 JSON 备份到剪贴板'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      tooltip: '系统分享',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      onPressed: () async {
                        try {
                          await txProvider.shareJsonFile(month: targetMonth);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('分享失败: $e')),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      tooltip: '预览数据',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      onPressed: () async {
                        final json = await txProvider.exportAsJson(month: targetMonth);
                        if (mounted) _showPreviewDialog('JSON 备份内容', json);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. CSV Export Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.table_chart_rounded, color: AppColors.income, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMonthScope ? '单月表格明细 (CSV)' : 'Excel / 表格明细 (CSV)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMonthScope ? '导出选定月份明细，支持在 Excel / Numbers 打开' : '导出全量历史流水，支持在 Excel / Numbers 打开',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBadge('导出范围', scopeDesc),
                      _buildStatBadge('流水笔数', currentTxCount != null ? '$currentTxCount 笔' : '...'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.income,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        icon: const Icon(Icons.save_alt_rounded, size: 16),
                        label: const Text('保存文件'),
                        onPressed: () async {
                          try {
                            final uri = await txProvider.saveCsvFile(month: targetMonth);
                            if (uri != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('已成功保存 CSV 表格文件'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('保存文件失败: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('复制表格'),
                        onPressed: () async {
                          final csv = await txProvider.exportAsCsv(month: targetMonth);
                          await Clipboard.setData(ClipboardData(text: csv));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isMonthScope ? '已复制单月 CSV 表格到剪贴板' : '已复制 CSV 表格数据到剪贴板'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      tooltip: '系统分享',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      onPressed: () async {
                        try {
                          await txProvider.shareCsvFile(month: targetMonth);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('分享失败: $e')),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      tooltip: '预览表格',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      onPressed: () async {
                        final csv = await txProvider.exportAsCsv(month: targetMonth);
                        if (mounted) _showPreviewDialog('CSV 表格明细', csv);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  // ===================== IMPORT TAB =====================

  Widget _buildImportTab(bool isDark) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final text = _importTextController.text.trim();
    final preview = text.isNotEmpty ? txProvider.parseBackupPreview(text) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Source Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '备份数据来源',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (_importTextController.text.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                onPressed: () => setState(() => _importTextController.clear()),
                icon: const Icon(Icons.clear, size: 14),
                label: const Text('清空内容'),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Source Action Buttons Row: File Picker + Clipboard
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: _pickJsonFile,
                icon: const Icon(Icons.file_open_outlined, size: 16),
                label: const Text('选取文件'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('剪贴板粘贴'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _importTextController,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: '{\n  "app": "Cently",\n  "version": "1.0.0",\n  "categories": [...],\n  "transactions": [...]\n}',
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),

        const SizedBox(height: 16),

        // Live Validation Card
        if (preview != null)
          Card(
            color: preview.isValid
                ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : AppColors.incomeBg)
                : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : AppColors.expenseBg),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        preview.isValid ? Icons.verified_rounded : Icons.error_outline_rounded,
                        color: preview.isValid ? AppColors.income : AppColors.expense,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        preview.isValid ? '备份数据解析成功' : '备份数据格式异常',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: preview.isValid ? AppColors.income : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (preview.isValid) ...[
                    if (preview.isSingleMonth && preview.targetMonth != null)
                      Text('• 备份类型: 单月备份 (${preview.targetMonth})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.income))
                    else
                      const Text('• 备份类型: 全量历史备份',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('• 包含分类: ${preview.categoriesCount} 个', style: const TextStyle(fontSize: 13)),
                    Text('• 包含预设名称: ${preview.presetsCount} 个', style: const TextStyle(fontSize: 13)),
                    Text('• 包含记账流水: ${preview.transactionsCount} 笔', style: const TextStyle(fontSize: 13)),
                    if (preview.exportTime != null)
                      Text('• 备份生成时间: ${preview.exportTime}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ] else ...[
                    Text(
                      preview.errorMessage ?? '无法识别有效备份内容',
                      style: const TextStyle(fontSize: 13, color: AppColors.expense),
                    ),
                  ],
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Mode Choice Card
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    '导入方式',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _overwriteMode = false),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          !_overwriteMode ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: !_overwriteMode ? AppColors.primary : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '合并追加导入 (推荐)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '保留当前已有数据，自动合并分类和预设，并追加新的记录',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                InkWell(
                  onTap: () => setState(() => _overwriteMode = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          _overwriteMode ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: _overwriteMode ? AppColors.expense : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '完全覆盖恢复 (危险)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.expense,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '清空当前设备所有记录，完全还原为备份文件的状态',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action CTA
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _overwriteMode ? AppColors.expense : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: (_isImporting || (preview != null && !preview.isValid))
                ? null
                : _executeImport,
            icon: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_upload_rounded),
            label: Text(
              _isImporting
                  ? '正在导入数据...'
                  : (_overwriteMode ? '执行覆盖恢复' : '确认导入数据'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}
