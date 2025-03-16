import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/home_controller.dart';
import 'package:vktinder/presentation/widgets/user_card.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        // Show loading indicator
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show message if no token
        if (!controller.hasVkToken) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.key_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Для начала работы задайте VK Token в настройках",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show empty state if no users
        if (controller.users.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Нет пользователей для отображения",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show the stack of cards
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(
              controller.users.length,
              (index) {
                // Stack cards from end to start (last card on top)
                final cardIndex = controller.users.length - 1 - index;
                if (cardIndex >= 0 && cardIndex < controller.users.length) {
                  final user = controller.users[cardIndex];

                  // Only the top card is dismissible
                  if (cardIndex == 0) {
                    return Dismissible(
                      key:
                          ValueKey(user.toString() + DateTime.now().toString()),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(
                          Icons.message,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      onDismissed: (direction) {
                        controller.dismissCard(direction);
                      },
                      child: UserCard(user: user),
                    );
                  }

                  // Other cards in the stack (not dismissible)
                  return Transform.translate(
                    offset: Offset(0, -10.0 * index),
                    child: UserCard(user: user),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }),
    );
  }
}
