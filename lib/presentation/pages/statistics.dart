// --- File: lib/presentation/pages/statistics.dart ---
// lib/presentation/pages/statistics.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/data/models/statistics.dart';
import 'package:vktinder/presentation/controllers/statistics_controller.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for locale data

class StatisticsPage extends GetView<StatisticsController> {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure Russian locale data is loaded for date formatting
    initializeDateFormatting('ru_RU');

    // Request a refresh of the view data when the page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshStatisticsView();
    });

    // State variables for filtering and sorting (local to this build method)
    final selectedGroup = RxString('all_groups');
    final sortByLatestLikes = RxBool(true); // Default sort

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
                  // Get distinct group URLs from the loaded actions
                  final availableGroups = <String>{'all_groups'};
                  controller.userActions.forEach((groupUrl, actions) {
                    if (groupUrl.isNotEmpty && actions.isNotEmpty) {
                      // Only add if there are actions for this group
                      availableGroups.add(groupUrl);
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
                      // Basic sort by name for now
                      return _extractGroupName(a)
                          .compareTo(_extractGroupName(b));
                    });

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Группа',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    value: selectedGroup.value,
                    isExpanded: true,
                    // Allow long names to fit
                    items: sortedGroupList
                        .map((groupUrl) => DropdownMenuItem(
                              value: groupUrl,
                              child: Text(
                                groupUrl == 'all_groups'
                                    ? 'Все группы'
                                    : _extractGroupName(groupUrl),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedGroup.value = value;
                        // No need to explicitly call controller.refresh or update()
                        // The Obx below rebuilding the list will react to selectedGroup change.
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
                        // Re-sorting happens in the Obx below
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

              // --- Filtering ---
              var filteredActions = <StatisticsUserAction>[];
              if (selectedGroup.value == 'all_groups') {
                controller.userActions.values.forEach((rxList) {
                  filteredActions.addAll(rxList);
                });
              } else if (controller.userActions
                  .containsKey(selectedGroup.value)) {
                filteredActions
                    .addAll(controller.userActions[selectedGroup.value]!);
              }

              if (filteredActions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          selectedGroup.value == 'all_groups'
                              ? Icons.analytics_outlined
                              : Icons.filter_alt_off_outlined,
                          size: 64,
                          color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        selectedGroup.value == 'all_groups'
                            ? 'Нет данных статистики\nНачните свайпать!'
                            : 'Нет действий для группы\n"${_extractGroupName(selectedGroup.value)}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // --- Sorting ---
              filteredActions.sort((a, b) {
                if (sortByLatestLikes.value) {
                  // Likes first, then by date descending
                  final isALike = a.action == ActionLike;
                  final isBLike = b.action == ActionLike;
                  if (isALike != isBLike) {
                    return isALike ? -1 : 1;
                  }
                }
                // If types are same or not sorting by like, sort by date descending
                return b.actionDate.compareTo(a.actionDate);
              });

              // --- Grouping items with headers ---
              // Pass the current selected group value to the function that needs it
              final itemsWithHeaders = _buildItemsWithHeaders(filteredActions);

              // Calculate totals from the *filtered* list
              int totalLikes =
                  filteredActions.where((a) => a.action == ActionLike).length;
              int totalDislikes = filteredActions
                  .where((a) => a.action == ActionDislike)
                  .length;

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
                            'Всего просмотрено', // Updated label
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

                  // User action list with headers
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: itemsWithHeaders.length,
                      itemBuilder: (context, index) {
                        final item = itemsWithHeaders[index];
                        if (item is String) {
                          // Build header
                          return _buildDateHeader(context, item);
                        } else if (item is StatisticsUserAction) {
                          // Build user action card
                          // **** FIX: Pass selectedGroup.value here ****
                          return _buildUserActionCard(
                              context, item, selectedGroup.value);
                        }
                        return const SizedBox.shrink(); // Should not happen
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

  // --- Helper Functions ---

  /// Extracts a displayable name from a group URL/screen name.
  String _extractGroupName(String groupUrl) {
    if (groupUrl == 'all_groups') return 'Все группы';
    try {
      if (groupUrl.startsWith('http')) {
        Uri uri = Uri.parse(groupUrl);
        if (uri.pathSegments.isNotEmpty) {
          var name = uri.pathSegments.last;
          if (name.isEmpty && uri.pathSegments.length > 1) {
            name = uri.pathSegments[uri.pathSegments.length - 2];
          }
          return name.isNotEmpty
              ? name
              : groupUrl; // Fallback to full URL if parsing fails
        }
      }
      // Handle screen names like club123, public123
      if (RegExp(r'^(club|public)\d+$').hasMatch(groupUrl)) {
        return groupUrl; // Keep as is for now
      }
      return groupUrl; // Assume it's a screen name
    } catch (e) {
      print("Error extracting group name from $groupUrl: $e");
      return groupUrl; // Fallback
    }
  }

  /// Builds the list of items including date headers.
  List<dynamic> _buildItemsWithHeaders(List<StatisticsUserAction> actions) {
    if (actions.isEmpty) return [];

    final List<dynamic> items = [];
    String? lastHeader;

    for (int i = 0; i < actions.length; i++) {
      final currentAction = actions[i];
      final previousAction = (i > 0) ? actions[i - 1] : null;

      // Determine the header based on the date comparison logic
      final String header = _formatDateHeader(currentAction.actionDate);

      // Add header if it's different from the last one processed
      if (header != lastHeader) {
        items.add(header);
        lastHeader = header;
      }
      // Add the actual action item
      items.add(currentAction);
    }
    return items;
  }

  /// Formats the date header string based on the action's date.
  String _formatDateHeader(DateTime current) {
    // Simplified: only needs current date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final currentDay = DateTime(current.year, current.month, current.day);
    final currentMonth = DateTime(current.year, current.month);
    final thisMonth = DateTime(now.year, now.month);

    if (currentDay == today) {
      return 'Сегодня';
    } else if (currentDay == yesterday) {
      return 'Вчера';
    } else if (currentMonth == thisMonth) {
      // Within the current month but not today/yesterday
      return DateFormat('d MMMM', 'ru_RU').format(current); // e.g., "15 мая"
    } else if (current.year == now.year) {
      // Older month within the current year
      return DateFormat('MMMM', 'ru_RU').format(current); // e.g., "Апрель"
    } else {
      // Different year
      return DateFormat('MMMM yyyy', 'ru_RU')
          .format(current); // e.g., "Декабрь 2023"
    }
  }

  /// Builds the header widget for the list.
  Widget _buildDateHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      // Use a slightly different background for month/year headers vs day headers
      color: (title == 'Сегодня' ||
              title == 'Вчера' ||
              title.contains(RegExp(r'^\d{1,2}\s')))
          ? Theme.of(context)
              .colorScheme
              .surfaceVariant
              .withOpacity(0.5) // Day header
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
      // Month/Year header
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: (title == 'Сегодня' ||
                      title == 'Вчера' ||
                      title.contains(RegExp(r'^\d{1,2}\s')))
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
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
                  .titleLarge // Use titleLarge for more emphasis
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // *** Updated signature to accept currentFilterGroup ***
  Widget _buildUserActionCard(BuildContext context, StatisticsUserAction action,
      String currentFilterGroup) {
    final dateFormat = DateFormat('HH:mm', 'ru_RU'); // Only time needed
    final formattedTime = dateFormat.format(action.actionDate);
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
                action.avatar ?? 'https://vk.com/images/camera_100.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300, shape: BoxShape.circle),
                  child: Icon(Icons.person_outline, color: Colors.grey[600]),
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
                          '${action.name} ${action.surname}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        isLike ? Icons.favorite : Icons.close,
                        color: isLike ? Colors.redAccent : Colors.blueGrey,
                        size: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Time and Group
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const Spacer(),
                      // **** FIX: Use the passed currentFilterGroup parameter ****
                      if (action.groupURL != null &&
                          action.groupURL!.isNotEmpty &&
                          currentFilterGroup == 'all_groups')
                        Flexible(
                          child: Text(
                            '(${_extractGroupName(action.groupURL!)})',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Open in VK button
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () => _openVkProfile(action.userId),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Открыть в VK'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                        elevation: 0,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
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
    final uri = Uri.parse(url);
    bool launched = false;
    try {
      if (kIsWeb){
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }else {
        launched = await launchUrl(
          Uri.parse('vk://profile/$userId'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
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
