// --- File: lib/presentation/controllers/user_detail_controller.dart ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/data/models/vk_group_user.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/data/repositories/group_users_repository_impl.dart';
import 'package:vktinder/routes/app_pages.dart';

class UserDetailsController extends GetxController {
  // Main user object - can be null initially or on error
  final Rx<VKGroupUser?> user = Rx<VKGroupUser?>(null);

  // Separate observables for potentially updated fields from getFullProfile
  // These are primarily for UI updates if the underlying user object changes
  // in ways that the full object replacement might not trigger UI refresh for nested widgets.
  final RxString status = ''.obs;
  final Rxn<int> relation = Rxn<int>(); // Nullable int
  final RxBool onlineStatus = false.obs; // Separate bool for online
  final RxString avatarUrl = ''.obs;
  final RxString location = ''.obs; // Combined city/country
  final RxString bDate = ''.obs;
  // Use RxList for photos and groups as they are fetched separately/concurrently
  final RxList<String> photos = <String>[].obs;
  final RxList<VKGroupInfo> groups = <VKGroupInfo>[].obs;


  final RxBool isLoading = true.obs;
  final RxBool isSendingMessage = false.obs;

  final SettingsController _settingsController = Get.find<SettingsController>();
  final GroupUsersRepository _groupUsersRepository = Get.find<GroupUsersRepository>();

  String? _initialUserID; // Store the ID passed via arguments

  @override
  void onInit() {
    super.onInit();

    // Extract initial user data from arguments if available
    if (Get.arguments != null && Get.arguments is VKGroupUser) {
      final initialUser = Get.arguments as VKGroupUser;
      _initialUserID = initialUser.userID;
      _updateObservables(initialUser, isInitial: true); // Update UI with initial data
      isLoading.value = false; // Show initial data immediately
      print("UserDetailsController: Initialized with user ID $_initialUserID from arguments.");
    } else {
      // Handle cases where arguments might be just the ID (if navigation changes)
      if (Get.arguments != null && Get.arguments is String) {
        _initialUserID = Get.arguments as String;
        isLoading.value = true; // Need to load everything
        print("UserDetailsController: Initialized with user ID $_initialUserID from arguments (String).");
      } else {
        // No valid argument found
        isLoading.value = true; // Keep loading true
        print("UserDetailsController Error: No valid user data or ID found in arguments.");
        // Navigate back or show error early? Decided to handle in onReady.
      }
    }
  }

  @override
  void onReady() {
    super.onReady();

    // Load full profile details if we have a user ID
    if (_initialUserID != null) {
      print("UserDetailsController: onReady - Triggering loadFullProfile for $_initialUserID");
      // Set loading to true only if we didn't have initial data or if forced refresh needed
      if (user.value == null) {
        isLoading.value = true;
      }
      loadFullProfile(_initialUserID!);
    } else {
      // No user ID, cannot proceed
      isLoading.value = false; // Stop loading
      Get.snackbar(
        'Ошибка',
        'Не удалось найти данные пользователя для отображения.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
      );
      // Give time for snackbar to appear before navigating back
      Future.delayed(const Duration(seconds: 2), () {
        if (Get.key.currentState?.canPop() ?? false) {
          Get.back();
        } else {
          Get.offAllNamed(Routes.MAIN); // Fallback if cannot pop
        }
      });
    }
  }

  // Helper to update all observable fields from a VKGroupUser object
  void _updateObservables(VKGroupUser userDetails, {bool isInitial = false}) {
    // Update the main user object reference
    user.value = userDetails;

    // Update individual observables for reactivity
    status.value = userDetails.status ?? '';
    relation.value = userDetails.relation;
    onlineStatus.value = userDetails.online ?? false;
    avatarUrl.value = userDetails.avatar ?? 'https://vk.com/images/camera_200.png'; // Provide default

    // Combine city and country
    final city = userDetails.city;
    final country = userDetails.country;
    location.value = [if (city != null && city.isNotEmpty) city, if (country != null && country.isNotEmpty) country].join(', ');

    bDate.value = userDetails.bdate ?? '';

    // Update lists only if they changed significantly (or if initial load)
    // Using assignAll triggers list updates properly
    if (isInitial || !listEquals(photos, userDetails.photos)) {
      photos.assignAll(userDetails.photos);
    }
    if (isInitial || !listEquals(groups, userDetails.groups)) {
      groups.assignAll(userDetails.groups);
    }

    // Debug prints
    // print("Observables Updated: Status='${status.value}', Relation=${relation.value}, Online=${onlineStatus.value}, Photos=${photos.length}, Groups=${groups.length}");
  }


