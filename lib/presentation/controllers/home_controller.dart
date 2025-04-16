// --- File: lib/presentation/controllers/home_controller.dart ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';
import 'package:vktinder/data/providers/local_storage_provider.dart';
import 'dart:async';

class HomeController extends GetxController {
  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository = Get.find<GroupUsersRepository>();
  final StatisticsController _statisticsController = Get.find<StatisticsController>();
  final LocalStorageProvider _localStorageProvider = Get.find<LocalStorageProvider>();

  final RxList<VKGroupUser> users = <VKGroupUser>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxnString errorMessage = RxnString();

  final int _loadMoreThreshold = 5;

  Timer? _saveStackDebounceTimer;
  final Duration _saveStackDebounceDuration = const Duration(milliseconds: 600);

  Timer? _fetchDebounceTimer;
  final Duration _fetchDebounceDuration = const Duration(milliseconds: 500);

  String get vkToken => _settingsController.vkToken;
  String get defaultMessage => _settingsController.defaultMessage;
  bool get hasVkToken => vkToken.isNotEmpty;
  bool get hasGroupsConfigured => _settingsController.groupUrls.isNotEmpty;

  bool _justLoadedFromDisk = false;
  bool _isApiFetchInProgress = false;


  @override
  void onInit() {
    super.onInit();
    print("HomeController onInit");

    debounce<int>(
      _settingsController.settingsChanged,
          (_) {
        print("Settings changed, debounced event triggered. Clearing stack and forcing reload.");
        _fetchDebounceTimer?.cancel();
        _saveStackDebounceTimer?.cancel();
        _clearPersistedAndMemoryStack();
        _triggerApiFetch(isInitialLoad: true);
      },
      time: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("HomeController: First frame callback - initiating initial load sequence.");
      _initializeCardStack();
    });
  }

  @override
  void onClose() {
    _saveStackDebounceTimer?.cancel();
    _fetchDebounceTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeCardStack() async {
    print("Initializing card stack...");
    isLoading.value = true;
    errorMessage.value = null;
    users.clear();
    _isApiFetchInProgress = false;

    if (!hasVkToken) {
      errorMessage.value = "Необходимо указать VK токен в настройках.";
      isLoading.value = false;
      print("Initialization aborted: VK Token missing.");
      return;
    }
    if (!hasGroupsConfigured) {
      errorMessage.value = "Необходимо добавить хотя бы одну группу в настройках.";
      isLoading.value = false;
      print("Initialization aborted: No groups configured.");
      return;
    }

    List<VKGroupUser> persistedUsers = [];
    try {
      persistedUsers = await _localStorageProvider.loadPersistedCards();
    } catch (e) {
      print("Error loading persisted cards during init: $e");
      await _localStorageProvider.clearPersistedCards();
    }

    if (persistedUsers.isNotEmpty) {
      print("Loaded ${persistedUsers.length} users from persisted stack.");
      users.assignAll(persistedUsers);
      _justLoadedFromDisk = true;
      isLoading.value = false;
      _checkAndFetchMoreIfNeeded(delay: const Duration(milliseconds: 100));
    } else {
      print("No persisted stack found. Triggering initial API fetch.");
      await _triggerApiFetch(isInitialLoad: true);
    }

    if (isLoading.value && persistedUsers.isNotEmpty){
      isLoading.value = false;
    }
    print("Card stack initialization complete. Users: ${users.length}, Loading: ${isLoading.value}");
  }

  Future<void> loadCardsFromAPI({required bool forceReload}) async {
    if (!forceReload) {
      print("loadCardsFromAPI called without forceReload=true. Use the refresh button or let automatic fetching handle it.");
      return;
    }

    print("Force Reload Initiated.");
    _fetchDebounceTimer?.cancel();
    _saveStackDebounceTimer?.cancel();

    if (_isApiFetchInProgress) {
      print("Warning: Force reload triggered while another API fetch might be in progress.");
    }

    await _clearPersistedAndMemoryStack();
    await _triggerApiFetch(isInitialLoad: true);
  }

  Future<void> _triggerApiFetch({required bool isInitialLoad}) async {
    if (_isApiFetchInProgress) {
      print("API fetch triggered, but another fetch is already in progress. Skipping.");
      return;
    }

    if (!hasVkToken || !hasGroupsConfigured) {
      print("API fetch aborted: Token or Groups missing.");
      errorMessage.value = !hasVkToken
          ? "Необходимо указать VK токен в настройках."
          : "Необходимо добавить хотя бы одну группу в настройках.";
      isLoading.value = false;
      isLoadingMore.value = false;
      return;
    }

    _isApiFetchInProgress = true;

    if (isInitialLoad) {
      print("Setting state for initial/forced API fetch: isLoading=true");
      if (!isLoading.value) isLoading.value = true;
      if (isLoadingMore.value) isLoadingMore.value = false;
      errorMessage.value = null;
    } else {
      print("Setting state for background API fetch: isLoadingMore=true");
      if (!isLoadingMore.value) isLoadingMore.value = true;
      if (isLoading.value) isLoading.value = false;
    }

    try {
      final Set<String> skippedIds = _statisticsController.skippedIdsSet;
      print("Calling repository.getUsers... (Skipped IDs count: ${skippedIds.length})");

      // --- FIX: Convert Set to List before passing ---
      final fetchedUsers = await _groupUsersRepository.getUsers(vkToken, skippedIds.toList());
      print("Repository returned ${fetchedUsers.length} potential users.");

      // --- FIX: Check if controller is disposed using 'isClosed' property ---
      if (!isClosed) { // Check if controller is still mounted
        final existingUserIds = users.map((u) => u.userID).toSet();
        final uniqueNewUsers = fetchedUsers
            .where((user) => !existingUserIds.contains(user.userID))
            .toList();

        print("${uniqueNewUsers.length} unique new users received from API.");

        if (uniqueNewUsers.isNotEmpty) {
          users.addAll(uniqueNewUsers);
          if(errorMessage.value != null) errorMessage.value = null;
          print("Added new users. Total cards now: ${users.length}");
          _saveCurrentStackWithDebounce();
        } else {
          if (isInitialLoad && users.isEmpty) {
            print("Initial API fetch returned no users and stack is empty.");
            errorMessage.value = "Не найдено новых пользователей по вашим критериям.\nПопробуйте изменить фильтры или обновить.";
          } else if (!isInitialLoad) {
            print("Background API fetch returned no *new* users.");
          }
        }
      } else {
        print("HomeController closed during API fetch. Aborting state update.");
      }

    } catch (e) {
      print("Error during API fetch (_triggerApiFetch): $e");
      // --- FIX: Check if controller is disposed using 'isClosed' property ---
      if (!isClosed) { // Check if controller is still mounted
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        Get.snackbar(
          'Ошибка загрузки', errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100], colorText: Colors.red[900],
          margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 4),
        );
        if (isInitialLoad && users.isEmpty) {
          errorMessage.value = "Ошибка при загрузке: $errorMsg";
        }
      } else {
        print("HomeController closed during API fetch error handling.");
      }
    } finally {
      print("API fetch cycle finishing. Resetting flags.");
      // --- FIX: Check if controller is disposed using 'isClosed' property ---
      if (!isClosed) { // Reset flags ONLY IF the controller is still active
        _isApiFetchInProgress = false;
        isLoading.value = false;
        isLoadingMore.value = false;
      } else {
        print("HomeController closed, skipping final flag resets.");
      }
    }
  }

  Future<void> dismissCard(DismissDirection direction) async {
    if (users.isEmpty || isLoading.value || isLoadingMore.value || isSendingMessage.value || _isApiFetchInProgress) {
      print("Dismissal blocked: Busy (loading/sending/fetching) or stack empty.");
      return;
    }

    final dismissedUser = users.removeAt(0);
    final groupURL = dismissedUser.groupURL ?? "unknown_group";
    final actionType = direction == DismissDirection.startToEnd ? ActionLike : ActionDislike;

    print("${actionType == ActionLike ? 'Liking' : 'Disliking'} user: ${dismissedUser.userID} from group '$groupURL'");

    await _statisticsController.addUserAction(groupURL, dismissedUser, actionType);
    _saveCurrentStackWithDebounce(); // Save remaining stack

    if (actionType == ActionLike) {
      showMessageDialogForUser(dismissedUser);
    }

    _checkAndFetchMoreIfNeeded(delay: _fetchDebounceDuration);

    if (_justLoadedFromDisk) {
      _justLoadedFromDisk = false;
    }
  }

  void _checkAndFetchMoreIfNeeded({Duration delay = Duration.zero}) {
    _fetchDebounceTimer?.cancel();
    if (_justLoadedFromDisk) {
      print("CheckFetchMore: Just loaded from disk, skipping fetch trigger for now.");
      return;
    }

    _fetchDebounceTimer = Timer(delay, () {
      // --- FIX: Check 'isClosed' property ---
      if (isClosed) {
        print("CheckFetchMore: Timer fired but controller is closed. Aborting.");
        return;
      }
      if (users.length < _loadMoreThreshold && !_isApiFetchInProgress) {
        print("Card count low (${users.length}), triggering background API fetch.");
        _triggerApiFetch(isInitialLoad: false);
      } else {
        // print("CheckFetchMore: Card count (${users.length}) sufficient or fetch already in progress.");
      }
    });
  }

  Future<void> _saveCurrentStackWithDebounce() async {
    _saveStackDebounceTimer?.cancel();
    _saveStackDebounceTimer = Timer(_saveStackDebounceDuration, () {
      _saveCurrentStackImmediate();
    });
    // print("Save stack debouncer reset."); // Can be noisy, optional log
  }

  Future<void> _saveCurrentStackImmediate() async {
    // --- FIX: Check 'isClosed' property ---
    if (isClosed) {
      print("Save stack immediate: Controller is closed. Skipping save.");
      return;
    }
    final List<VKGroupUser> stackToSave = List.from(users); // Safe copy
    print("Saving current stack (immediate): ${stackToSave.length} users");
    await _localStorageProvider.savePersistedCards(stackToSave);
  }

  Future<void> _clearPersistedAndMemoryStack() async {
    print("Clearing persisted and in-memory card stack.");
    users.clear(); // Clear memory
    await _localStorageProvider.clearPersistedCards(); // Clear disk
  }

  Future<bool> sendVKMessage(String userId, String message) async {
    if (isSendingMessage.value) {
      print("Send message requested, but already sending. Skipping.");
      return false;
    }
    if (userId.isEmpty || !hasVkToken) {
      Get.snackbar('Ошибка', 'Не указан ID пользователя или VK токен.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (message.isEmpty) {
      Get.snackbar('Ошибка', 'Сообщение не может быть пустым.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    bool success = false;
    try {
      isSendingMessage.value = true;
      print("Setting isSendingMessage = true");
      success = await _groupUsersRepository.sendMessage(vkToken, userId, message);
      if (success) {
        Get.snackbar('Успех', 'Сообщение отправлено.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green[100], colorText: Colors.green[900], margin: const EdgeInsets.all(8), borderRadius: 10, duration: const Duration(seconds: 2));
      }
    } catch (e) {
      print("Error sending message from controller: $e");
      Get.snackbar('Ошибка', 'Не удалось отправить сообщение: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[900], margin: const EdgeInsets.all(8), borderRadius: 10);
      success = false;
    } finally {
      // --- FIX: Check 'isClosed' property ---
      if (!isClosed) { // Avoid setting state if controller is disposed
        isSendingMessage.value = false;
        print("Setting isSendingMessage = false");
      }
    }
    return success;
  }

  void showMessageDialogForUser(VKGroupUser targetUser) {
    final TextEditingController messageController =
    TextEditingController(text: defaultMessage);
    final RxBool isDialogSending = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Отправить сообщение'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          RichText(
              text: TextSpan(
                  style: TextStyle(color: Get.theme.textTheme.bodyMedium?.color),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Отмена')),
          Obx(() => ElevatedButton.icon(
              onPressed: isDialogSending.value
                  ? null
                  : () async {
                final message = messageController.text.trim();
                if (message.isEmpty) {
                  Get.snackbar('Ошибка', 'Сообщение не может быть пустым.',
                      snackPosition: SnackPosition.BOTTOM);
                  return;
                }
                isDialogSending.value = true;
                Get.back(result: true);
                await sendVKMessage(targetUser.userID, message);
              },
              icon: isDialogSending.value
                  ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(isDialogSending.value ? 'Отправка...' : 'Отправить'))),
        ],
      ),
      barrierDismissible: !isDialogSending.value,
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String labelText,
        required String hintText,
        required IconData icon,
        int maxLines = 1}) {
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
                borderSide: BorderSide.none
            ),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!)
            ),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Get.theme.primaryColor, width: 1.5)
            )
        )
    );
  }

  VoidCallback get refreshButtonAction => () => loadCardsFromAPI(forceReload: true);
}
