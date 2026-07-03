import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Ya, lanjutkan',
  String cancelText = 'Batal',
  bool isDanger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      title: Text(title, style: AppText.h3),
      content: Text(message, style: AppText.bodyMuted),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText, style: const TextStyle(color: AppTheme.warmGray)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: isDanger ? AppTheme.error : AppTheme.terracotta,
          ),
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDanger ? AppTheme.error : AppTheme.terracotta,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: AppTheme.white)),
      backgroundColor: isError ? AppTheme.error : AppTheme.sage,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ),
  );
}