  Future<void> loadFullProfile(String userID) async {
    // Avoid reload if already loading the same user
    if (isLoading.value && user.value?.userID == userID) return;

    // Indicate loading starts
    // Use isLoading only if no user data is present yet
    if (user.value == null) {
      isLoading.value = true;
    }

    try {
      final userDetails = await _groupUsersRepository.getFullProfile(
        _settingsController.vkToken,
        userID,
      );

      _updateObservables(userDetails); // Update all fields from the fresh data

      print("Loaded full profile - Photos: ${photos.length}, Groups: ${groups.length}");

    } catch (e) {
      print("Error loading full profile: $e");
      Get.snackbar(
        'Ошибка Загрузки Профиля',
        e.toString().replaceFirst('Exception: ', ''), // Cleaner error message
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 4),
      );
      // Keep existing data if load fails, unless it was the initial load
      // If initial load failed (user.value still null), error state is shown by UI checks
    } finally {
      isLoading.value = false; // Ensure loading is set to false
    }
  }

  // Helper for list equality check needed for _updateObservables
  bool listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }


  // Method to open VK profile
  void openVkProfile() async {
    if (user.value == null) return;

    final userId = user.value!.userID;
    final url = 'https://vk.com/id$userId';
    final uri = Uri.parse(url);

    try {
      bool launched = false;
      // Try specific app links first
      if (!kIsWeb) { // Only try app links on mobile
        try { launched = await launchUrl(Uri.parse('vk://profile/$userId'), mode: LaunchMode.externalApplication); }
        catch (e) { print("Failed vk://profile link: $e"); }

        // // iOS specific? (might be redundant)
        // if (!launched) {
        //    try { launched = await launchUrl(Uri.parse('vk://vk.com/id$userId'), mode: LaunchMode.externalApplication); }
        //    catch (e) { print("Failed vk://vk.com/id link: $e"); }
        // }
      }

      // Fallback to web URL
      if (!launched) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось открыть профиль VK: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );
    }
  }


  // Method to initiate sending a message
  void sendMessage() {
    if (user.value == null) return;

    final targetUser = user.value!; // Safe now due to check

    // Slightly improved check using can_write_private_message if available
    if (targetUser.canWritePrivateMessage == false) {
      Get.snackbar(
        'Невозможно отправить',
        'Пользователь ограничил получение личных сообщений.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );
      return;
    }


    final TextEditingController messageController =
    TextEditingController(text: _settingsController.defaultMessage);
    final RxBool isDialogSending = false.obs; // Local state for dialog button

    Get.dialog(
      AlertDialog(
        title: const Text(
          'Отправить сообщение',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: Get.theme.textTheme.bodyMedium?.color),
                children: [
                  const TextSpan(text: 'Сообщение для '),
                  TextSpan(
                    text: '${targetUser.name} ${targetUser.surname}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Сообщение',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
          Obx(() => ElevatedButton.icon( // Observe local sending state
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
              Get.back(); // Close dialog immediately

              // Send message using repository (feedback handled within repo/provider now)
              await _groupUsersRepository.sendMessage(
                _settingsController.vkToken,
                targetUser.userID,
                message,
              );
              // No need to reset isDialogSending.value as dialog is closed
            },
            icon: isDialogSending.value
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: Text(
                isDialogSending.value ? 'Отправка...' : 'Отправить',
                style: const TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(110, 40) // Ensure minimum button size
            ),
          )),
        ],
      ),
      barrierDismissible: !isDialogSending.value, // Prevent dismiss while sending
    );
  }
}