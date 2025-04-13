import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';

class StatisticsPage extends GetView<StatisticsController> {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get settings controller to access group URLs
    final settingsController = Get.find<SettingsController>();

    // Load statistics data when page is shown
    controller.getUserActions();

    // State variables for filtering and sorting
    final selectedGroup = RxString('all_groups'); // Changed default value
    final sortByLatestLikes = RxBool(true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Filter and sort controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Фильтры и сортировка',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Group selection dropdown
                Obx(() {
                  // Build the dropdown items from available groups
                  final availableGroups = <String>{'all_groups'}; // Use Set to avoid duplicates

                  // Add groups from statistics data
                  controller.userActions.keys.forEach((group) {
                    if (group.isNotEmpty) {
                      availableGroups.add(group);
                    }
                  });

                  // Add groups from settings (if not already in the list)
                  settingsController.groupUrls.forEach((url) {
                    if (url.isNotEmpty) {
                      availableGroups.add(url);
                    }
                  });

                  // Make sure selectedGroup value is valid and present in the items
                  if (!availableGroups.contains(selectedGroup.value)) {
                    selectedGroup.value = 'all_groups';
                  }

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Группа',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    value: selectedGroup.value,
                    items: availableGroups.map((group) => DropdownMenuItem(
                      value: group,
                      child: Text(
                        group == 'all_groups' ? 'Все группы' : group,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedGroup.value = value;
                      }
                    },
                  );
                }),

                const SizedBox(height: 12),

                // Sort option
                Obx(() => SwitchListTile(
                  title: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('Сначала последние лайки'),
                    ],
                  ),
                  value: sortByLatestLikes.value,
                  onChanged: (value) {
                    sortByLatestLikes.value = value;
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
              ],
            ),
          ),

          const Divider(height: 1),

          // Statistics content
          Expanded(
            child: Obx(() {
              // Process data based on filters
              final Map<String, List<StatisticsUserAction>> filteredActions = {};

              if (selectedGroup.value == 'all_groups') {
                // Show all groups
                controller.userActions.forEach((group, actions) {
                  filteredActions[group] = actions.toList();
                });
              } else if (controller.userActions.containsKey(selectedGroup.value)) {
                // Show specific group
                filteredActions[selectedGroup.value] = controller.userActions[selectedGroup.value]!.toList();
              }

              // Apply sorting if needed
              if (sortByLatestLikes.value) {
                filteredActions.forEach((group, actions) {
                  actions.sort((a, b) {
                    if (a.action == ActionLike && b.action != ActionLike) {
                      return -1;
                    } else if (a.action != ActionLike && b.action == ActionLike) {
                      return 1;
                    } else {
                      return b.actionDate.compareTo(a.actionDate);
                    }
                  });
                });
              } else {
                // Default sort by date (newest first)
                filteredActions.forEach((group, actions) {
                  actions.sort((a, b) => b.actionDate.compareTo(a.actionDate));
                });
              }

              // Build the UI based on filtered & sorted data
              if (controller.userActions.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Нет данных статистики\nНачните свайпать!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              if (filteredActions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Нет данных для группы\n${selectedGroup.value == 'all_groups' ? 'Все группы' : selectedGroup.value}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Count totals for display
              int totalLikes = 0;
              int totalDislikes = 0;

              filteredActions.forEach((group, actions) {
                actions.forEach((action) {
                  if (action.action == ActionLike) {
                    totalLikes++;
                  } else if (action.action == ActionDislike) {
                    totalDislikes++;
                  }
                });
              });

              // Flatten all actions for the ListView
              final allActions = <StatisticsUserAction>[];
              filteredActions.forEach((group, actions) {
                allActions.addAll(actions);
              });

              // Apply final sort to the flattened list
              if (sortByLatestLikes.value) {
                allActions.sort((a, b) {
                  if (a.action == ActionLike && b.action != ActionLike) {
                    return -1;
                  } else if (a.action != ActionLike && b.action == ActionLike) {
                    return 1;
                  } else {
                    return b.actionDate.compareTo(a.actionDate);
                  }
                });
              } else {
                allActions.sort((a, b) => b.actionDate.compareTo(a.actionDate));
              }

              return Column(
                children: [
                  // Summary stats
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                            context,
                            'Всего',
                            '${totalLikes + totalDislikes}',
                            Icons.people,
                            Colors.blue
                        ),
                        _buildStatCard(
                            context,
                            'Лайки',
                            '$totalLikes',
                            Icons.favorite,
                            Colors.red
                        ),
                        _buildStatCard(
                            context,
                            'Пропущено',
                            '$totalDislikes',
                            Icons.close,
                            Colors.grey
                        ),
                      ],
                    ),
                  ),

                  // User action list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: allActions.length,
                      itemBuilder: (context, index) {
                        final action = allActions[index];
                        return _buildUserActionCard(context, action);
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActionCard(BuildContext context, StatisticsUserAction action) {
    final user = action.user;
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final formattedDate = dateFormat.format(action.actionDate);

    final isLike = action.action == ActionLike;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                user.avatar ?? 'https://vk.com/images/camera_200.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // User info and action
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${user.name} ${user.surname}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Icon(
                        isLike ? Icons.favorite : Icons.close,
                        color: isLike ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Action information
                  Text(
                    'Действие: ${isLike ? 'Лайк' : 'Пропуск'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  Text(
                    'Дата: $formattedDate',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  if (user.groupURL != null && user.groupURL!.isNotEmpty)
                    Text(
                      'Группа: ${user.groupURL}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Open in VK button
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _openVkProfile(user.userID),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Открыть в VK'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVkProfile(String userId) async {
    final url = 'https://vk.com/id$userId';

    try {
      // Try to launch VK app first
      bool launched = false;

      try {
        // Try Android deep link
        launched = await launchUrl(
          Uri.parse('vk://profile/$userId'),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print("Could not launch Android VK app: $e");
      }

      // If Android didn't work, try iOS deep link
      if (!launched) {
        try {
          launched = await launchUrl(
            Uri.parse('vk://vk.com/id$userId'),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          print("Could not launch iOS VK app: $e");
        }
      }

      // If app launch failed, open in browser
      if (!launched) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Show error message
      Get.snackbar(
        'Ошибка',
        'Не удалось открыть профиль: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(8),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
