// lib/presentation/pages/statistics.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart'; // Check if needed
import 'package:vktinder/presentation/controllers/statistics_controller.dart';

class StatisticsPage extends GetView<StatisticsController> {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get settings controller if needed for group URLs (maybe for display names if not in action)
    // final settingsController = Get.find<SettingsController>();

    // Request a refresh of the view data (which is now in memory)
    // This ensures the latest data is shown if the page was backgrounded
    // and data changed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshStatisticsView();
    });


    // State variables for filtering and sorting
    final selectedGroup = RxString('all_groups');
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
                  // Build the dropdown items from available groups in stats
                  final availableGroups = <String>{'all_groups'};
                  controller.userActions.keys.forEach((group) {
                    if (group.isNotEmpty) {
                      availableGroups.add(group);
                    }
                  });

                  // Make sure selectedGroup value is valid
                  if (!availableGroups.contains(selectedGroup.value)) {
                    selectedGroup.value = 'all_groups';
                  }

                  // Sort group names for better usability
                  final sortedGroupList = availableGroups.toList()
                    ..sort((a, b) {
                      if (a == 'all_groups') return -1;
                      if (b == 'all_groups') return 1;
                      return a.compareTo(b);
                    });

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Группа',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    value: selectedGroup.value,
                    isExpanded: true, // Allow long names to fit
                    items: sortedGroupList.map((group) => DropdownMenuItem(
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
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

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

              // --- Filtering and Sorting Logic ---
              var allActionsFlat = <StatisticsUserAction>[];
              if (selectedGroup.value == 'all_groups') {
                controller.userActions.values.forEach((rxList) {
                  allActionsFlat.addAll(rxList);
                });
              } else if (controller.userActions.containsKey(selectedGroup.value)) {
                allActionsFlat.addAll(controller.userActions[selectedGroup.value]!);
              }

              // Apply sorting
              allActionsFlat.sort((a, b) {
                if (sortByLatestLikes.value) {
                  // Likes first, then by date descending
                  final isALike = a.action == ActionLike;
                  final isBLike = b.action == ActionLike;
                  if (isALike && !isBLike) return -1;
                  if (!isALike && isBLike) return 1;
                }
                // Default/fallback: sort by date descending
                return b.actionDate.compareTo(a.actionDate);
              });
              // --- End Filtering and Sorting ---


              if (allActionsFlat.isEmpty && selectedGroup.value != 'all_groups') {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_off_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Нет действий для группы\n"${selectedGroup.value}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }


              // Calculate totals from the flat list
              int totalLikes = allActionsFlat.where((a) => a.action == ActionLike).length;
              int totalDislikes = allActionsFlat.where((a) => a.action == ActionDislike).length;

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
                            Colors.blue),
                        _buildStatCard(context, 'Лайки', '$totalLikes',
                            Icons.favorite, Colors.red),
                        _buildStatCard(context, 'Пропущено', '$totalDislikes',
                            Icons.close, Colors.grey),
                      ],
                    ),
                  ),

                  // User action list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: allActionsFlat.length,
                      itemBuilder: (context, index) {
                        final action = allActionsFlat[index];
                        // *** Use fields directly from action, not action.user ***
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

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
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
              style: Theme.of(context).textTheme.labelSmall, // Use labelSmall
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium // Use titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // *** Updated to use fields directly from StatisticsUserAction ***
  Widget _buildUserActionCard(BuildContext context, StatisticsUserAction action) {
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
                action.avatar ?? 'https://vk.com/images/camera_100.png', // Smaller default
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300, shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline, color: Colors.grey),
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
                          '${action.name} ${action.surname}', // Use fields directly
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        isLike ? Icons.favorite : Icons.close,
                        color: isLike ? Colors.redAccent : Colors.grey,
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

                  if (action.groupURL != null && action.groupURL!.isNotEmpty)
                    Text(
                      'Группа: ${action.groupURL}', // Use field directly
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Open in VK button
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _openVkProfile(action.userId), // Use field directly
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Открыть в VK'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                        // Optional: More subtle button style
                        elevation: 0,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
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

  // _openVkProfile remains the same
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

