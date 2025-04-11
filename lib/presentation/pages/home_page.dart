import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/controllers/nav_controller.dart';
import 'package:vktinder/presentation/widgets/user_card.dart';
import 'package:vktinder/routes/app_pages.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VK Tinder"),
        actions: [
          Obx(() => controller.isLoading.value || controller.isLoadingMore.value
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          )
              : IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.isLoading.value
                ? null
                : () => controller.loadCardsFromAPI(forceReload: true),
            tooltip: 'Обновить список',
          )),
        ],
      ),
      body: Obx(() {
        // Show loading indicator centrally
        if (controller.isLoading.value && controller.users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Ищем пользователей...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Show message if error occurred or settings are missing
        if (controller.errorMessage.value != null && controller.users.isEmpty) {
          return _buildInfoCard(
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
              title: 'Внимание',
              message: controller.errorMessage.value!,
              buttonText: controller.hasVkToken ? 'Обновить' : 'В настройки',
              onButtonPressed: () {
                if (controller.hasVkToken) {
                  controller.loadCardsFromAPI(forceReload: true);
                } else {
                  Get.find<NavController>().changePage(1);
                }
              },
              buttonIcon: controller.hasVkToken ? Icons.refresh : Icons.settings);
        }

        // Show empty state if loading finished, no errors, but no users found
        if (controller.users.isEmpty && !controller.isLoading.value) {
          return _buildInfoCard(
              icon: Icons.people_outline,
              iconColor: Colors.blue,
              title: 'Нет пользователей',
              message:
              "Не найдено пользователей по вашим критериям.\nПопробуйте изменить фильтры в настройках или обновить.",
              buttonText: 'Обновить',
              onButtonPressed: () =>
                  controller.loadCardsFromAPI(forceReload: true),
              buttonIcon: Icons.refresh);
        }

        // Show the User Card stack
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.center,
                  fit: StackFit.passthrough,
                  children: [
                    // Background cards simulation
                    if (controller.users.length > 2)
                      Positioned(
                        top: 16,
                        child: SizedBox(
                          width: constraints.maxWidth * 0.9,
                          child: Transform.scale(
                            scale: 0.9,
                            child: Opacity(
                              opacity: 0.5,
                              child: UserCard(user: controller.users[2]),
                            ),
                          ),
                        ),
                      ),
                    if (controller.users.length > 1)
                      Positioned(
                        top: 8,
                        child: SizedBox(
                          width: constraints.maxWidth * 0.95,
                          child: Transform.scale(
                            scale: 0.95,
                            child: Opacity(
                              opacity: 0.8,
                              child: UserCard(user: controller.users[1]),
                            ),
                          ),
                        ),
                      ),

                    // The main dismissible card
                    if (controller.users.isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          // Load and display full profile
                          final user = controller.users.first;
                          Get.toNamed(Routes.UserDetails, arguments: user);
                        },
                        child: Dismissible(
                          key: ValueKey(controller.users.first.userID),
                          direction: DismissDirection.horizontal,
                          background: _buildSwipeBackground(Alignment.centerLeft,
                              Colors.green, Icons.message_rounded),
                          secondaryBackground: _buildSwipeBackground(
                              Alignment.centerRight,
                              Colors.red,
                              Icons.close_rounded),
                          onDismissed: (direction) {
                            controller.dismissCard(direction);
                          },
                          child: UserCard(
                            key: ValueKey(controller.users.first.userID + '_card'),
                            user: controller.users.first,
                          ),
                        ),
                      ),

                    // Loading more indicator at the bottom
                    if (controller.users.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        child: IgnorePointer(
                          child: Obx(() => controller.isLoadingMore.value
                              ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Загружаем еще...',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : const SizedBox.shrink()),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      }),
    );
  }

  // Helper for swipe background
  Widget _buildSwipeBackground(
      Alignment alignment, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Icon(
        icon,
        color: Colors.white,
        size: 64,
      ),
    );
  }

  // Helper for info/error cards
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onButtonPressed,
    required IconData buttonIcon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 3,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 60, color: iconColor),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onButtonPressed,
                  icon: Icon(buttonIcon),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}