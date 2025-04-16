// --- File: lib/presentation/pages/full_user_info.dart ---
// lib/presentation/pages/full_user_info.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/data/models/vk_group_info.dart'; // Import Group Info
import 'package:vktinder/presentation/controllers/user_detail_controller.dart';
import 'package:vktinder/routes/app_pages.dart';
import 'package:intl/date_symbol_data_local.dart'; // For group date formatting

class UserDetailsPage extends GetView<UserDetailsController> {
  const UserDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure Russian locale data is loaded for date formatting
    initializeDateFormatting('ru_RU');

    return Scaffold(
      // Use a SliverAppBar for a collapsing effect if desired, or keep AppBar
      appBar: AppBar(
        // Title can be dynamic based on user name
        title: Obx(() => Text(controller.user.value != null
            ? '${controller.user.value!.name} ${controller.user.value!.surname}'
            : 'Профиль', overflow: TextOverflow.ellipsis)),
        actions: [
          // More compact actions using IconButton for consistency
          Obx(() => controller.isLoading.value && controller.user.value == null // Show loader only if initial load
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Открыть в VK',
                onPressed: controller.user.value == null ? null : () => controller.openVkProfile(),
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined),
                tooltip: 'Написать сообщение',
                onPressed: controller.user.value == null ? null : () => controller.sendMessage(),
              ),
              const SizedBox(width: 8), // Add some padding to the right edge
            ],
          )
          ),
        ],
      ),
      body: Obx(() {
        // Show loading indicator centrally only if it's the initial load
        if (controller.isLoading.value && controller.user.value == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка профиля...'),
              ],
            ),
          );
        }

        // Show error state if no user is available after loading attempt
        if (!controller.isLoading.value && controller.user.value == null) {
          return Center(
            child: Padding( // Add padding around error card
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text(
                        "Не удалось загрузить профиль",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.isLoading.value ? 'Проверьте ID или токен' : 'Пользователь не найден или произошла ошибка.', // More specific message potentially
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Вернуться назад'),
                        onPressed: () {
                          if (Get.key.currentState?.canPop() ?? false) {
                            Get.back();
                          } else {
                            Get.offAllNamed(Routes.MAIN); // Fallback
                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // User data is available (at least initial data)
        // Use ListView for better structure and handling potential overflows
        return RefreshIndicator( // Allow pull-to-refresh
          onRefresh: () async {
            if (controller.user.value != null) {
              await controller.loadFullProfile(controller.user.value!.userID);
            }
          },
          child: ListView( // Changed from SingleChildScrollView to ListView
            padding: EdgeInsets.zero, // Remove default padding if using sections
            children: [
              DetailedProfileHeader(controller: controller), // Extracted header
              const SizedBox(height: 16),

              // Status Section
              Obx(() {
                final statusValue = controller.status.value;
                if (statusValue.isNotEmpty && statusValue != 'null') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSection(
                      context: context,
                      title: 'Статус',
                      icon: Icons.format_quote,
                      contentWidget: Text(
                        statusValue,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          // color: Theme.of(context).colorScheme.primary // Maybe too strong?
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),


              // About section if available
              Obx(() {
                final aboutText = controller.user.value?.about;
                if (aboutText != null && aboutText.isNotEmpty && aboutText != 'null') {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSection(
                      context: context,
                      title: 'О себе',
                      icon: Icons.person_outline,
                      contentWidget: Text(
                        aboutText,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),

              // Interests section if available
              Obx(() {
                final interestsList = controller.user.value?.interests ?? [];
                if (interestsList.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSection(
                      context: context,
                      title: 'Интересы',
                      icon: Icons.interests_outlined,
                      contentWidget: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: interestsList
                            .map((interest) => Chip(
                          label: Text(interest),
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Less round
                            side: BorderSide.none,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),


              // Photos section (only show if photos exist)
              Obx(() {
                if (controller.photos.isEmpty && !controller.isLoading.value) {
                  return const SizedBox.shrink(); // Hide section completely if no photos
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSectionHeader(
                        title: 'Фотографии (${controller.photos.length})',
                        icon: Icons.photo_library_outlined,
                        context: context,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PhotosGallery(photos: controller.photos), // Pass RxList directly
                  ],
                );
              }),
              const SizedBox(height: 16),

              // Groups section
              UserGroupsList(
                groups: controller.groups, // Pass RxList directly
                isLoading: controller.isLoading.value, // Indicate if still loading full profile
              ),
              const SizedBox(height: 24), // Bottom padding
            ],
          ),
        );
      }),
    );
  }

  // Helper for section header (moved outside build)
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), // Bolder title
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper for building sections (moved outside build)
  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget contentWidget}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: title, icon: icon, context: context),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4.0), // Small indent for content
          child: contentWidget,
        ),
      ],
    );
  }
}


// Extracted Header Widget
class DetailedProfileHeader extends StatelessWidget {
  final UserDetailsController controller;

  const DetailedProfileHeader({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Obx to listen to changes in individual fields
    return Obx(() {
      final userName = controller.user.value?.name ?? '...';
      final userSurname = controller.user.value?.surname ?? '...';
      final avatar = controller.avatarUrl.value; // Use observable
      final isOnline = controller.onlineStatus.value; // Use observable
      final locationText = controller.location.value; // Use observable
      final bDateText = controller.bDate.value; // Use observable
      final relationValue = controller.relation.value; // Use observable
      final userId = controller.user.value?.userID ?? 'loading'; // For Hero tag uniqueness

      return Container(
        padding: const EdgeInsets.all(16.0),
        // Optional: Add background color or decoration
        // color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Hero animation
                Hero(
                  tag: 'user_avatar_$userId', // Use unique ID
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: (avatar.isNotEmpty && avatar.startsWith('http'))
                        ? NetworkImage(avatar)
                        : null, // Handle empty/invalid URL
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    child: (avatar.isEmpty || !avatar.startsWith('http'))
                        ? const Icon(Icons.person, size: 50) // Placeholder
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Basic Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$userName $userSurname',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      // Online Status Row
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                              isOnline ? 'В сети' : _getLastSeenInfo(controller.user.value?.lastSeen) ?? 'Не в сети', // Add last seen info
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isOnline ? Colors.green : Colors.grey,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location
                      if (locationText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _buildInfoRow(
                              icon: Icons.location_on_outlined,
                              text: locationText,
                              context: context),
                        ),
                      // Birth Date
                      if (bDateText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _buildInfoRow(
                              icon: Icons.cake_outlined,
                              text: _formatBDate(bDateText), // Format birth date
                              context: context),
                        ),
                      // Relationship Status
                      if (relationValue != null) // relation is RxnInt, check for null
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _buildInfoRow(
                            icon: _getRelationIcon(relationValue), // Dynamic icon
                            text: _getRelationshipStatus(relationValue),
                            context: context,
                            // Optional: Color coding?
                            // primaryColor: relationValue == 6 || relationValue == 1 // Highlight active search/single
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Add a subtle divider below the header info
            const SizedBox(height: 16),
            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ],
        ),
      );
    });
  }

  // Helper to format BDate (including age calculation)
  String _formatBDate(String? bdate) {
    if (bdate == null || bdate.isEmpty) return '';
    try {
      List<String> parts = bdate.split('.');
      if (parts.length == 3) { // d.M.yyyy format
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        DateTime birthDate = DateTime(year, month, day);
        DateTime today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        // Format using Russian locale
        String formattedDate = DateFormat.yMMMMd('ru_RU').format(birthDate);
        return '$formattedDate ($age ${ _getAgeSuffix(age)})';
      } else if (parts.length == 2) { // d.M format
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        // Cannot calculate age reliably, just format date
        // Use a dummy year like 2000 for formatting
        DateTime birthDate = DateTime(2000, month, day);
        return DateFormat('d MMMM', 'ru_RU').format(birthDate);
      }
    } catch (e) {
      print("Error parsing bdate '$bdate': $e");
      return bdate; // Return original if parsing fails
    }
    return bdate; // Fallback
  }

  // Helper for age suffix (год, года, лет)
  String _getAgeSuffix(int age) {
    if (age % 100 >= 11 && age % 100 <= 14) {
      return 'лет';
    }
    switch (age % 10) {
      case 1:
        return 'год';
      case 2:
      case 3:
      case 4:
        return 'года';
      default:
        return 'лет';
    }
  }

  // Helper to format last seen time
  String? _getLastSeenInfo(Map<String, dynamic>? lastSeenData) {
    if (lastSeenData == null || !lastSeenData.containsKey('time')) return null;
    try {
      final int timestamp = lastSeenData['time'];
      final lastSeenDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final now = DateTime.now();
      final difference = now.difference(lastSeenDateTime);

      if (difference.inMinutes < 5) return 'недавно';
      if (difference.inHours < 1) return 'был(а) ${difference.inMinutes} мин. назад';

      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final lastSeenDay = DateTime(lastSeenDateTime.year, lastSeenDateTime.month, lastSeenDateTime.day);

      final timeFormat = DateFormat('HH:mm', 'ru_RU');
      final dateFormat = DateFormat('d MMM', 'ru_RU');
      final yearFormat = DateFormat('d MMM yyyy', 'ru_RU');

      if (lastSeenDay == today) {
        return 'был(а) сегодня в ${timeFormat.format(lastSeenDateTime)}';
      } else if (lastSeenDay == yesterday) {
        return 'был(а) вчера в ${timeFormat.format(lastSeenDateTime)}';
      } else if (lastSeenDateTime.year == now.year) {
        return 'был(а) ${dateFormat.format(lastSeenDateTime)} в ${timeFormat.format(lastSeenDateTime)}';
      } else {
        return 'был(а) ${yearFormat.format(lastSeenDateTime)}';
      }

    } catch (e) {
      print("Error formatting last seen: $e");
      return null;
    }
  }


  // Helper for info rows
  Widget _buildInfoRow(
      {required IconData icon,
        required String text,
        required BuildContext context,
        bool primaryColor = false}) {
    final textColor = primaryColor
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodyMedium?.color; // Use bodyMedium color

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align icon top if text wraps
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0), // Align icon slightly lower
          child: Icon(icon, size: 16, color: textColor),
        ),
        const SizedBox(width: 8), // Increased spacing
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
            // overflow: TextOverflow.ellipsis, // Allow wrapping instead of ellipsis
            // maxLines: 2,
          ),
        ),
      ],
    );
  }

  // Helper to get relevant icon for relationship status
  IconData _getRelationIcon(int relation) {
    switch (relation) {
      case 1: return Icons.person_outline; // Not married/single
      case 2: return Icons.favorite_border; // Has partner
      case 3: return Icons.ring_volume_outlined; // Engaged
      case 4: return Icons.favorite; // Married
      case 5: return Icons.sync_problem_outlined; // Complicated
      case 6: return Icons.search; // Active search
      case 7: return Icons.sentiment_satisfied_alt_outlined; // In love
      case 8: return Icons.home_work_outlined; // Civil union
      case 0: return Icons.question_mark; // Not specified
      default: return Icons.help_outline;
    }
  }


  // Helper to get relationship status text
  String _getRelationshipStatus(int relation) {
    switch (relation) {
      case 1:
        return 'Не женат/не замужем';
      case 2:
        return 'Есть друг/подруга';
      case 3:
        return 'Помолвлен(а)';
      case 4:
        return 'Женат/замужем';
      case 5:
        return 'Всё сложно';
      case 6:
        return 'В активном поиске';
      case 7:
        return 'Влюблён(а)';
      case 8:
        return 'В гражданском браке';
      case 0:
        return 'Статус не указан'; // Clearer than 'Не указано'
      default:
        return 'Статус не указан';
    }
  }
}


