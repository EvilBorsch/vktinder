import 'package:flutter/material.dart';
import 'package:vktinder/core/utils/ui_constants.dart';

/// A standardized loading indicator for consistent loading states across the app
class AppLoadingIndicator extends StatelessWidget {
  /// The size of the loading indicator
  final double size;
  
  /// The stroke width of the loading indicator
  final double strokeWidth;
  
  /// The color of the loading indicator (uses primary color if null)
  final Color? color;
  
  /// Whether to show a label below the indicator
  final bool showLabel;
  
  /// The label text to display (defaults to "Загрузка...")
  final String labelText;
  
  /// Creates a standard loading indicator
  const AppLoadingIndicator({
    Key? key,
    this.size = 24.0,
    this.strokeWidth = 2.0,
    this.color,
    this.showLabel = false,
    this.labelText = 'Загрузка...',
  }) : super(key: key);
  
  /// Creates a small loading indicator (16x16)
  const AppLoadingIndicator.small({
    Key? key,
    Color? color,
    bool showLabel = false,
    String labelText = 'Загрузка...',
  }) : this(
    key: key,
    size: 16.0,
    strokeWidth: 1.5,
    color: color,
    showLabel: showLabel,
    labelText: labelText,
  );
  
  /// Creates a large loading indicator (48x48)
  const AppLoadingIndicator.large({
    Key? key,
    Color? color,
    bool showLabel = true,
    String labelText = 'Загрузка...',
  }) : this(
    key: key,
    size: 48.0,
    strokeWidth: 3.0,
    color: color,
    showLabel: showLabel,
    labelText: labelText,
  );
  
  /// Creates a full-screen loading indicator with a semi-transparent background
  static Widget fullScreen({
    Color? color,
    String labelText = 'Загрузка...',
    Color? backgroundColor,
  }) {
    return Container(
      color: backgroundColor ?? Colors.black.withOpacity(0.3),
      child: Center(
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
                AppLoadingIndicator.large(
                  color: color,
                  showLabel: true,
                  labelText: labelText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Creates an inline loading indicator with text
  static Widget inline({
    required String text,
    Color? color,
    double size = 16.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: size / 8,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: UIConstants.paddingS),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingIndicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null 
            ? AlwaysStoppedAnimation<Color>(color!)
            : AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
      ),
    );
    
    if (!showLabel) {
      return loadingIndicator;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        loadingIndicator,
        const SizedBox(height: UIConstants.paddingS),
        Text(
          labelText,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontSize: UIConstants.textSizeM,
          ),
        ),
      ],
    );
  }
}