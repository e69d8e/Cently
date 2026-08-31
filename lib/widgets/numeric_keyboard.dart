import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/currency_format.dart';

class NumericKeyboard extends StatelessWidget {
  final String amountText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback? onSaveAndContinue;
  final Color accentColor;
  final bool isEditing;
  final bool isInitialState;

  const NumericKeyboard({
    super.key,
    required this.amountText,
    required this.onChanged,
    required this.onSave,
    this.onSaveAndContinue,
    this.accentColor = AppColors.primary,
    this.isEditing = false,
    this.isInitialState = false,
  });

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();
    final updated = CurrencyFormat.processKeyInput(
      currentExpression: amountText,
      key: key,
      isInitialState: isInitialState,
    );
    onChanged(updated);
  }

  void _onDone() {
    final clean = amountText.replaceAll(',', '');
    if (CurrencyFormat.hasPendingCalculation(clean)) {
      final res = CurrencyFormat.parseExpression(clean);
      onChanged(CurrencyFormat.formatRaw(res));
    }
    onSave();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyBg = isDark ? AppColors.surfaceMutedDark : AppColors.surfaceLight;
    final keyBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final actionBg = isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceMutedLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildKey('1', keyBg, keyBorder, textColor),
                _buildKey('2', keyBg, keyBorder, textColor),
                _buildKey('3', keyBg, keyBorder, textColor),
                _buildKey('+', keyBg, keyBorder, accentColor, isSpecial: true),
              ],
            ),
            Row(
              children: [
                _buildKey('4', keyBg, keyBorder, textColor),
                _buildKey('5', keyBg, keyBorder, textColor),
                _buildKey('6', keyBg, keyBorder, textColor),
                _buildKey('-', keyBg, keyBorder, accentColor, isSpecial: true),
              ],
            ),
            Row(
              children: [
                _buildKey('7', keyBg, keyBorder, textColor),
                _buildKey('8', keyBg, keyBorder, textColor),
                _buildKey('9', keyBg, keyBorder, textColor),
                _buildKey('⌫', keyBg, keyBorder, textColor, isSpecial: true),
              ],
            ),
            Row(
              children: [
                _buildKey('.', keyBg, keyBorder, textColor),
                _buildKey('0', keyBg, keyBorder, textColor),
                if (isEditing)
                  _buildActionKey(
                    '清空',
                    actionBg,
                    isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    () => onChanged('0'),
                    subtitle: '归零',
                  )
                else
                  _buildActionKey(
                    '再记',
                    actionBg,
                    accentColor,
                    onSaveAndContinue ?? () {},
                    subtitle: '连续',
                  ),
                _buildActionKey(
                  '完成',
                  accentColor,
                  Colors.white,
                  _onDone,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(
    String label,
    Color bg,
    Color border,
    Color textCol, {
    bool isSpecial = false,
  }) {
    return Expanded(
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(4),
        child: Material(
          color: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border, width: 0.8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onKeyPress(label),
            onLongPress: label == '⌫'
                ? () {
                    HapticFeedback.mediumImpact();
                    onChanged('0');
                  }
                : null,
            child: Center(
              child: label == '⌫'
                  ? Icon(Icons.backspace_outlined, size: 20, color: textCol)
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: isSpecial ? 20 : 22,
                        fontWeight: isSpecial ? FontWeight.w600 : FontWeight.w500,
                        color: textCol,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(
    String label,
    Color bg,
    Color textCol,
    VoidCallback onTap, {
    bool isPrimary = false,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(4),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Center(
              child: subtitle != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textCol,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: textCol.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textCol,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