// --- WIDGET FOR GROUPS LIST ---
class UserGroupsList extends StatelessWidget {
  final List<VKGroupInfo> groups;
  final bool isLoading; // Indicates if the parent controller is loading

  const UserGroupsList({
    required this.groups,
    required this.isLoading,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show section if loading is finished and groups are definitively empty.
    // Show loader if parent is loading and groups are currently empty.
    if (!isLoading && groups.isEmpty) {
      // Optionally show a "No groups found" message if desired
      // return Padding(... Text('...'));
      return const SizedBox.shrink(); // Hide section if no groups
    }

    // Use NumberFormat for thousands separator
    final formatter = NumberFormat('#,###', 'ru_RU');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use the existing header builder from UserDetailsPage
          UserDetailsPage(key: key)._buildSectionHeader(
            title: 'Группы и паблики' + (groups.isNotEmpty ? ' (${groups.length})' : ''), // Show count only if > 0
            icon: Icons.group_work_outlined,
            context: context,
          ),
          const SizedBox(height: 12),

          // Show loading indicator specifically for groups if parent is loading AND groups are empty
          if (isLoading && groups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),

          // Display the groups using ListView.builder for potentially long lists
          if (groups.isNotEmpty)
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(), // Important inside another scrollable
              shrinkWrap: true,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                String membersText = 'Подписчиков: ?'; // Changed label
                if (group.membersCount != null) {
                  membersText =
                  '${formatter.format(group.membersCount)} подпис.';
                }

                return ListTile(
                  leading: CircleAvatar(
                    radius: 20, // Slightly smaller avatar
                    backgroundImage: NetworkImage(group.avatarUrl),
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  title: Text(group.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(membersText,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0), // Adjust padding
                  // Optional: Add onTap to open group?
                  onTap: () => _openVkGroup(group.screenName),
                  visualDensity: VisualDensity.compact, // Make denser
                );
              },
              separatorBuilder: (context, index) =>
              const Divider(height: 1, thickness: 0.5, indent: 52), // Match avatar size + padding
            ),
        ],
      ),
    );
  }

  // Helper to open VK group
  void _openVkGroup(String screenName) async {
    if (screenName.isEmpty) return;
    final url = 'https://vk.com/$screenName';
    final uri = Uri.parse(url);
    try {
      bool launched = false;
      if (!kIsWeb) {
        try { launched = await launchUrl(Uri.parse('vk://vk.com/$screenName'), mode: LaunchMode.externalApplication); }
        catch (e) { print("Failed vk://vk.com/ link for group: $e"); }
      }
      if (!launched) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Could not launch $url';
        }
      }
    } catch(e) {
      Get.snackbar('Ошибка', 'Не удалось открыть группу: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
// --- END GROUP WIDGET ---


// --- WIDGET FOR PHOTOS GALLERY ---
class PhotosGallery extends StatelessWidget {
  final List<String> photos;

  const PhotosGallery({
    required this.photos,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Important: Return SizedBox.shrink() directly here if photos are empty.
    // The section header is now handled conditionally outside this widget.
    if (photos.isEmpty) return const SizedBox.shrink();

    // Fixed height for the horizontal gallery scrolling area
    double galleryHeight = size.height * 0.25; // Adjust height as needed

    return SizedBox(
      height: galleryHeight,
      child: ListView.builder( // Use ListView for horizontal scrolling
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), // Remove vertical padding here
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photoUrl = photos[index];
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, photos, index),
            child: Hero(
              tag: 'photo_$index', // Unique tag per photo
              child: Container(
                width: galleryHeight * 0.8, // Aspect ratio control (e.g., 4:5)
                margin: const EdgeInsets.only(right: 10), // Spacing between photos
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    // Loading Builder
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    // Error Builder
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Method to show full-screen image viewer
  void _showFullScreenImage(BuildContext context, List<String> photos, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder( // Use PageRouteBuilder for custom transitions
        opaque: false, // Make route background transparent
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black.withOpacity(animation.value), // Fade background
          appBar: AppBar(
              backgroundColor: Colors.transparent, // Transparent AppBar
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )),
          body: Container(
            color: Colors.transparent, // Container also transparent
            child: PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Hero(
                    tag: 'photo_$index', // Match tag from gallery item
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5, // Allow zoom out
                      maxScale: 5.0, // Allow more zoom in
                      child: FadeInImage.memoryNetwork( // Use FadeInImage for smoother loading feel
                        placeholder: kTransparentImage, // Requires import 'package:transparent_image/transparent_image.dart'; (or use a different placeholder) -> Need to add dependency if using this. Using basic Image.network for now.
                        // placeholder: Uint8List(0), // Empty placeholder
                        image: photos[index],
                        fit: BoxFit.contain,
                        // Loading builder within FadeInImage not directly supported, but InteractiveViewer handles zoom/pan
                        imageErrorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),

                      ),
                      // child: Image.network( // Original way
                      //   photos[index],
                      //   fit: BoxFit.contain,
                      //    loadingBuilder: (context, widget, imageLoadingProgress) { /* ... */ },
                      //   errorBuilder: (context, error, stackTrace) => /* ... */,
                      // ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

// Placeholder for kTransparentImage if you add the dependency later
// import 'package:transparent_image/transparent_image.dart';
// If not adding, use Image.network directly as before or a local asset.
final kTransparentImage = Uri.parse('data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7').data!.contentAsBytes();

// --- END PHOTO WIDGET ---