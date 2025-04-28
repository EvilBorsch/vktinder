import 'package:get/get.dart';
import 'package:vktinder/core/utils/snackbar_utils.dart';

/// Base controller class with common functionality for all controllers
abstract class BaseController extends GetxController {
  /// Loading state
  final RxBool isLoading = false.obs;

  /// Error message
  final RxnString errorMessage = RxnString();

  /// Whether the controller has been disposed
  bool get isDisposed => !GetInstance().isRegistered<BaseController>(tag: runtimeType.toString());

  @override
  void onInit() {
    super.onInit();
    // Initialize controller
    _initialize();
  }

  @override
  void onClose() {
    // Clean up resources
    _cleanUp();
    super.onClose();
  }

  /// Initialize the controller (to be implemented by subclasses)
  void _initialize() {}

  /// Clean up resources (to be implemented by subclasses)
  void _cleanUp() {}

  /// Show loading state
  void showLoading() {
    if (!isDisposed) {
      isLoading.value = true;
    }
  }

  /// Hide loading state
  void hideLoading() {
    if (!isDisposed) {
      isLoading.value = false;
    }
  }

  /// Set error message
  void setError(dynamic message) {
    if (!isDisposed) {
      errorMessage.value = message.toString();
    }
  }

  /// Clear error message
  void clearError() {
    if (!isDisposed) {
      errorMessage.value = null;
    }
  }

  /// Show error snackbar
  void showErrorSnackbar(dynamic message) {
    if (!isDisposed) {
      SnackbarUtils.showError(message.toString());
    }
  }

  /// Show success snackbar
  void showSuccessSnackbar(dynamic message) {
    if (!isDisposed) {
      SnackbarUtils.showSuccess(message.toString());
    }
  }

  /// Show warning snackbar
  void showWarningSnackbar(dynamic message) {
    if (!isDisposed) {
      SnackbarUtils.showWarning(message.toString());
    }
  }

  /// Show info snackbar
  void showInfoSnackbar(dynamic message) {
    if (!isDisposed) {
      SnackbarUtils.showInfo(message.toString());
    }
  }

  /// Execute an async operation with loading state and error handling
  Future<T?> executeWithLoading<T>(
    Future<T> Function() operation, {
    bool showLoadingState = true,
    bool shouldShowErrorSnackbar = true,
    String? loadingMessage,
    String? errorMessage,
    String? successMessage,
    bool clearErrorOnSuccess = true,
  }) async {
    if (showLoadingState) {
      showLoading();
    }

    try {
      final result = await operation();

      if (!isDisposed) {
        if (clearErrorOnSuccess) {
          clearError();
        }

        if (successMessage != null) {
          showSuccessSnackbar(successMessage);
        }
      }

      return result;
    } catch (e) {
      if (!isDisposed) {
        final errorMsg = errorMessage ?? e.toString();
        setError(errorMsg);

        if (shouldShowErrorSnackbar) {
          showErrorSnackbar(errorMsg);
        }
      }
      return null;
    } finally {
      if (!isDisposed && showLoadingState) {
        hideLoading();
      }
    }
  }
}
