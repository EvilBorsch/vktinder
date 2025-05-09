import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/controllers/nav_controller.dart';
import 'package:vktinder/presentation/widgets/common/app_loading_indicator.dart';
import 'package:vktinder/presentation/widgets/common/app_error_display.dart';
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
          // Display remaining cards counter
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${controller.users.length}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              )),
          Obx(() => controller.isLoading.value || controller.isLoadingMore.value
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: AppLoadingIndicator.small()),
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
            child: AppLoadingIndicator.large(
              labelText: 'Ищем пользователей...',
            ),
          );
        }

        // Show message if error occurred or settings are missing
        if (controller.errorMessage.value != null && controller.users.isEmpty) {
          return AppErrorDisplay.warning(
            message: controller.errorMessage.value!,
            actionText: controller.hasVkToken ? 'Обновить' : 'В настройки',
            onActionPressed: () {
              if (controller.hasVkToken) {
                controller.loadCardsFromAPI(forceReload: true);
              } else {
                Get.find<NavController>().changePage(2);
              }
            },
            actionIcon: controller.hasVkToken ? Icons.refresh : Icons.settings,
          );
        }

        // Show empty state if loading finished, no errors, but no users found
        if (controller.users.isEmpty && !controller.isLoading.value) {
          return AppErrorDisplay.empty(
            title: 'Нет пользователей',
            message:
                "Не найдено пользователей по вашим критериям.\nПопробуйте изменить фильтры в настройках или обновить.",
            actionText: 'Обновить',
            onActionPressed: () =>
                controller.loadCardsFromAPI(forceReload: true),
            actionIcon: Icons.refresh,
          );
        }

        // Show the User Card stack
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                              child: UserCard(
                                user: controller.users[2],
                                // No callbacks for background cards
                              ),
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
                              child: UserCard(
                                user: controller.users[1],
                                // No callbacks for background cards
                              ),
                            ),
                          ),
                        ),
                      ),

                    // The main card with swipe functionality
                    if (controller.users.isNotEmpty)
                      UserCard(
                        key: ValueKey(controller.users.first.userID + '_card'),
                        user: controller.users.first,
                        onTap: () async {
                          // Load and display full profile
                          final user = controller.users.first;
                          Get.toNamed(Routes.UserDetails, arguments: user);
                        },
                        onSwipeLeft: () {
                          controller.dismissCard(DismissDirection.endToStart);
                        },
                        onSwipeRight: () {
                          controller.dismissCard(DismissDirection.startToEnd);
                        },
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: AppLoadingIndicator.inline(
                                    text: 'Загружаем еще...',
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
}
