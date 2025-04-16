// --- File: lib/presentation/controllers/home_controller.dart ---
// lib/presentation/controllers/home_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart'; // ActionLike, ActionDislike
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';
import 'dart:async'; // For Timer

class HomeController extends GetxController {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository =
      Get.find<GroupUsersRepository>();
  final StatisticsController _statisticsController =
      Get.find<StatisticsController>();

  final RxList<VKGroupUser> users = <VKGroupUser>[].obs;
  final RxBool isLoading = true.obs; // Indicates initial load or forced reload
  final RxBool isSendingMessage =
      false.obs; // Global flag for ANY send operation
  final RxnString errorMessage = RxnString();
  final RxBool isLoadingMore = false.obs; // Indicates background loading

  String get vkToken => _settingsController.vkToken;

  String get defaultMessage => _settingsController.defaultMessage;

  bool get hasVkToken => vkToken.isNotEmpty;

  bool get hasGroupsConfigured => _settingsController.groupUrls.isNotEmpty;

  // Throttling/Debouncing API calls
  Timer? _apiCallTimer;
  bool _isApiCallScheduledOrRunning = false;
  final Duration _apiCallDebounceDuration = const Duration(milliseconds: 750);
  final Duration _loadMoreDelay = const Duration(milliseconds: 200);

