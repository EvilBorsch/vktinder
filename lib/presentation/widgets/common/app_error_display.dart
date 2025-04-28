import 'package:flutter/material.dart';
import 'package:vktinder/core/utils/ui_constants.dart';

/// A standardized error display widget for consistent error states across the app
class AppErrorDisplay extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// The title of the error (defaults to "Ошибка")
  final String title;
  
  /// The icon to display (defaults to error icon)
  final IconData icon;
  
  /// The color of the icon (defaults to red)
  final Color iconColor;
  
  /// The action button text (if null, no button is shown)
  final String? actionText;
  
  /// The callback when the action button is pressed
  final VoidCallback? onActionPressed;
  
  /// The icon for the action button
  final IconData? actionIcon;
  
  /// Creates a standard error display
  const AppErrorDisplay({
    Key? key,
    required this.message,
    this.title = 'Ошибка',
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
    this.actionText,
    this.onActionPressed,
    this.actionIcon,
  }) : super(key: key);
  
  /// Creates a warning display
  const AppErrorDisplay.warning({
    Key? key,
    required String message,
    String title = 'Внимание',
    String? actionText,
    VoidCallback? onActionPressed,
    IconData? actionIcon,
  }) : this(
    key: key,
    message: message,
    title: title,
    icon: Icons.warning_amber_rounded,
    iconColor: Colors.orange,
    actionText: actionText,
    onActionPressed: onActionPressed,
    actionIcon: actionIcon,
  );
  
  /// Creates an info display
  const AppErrorDisplay.info({
    Key? key,
    required String message,
    String title = 'Информация',
    String? actionText,
    VoidCallback? onActionPressed,
    IconData? actionIcon,
  }) : this(
    key: key,
    message: message,
    title: title,
    icon: Icons.info_outline,
    iconColor: Colors.blue,
    actionText: actionText,
    onActionPressed: onActionPressed,
    actionIcon: actionIcon,
  );
  
  /// Creates an empty state display
  const AppErrorDisplay.empty({
    Key? key,
    String message = 'Нет данных для отображения',
    String title = 'Пусто',
    String? actionText,
    VoidCallback? onActionPressed,
    IconData? actionIcon,
  }) : this(
    key: key,
    message: message,
    title: title,
    icon: Icons.inbox_outlined,
    iconColor: Colors.grey,
    actionText: actionText,
    onActionPressed: onActionPressed,
    actionIcon: actionIcon,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingL),
        child: Card(
          elevation: UIConstants.elevationM,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
          ),
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: UIConstants.iconSizeXL, color: iconColor),
                const SizedBox(height: UIConstants.paddingM),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: UIConstants.textSizeXL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UIConstants.paddingS),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: UIConstants.textSizeM,
                    height: 1.4,
                  ),
                ),
                if (actionText != null && onActionPressed != null) ...[
                  const SizedBox(height: UIConstants.paddingL),
                  ElevatedButton.icon(
                    onPressed: onActionPressed,
                    icon: Icon(actionIcon ?? Icons.refresh),
                    label: Text(actionText!),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.paddingL,
                        vertical: UIConstants.paddingM,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}