import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/core/utils/ui_constants.dart';

/// Utility class for displaying consistent snackbars across the app
class SnackbarUtils {
  /// Shows a success snackbar with the specified message
  static void showSuccess(dynamic message, {
    String? title,
    SnackPosition position = SnackPosition.TOP,
    Duration? duration,
    Widget? icon,
  }) {
    Get.snackbar(
      title ?? 'Успех',
      message.toString(),
      snackPosition: position,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
      margin: const EdgeInsets.all(UIConstants.paddingS),
      borderRadius: UIConstants.borderRadiusM,
      duration: duration ?? UIConstants.snackbarShort,
      icon: icon ?? const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  /// Shows an error snackbar with the specified message
  static void showError(dynamic message, {
    String? title,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration? duration,
    Widget? icon,
  }) {
    Get.snackbar(
      title ?? 'Ошибка',
      message.toString(),
      snackPosition: position,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      margin: const EdgeInsets.all(UIConstants.paddingS),
      borderRadius: UIConstants.borderRadiusM,
      duration: duration ?? UIConstants.snackbarLong,
      icon: icon ?? const Icon(Icons.error_outline, color: Colors.red),
    );
  }

  /// Shows a warning snackbar with the specified message
  static void showWarning(dynamic message, {
    String? title,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration? duration,
    Widget? icon,
  }) {
    Get.snackbar(
      title ?? 'Внимание',
      message.toString(),
      snackPosition: position,
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[900],
      margin: const EdgeInsets.all(UIConstants.paddingS),
      borderRadius: UIConstants.borderRadiusM,
      duration: duration ?? UIConstants.snackbarMedium,
      icon: icon ?? const Icon(Icons.warning_amber_rounded, color: Colors.orange),
    );
  }

  /// Shows an info snackbar with the specified message
  static void showInfo(dynamic message, {
    String? title,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration? duration,
    Widget? icon,
  }) {
    Get.snackbar(
      title ?? 'Информация',
      message.toString(),
      snackPosition: position,
      backgroundColor: Colors.blue[100],
      colorText: Colors.blue[900],
      margin: const EdgeInsets.all(UIConstants.paddingS),
      borderRadius: UIConstants.borderRadiusM,
      duration: duration ?? UIConstants.snackbarMedium,
      icon: icon ?? const Icon(Icons.info_outline, color: Colors.blue),
    );
  }
}