  @override
  void onInit() {
    super.onInit();
    print("HomeController onInit");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("HomeController: First frame callback - initiating load.");
      _scheduleLoad(forceReload: true, delay: Duration.zero);
    });

    debounce(
      _settingsController.settingsChanged,
      (_) {
        print(
            "Settings changed, debounced event triggered. Scheduling reload.");
        _scheduleLoad(forceReload: true, delay: _apiCallDebounceDuration);
      },
      time: _apiCallDebounceDuration,
    );
  }

  @override
  void onClose() {
    _apiCallTimer?.cancel();
    super.onClose();
  }

  void _scheduleLoad(
      {required bool forceReload, Duration delay = Duration.zero}) {
    if (_isApiCallScheduledOrRunning && !forceReload) {
      print(
          "Load schedule requested, but already scheduled/running. Skipping.");
      return;
    }

    _apiCallTimer?.cancel();
    _isApiCallScheduledOrRunning = true;

    print("Scheduling API load (forceReload: $forceReload) with delay: $delay");

    _apiCallTimer = Timer(delay, () {
      print(
          "Timer fired. Executing loadCardsFromAPI (forceReload: $forceReload)");
      // Flag reset will happen inside loadCardsFromAPI's finally block now
      // _isApiCallScheduledOrRunning = false; // Removed from here
      loadCardsFromAPI(forceReload: forceReload).catchError((e) {
        // Added catchError here for safety
        print("Error during scheduled loadCardsFromAPI: $e");
      }).whenComplete(() {
        // Ensure flag is false after call, regardless of success/error
        _isApiCallScheduledOrRunning = false;
        print("Scheduled load completed (flag reset).");
      });
    });
  }

  Future<void> loadCardsFromAPI({required bool forceReload}) async {
    // --- Start State Management ---
    if ((isLoading.value || isLoadingMore.value) &&
        !forceReload &&
        !_isApiCallScheduledOrRunning) {
      // If already loading (and not forced) AND a load isn't explicitly scheduled, skip.
      print(
          "loadCardsFromAPI called but already loading state active and no new schedule. Skipping.");
      return;
    }
    if (forceReload && isLoadingMore.value) {
      print("Forcing reload, canceling ongoing background load state.");
      isLoadingMore.value = false;
    }
    _isApiCallScheduledOrRunning = true; // Mark as running *now*

    if (!hasVkToken) {
      users.clear();
      errorMessage.value = "Необходимо указать VK токен в настройках.";
      isLoading.value = false;
      isLoadingMore.value = false;
      _isApiCallScheduledOrRunning = false; // Reset all
      print("Load aborted: VK Token missing.");
      return;
    }
    if (!hasGroupsConfigured) {
      users.clear();
      errorMessage.value =
          "Необходимо добавить хотя бы одну группу в настройках.";
      isLoading.value = false;
      isLoadingMore.value = false;
      _isApiCallScheduledOrRunning = false; // Reset all
      print("Load aborted: No groups configured.");
      return;
    }

    if (forceReload) {
      print("Setting state for forced reload: isLoading=true");
      users.clear();
      isLoading.value = true;
      isLoadingMore.value = false;
      errorMessage.value = null;
    } else {
      if (users.length >= 10) {
        print("Skipping load more: Have enough cards (${users.length}).");
        _isApiCallScheduledOrRunning = false; // Reset flag as we are skipping
        return;
      }
      print("Setting state for loading more: isLoadingMore=true");
      isLoadingMore.value = true;
      isLoading.value = false;
    }
    // --- End State Management ---

    bool success = false;
    List<VKGroupUser> uniqueNewUsers = [];

    try {
      print("Calling repository.getUsers...");
      final skippedIds = _statisticsController.skippedIdsSet;
      final fetchedUsers =
          await _groupUsersRepository.getUsers(vkToken, skippedIds.toList());
      success = true;
      print("Repository returned ${fetchedUsers.length} users.");

      final existingUserIds = users.map((u) => u.userID).toSet();
      uniqueNewUsers = fetchedUsers
          .where((user) => !existingUserIds.contains(user.userID))
          .toList();

      print("${uniqueNewUsers.length} unique new users found.");
      if (uniqueNewUsers.isNotEmpty) {
        users.addAll(uniqueNewUsers);
        errorMessage.value = null;
        print("Added new users. Total cards: ${users.length}");
      }
      if (users.isEmpty && success) {
        print("Users list is empty after a successful fetch.");
        errorMessage.value =
            "Не найдено новых пользователей по заданным критериям.\nПопробуйте изменить фильтры в настройках.";
      }
    } catch (e) {
      success = false;
      print("Error caught during repository.getUsers: $e");
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Ошибка загрузки',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM, /* ... */
      );
      if (users.isEmpty) {
        errorMessage.value = "Ошибка при загрузке: $errorMsg";
        print("Setting persistent error message: ${errorMessage.value}");
      } else {
        print("API error occurred, but keeping existing users displayed.");
      }
    } finally {
      print("Load cycle finishing. Resetting flags.");
      // CRITICAL: Reset all relevant flags
      isLoading.value = false;
      isLoadingMore.value = false;
      _isApiCallScheduledOrRunning = false; // Reset running flag
      print(
          "Final state: isLoading=${isLoading.value}, isLoadingMore=${isLoadingMore.value}, isScheduled=${_isApiCallScheduledOrRunning}, users=${users.length}, error='${errorMessage.value}'");
    }
  }

  Future<void> dismissCard(DismissDirection direction) async {
    if (users.isEmpty) return;
    if (isLoading.value || isLoadingMore.value)
      return; // Don't dismiss if loading

    final dismissedUser = users.first;
    users.removeAt(0);

    final groupURL = dismissedUser.groupURL ?? "unknown_group";
    final actionType =
        direction == DismissDirection.startToEnd ? ActionLike : ActionDislike;

    print(
        "${actionType == ActionLike ? 'Liking' : 'Disliking'} user: ${dismissedUser.userID}");
    await _statisticsController.addUserAction(
        groupURL, dismissedUser, actionType);

    if (actionType == ActionLike) {
      showMessageDialogForUser(dismissedUser);
    }

    // Schedule a *potential* load more check
    _scheduleLoad(forceReload: false, delay: _loadMoreDelay);
  }

  // --- sendVKMessage: Removed _isSendingMessageLocal ---
  Future<bool> sendVKMessage(String userId, String message) async {
    // --- Check the global RxBool flag ---
    if (isSendingMessage.value) {
      print("Send message requested, but already sending. Skipping.");
      return false; // Indicate send was not attempted
    }

    // Basic checks
    if (userId.isEmpty || !hasVkToken) {
      Get.snackbar('Ошибка', 'Не указан ID или токен.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (message.isEmpty) {
      Get.snackbar('Ошибка', 'Сообщение не может быть пустым.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    bool success = false;
    try {
      // --- Set global sending flag ---
      isSendingMessage.value = true;
      print("Setting isSendingMessage = true");

      success =
          await _groupUsersRepository.sendMessage(vkToken, userId, message);

      if (success) {
        Get.snackbar('Успех', 'Сообщение отправлено.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
            margin: const EdgeInsets.all(8),
            borderRadius: 10,
            duration: const Duration(seconds: 2));
      }
      // Failure snackbars are handled by the provider/repo
    } catch (e) {
      print("Error sending message from controller: $e");
      // Show generic snackbar here only if repo didn't show one
      // (Though currently repo shows snackbars on specific errors)
      Get.snackbar('Ошибка', 'Не удалось отправить сообщение.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          margin: const EdgeInsets.all(8),
          borderRadius: 10);
      success = false; // Ensure success is false on catch
    } finally {
      // --- Reset global sending flag ---
      isSendingMessage.value = false;
      print("Setting isSendingMessage = false");
    }
    return success;
  }

  void showMessageDialogForUser(VKGroupUser targetUser) {
    final TextEditingController messageController =
        TextEditingController(text: defaultMessage);
    // Local RxBool for the dialog's button state is correct and useful here
    final RxBool isDialogSending = false.obs;

    Get.dialog(
      AlertDialog(
          title: const Text('Отправить сообщение'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            RichText(
                text: TextSpan(
                    style:
                        TextStyle(color: Get.theme.textTheme.bodyMedium?.color),
                    children: [
                  const TextSpan(text: 'Кому: '),
                  TextSpan(
                      text: '${targetUser.name} ${targetUser.surname}',
                      style: const TextStyle(fontWeight: FontWeight.bold))
                ])),
            const SizedBox(height: 16),
            _buildTextField(
                controller: messageController,
                labelText: 'Сообщение',
                hintText: 'Введите ваше сообщение...',
                icon: Icons.message_outlined,
                maxLines: 4)
          ]),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: const Text('Отмена')),
            // Obx listens to the local isDialogSending
            Obx(() => ElevatedButton.icon(
                // Disable button based on the local dialog state
                onPressed: isDialogSending.value
                    ? null
                    : () async {
                        final message = messageController.text.trim();
                        if (message.isEmpty) {
                          Get.snackbar(
                              'Ошибка', 'Сообщение не может быть пустым.',
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }

                        isDialogSending.value =
                            true; // Update local dialog state
                        Get.back(); // Close dialog before sending

                        // Call the main send function which handles the global state
                        await sendVKMessage(targetUser.userID, message);

                        // No need to reset isDialogSending here as the dialog is closed
                      },
                icon: isDialogSending.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 18),
                label:
                    Text(isDialogSending.value ? 'Отправка...' : 'Отправить')))
          ]),
      barrierDismissible:
          !isDialogSending.value, // Prevent dismiss based on local dialog state
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String labelText,
      required String hintText,
      required IconData icon,
      int maxLines = 1}) {
    // ... Text Field helper remains the same ...
    return TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            labelText: labelText,
            hintText: hintText,
            filled: true,
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Get.theme.primaryColor, width: 1.5))));
  }
}
