import 'package:flutter/material.dart';

class NotificationService {
  void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message,
      Icons.check_circle_rounded,
      const Color(0xFF4CAF50),
      duration,
    );
  }

  void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message,
      Icons.error_rounded,
      const Color(0xFFE74C3C),
      duration,
    );
  }

  void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message,
      Icons.warning_rounded,
      const Color(0xFFFFA500),
      duration,
    );
  }

  void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message,
      Icons.info_rounded,
      const Color(0xFF2196F3),
      duration,
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    IconData icon,
    Color backgroundColor,
    Duration duration,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
