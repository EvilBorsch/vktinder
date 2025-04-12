// lib/presentation/pages/full_user_info.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:vktinder/data/models/vk_group_info.dart'; // Import Group Info
import 'package:vktinder/presentation/controllers/user_detail_controller.dart';
import 'package:vktinder/routes/app_pages.dart';

class UserDetailsPage extends GetView<UserDetailsController> {
  const UserDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Открыть в VK'),
                      onPressed: controller.user.value == null
                          ? null
                          : () => controller.openVkProfile(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.message),
                        label: const Text('Написать'),
                        onPressed: controller.user.value == null
                            ? null
                            : () => controller.sendMessage(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.black,
                        )),
                  ],
                )),
        ],
      ),
      body: Obx(() {
        // Show loading indicator when starting to load
        if (controller.isLoading.value) {
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

        // Show error state if no user is available after loading
        if (controller.user.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text("Не удалось загрузить профиль."),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Вернуться назад'),
                  onPressed: () {
                    // Use the main route directly instead of Get.back()
                    Get.offAllNamed(Routes.MAIN);
                  },
                )
              ],
            ),
          );
        }

        // User data is available
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailedProfile(controller: controller),
              // Conditionally display Photos section header
              if (controller.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                  child: _buildSectionHeader(
                    title: 'Фотографии (${controller.photos.length})',
                    icon: Icons.photo_library,
                    context: context,
                  ),
                ),
              PhotosGallery(photos: controller.photos),
              const SizedBox(height: 16),
              // Pass the dedicated groups observable
              UserGroupsList(
                groups: controller.groups,
                isLoading: controller.isLoading.value,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // Helper extracted for reuse
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
          // Use Expanded to prevent overflow with long titles
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class DetailedProfile extends StatelessWidget {
  const DetailedProfile({
    super.key,
    required this.controller,
  });

  final UserDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.user.value;
    if (user == null) return const SizedBox.shrink();

    // Debug user data
    print("Building DetailedProfile UI with user data:");
    print("  Status from user object: '${user.status}'");
    print("  Relation from user object: ${user.relation}");
    print("  Status from direct field: '${controller.status.value}'");
    print("  Relation from direct field: ${controller.relation.value}");

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header with avatar and basic info
          Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Hero(
              tag: 'user_avatar_${user.userID}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: NetworkImage(user.avatar ?? ''),
                  backgroundColor:
                  Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Basic info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name} ${user.surname}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  // Online status
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color:
                        user.online == true ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(user.online == true ? 'В сети' : 'Не в сети',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: user.online == true
                                ? Colors.green
                                : Colors.grey,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  if (user.city != null || user.country != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: _buildInfoRow(
                          icon: Icons.location_on,
                          text: [
                            if (user.city != null) user.city,
                            if (user.country != null) user.country,
                          ].join(', '),
                          context: context),
                    ),

                  // Birthday if available
                  if (user.bdate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: _buildInfoRow(
                          icon: Icons.cake,
                          text: user.bdate!,
                          context: context),
                    ),

                  // Relationship status - Use direct field instead of user object
                  Obx(() {
                    final relationValue = controller.relation.value;
                    if (relationValue != null && relationValue != 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: _buildInfoRow(
                            icon: Icons.favorite,
                            text: _getRelationshipStatus(relationValue),
                            context: context,
                            primaryColor: true),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Status - Use direct field instead of user object
        Obx(() {
      final statusValue = controller.status.value;
      if (statusValue.isNotEmpty && statusValue != 'null') {
        return Card(
            elevation: 1,
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            margin: EdgeInsets.zero, // remove default card margin
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: Theme.of(context).dividerColor, width: 0.5)),
            child: Padding(
            padding: const EdgeInsets.all(12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.format_quote,
            color: Theme.of(context).colorScheme.primary,
            size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            statusValue,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.primary
            ),
          ),
        ),
      ],
    ),
            ),
        );
      }
      return const SizedBox.shrink();
        }),

            const SizedBox(height: 20),

            // About section if available
            if (user.about != null && user.about!.isNotEmpty && user.about != 'null')
              _buildSection(
                context: context,
                title: 'О себе',
                icon: Icons.person_outline,
                contentWidget: Text(
                  user.about!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

            // Interests section if available
            if (user.interests.isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.only(top: 20.0), // Add consistent spacing
                child: _buildSection(
                  context: context,
                  title: 'Интересы',
                  icon: Icons.interests_outlined,
                  contentWidget: Wrap(
                    spacing: 8,
                    runSpacing: 4, // Reduced run spacing
                    children: user.interests
                        .map((interest) => Chip(
                      label: Text(interest),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.6),
                      labelStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16), // Less round
                        side: BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4), // Adjust padding
                      materialTapTargetSize: MaterialTapTargetSize
                          .shrinkWrap, // Tighter tap area
                    ))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  // Helper for icon + text rows with an option to use primary color
  Widget _buildInfoRow(
      {required IconData icon,
        required String text,
        required BuildContext context,
        bool primaryColor = false}) {
    final textColor = primaryColor
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodySmall?.color;

    return Row(
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: textColor),
            overflow:
            TextOverflow.ellipsis, // Handle potentially long location names
            maxLines: 2, // Allow wrapping for longer texts
          ),
        ),
      ],
    );
  }

  // Updated _buildSection to accept a widget for content
  Widget _buildSection(
      {required BuildContext context,
        required String title,
        required IconData icon,
        required Widget contentWidget // Use a widget instead of string
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12), // Increased space
        Padding(
          // Add left padding for the content
          padding: const EdgeInsets.only(left: 4.0), // Small indent
          child: contentWidget,
        ),
      ],
    );
  }

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
        return 'Не указано';
      default:
        return 'Не указано';
    }
  }
}

// --- NEW WIDGET FOR GROUPS ---
class UserGroupsList extends StatelessWidget {
  final List<VKGroupInfo> groups;
  final bool isLoading;

  const UserGroupsList({
    required this.groups,
    required this.isLoading,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(
        "UserGroupsList build: ${groups.length} groups, isLoading: $isLoading"); // Debug log

    // Don't show anything if loading is finished and groups are empty
    if (!isLoading && groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserDetailsPage(key: key)._buildSectionHeader(
              title: 'Группы',
              icon: Icons.group_work_outlined,
              context: context,
            ),
            const SizedBox(height: 12),
            Text(
              'Нет информации о группах или профиль скрыт.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Use NumberFormat for thousands separator
    final formatter = NumberFormat('#,###', 'ru_RU');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserDetailsPage(key: key)._buildSectionHeader(
            title: 'Группы (${groups.length})',
            icon: Icons.group_work_outlined,
            context: context,
          ),
          const SizedBox(height: 12),

          // Show loading indicator specifically for groups if needed
          if (isLoading && groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text("Загрузка групп..."),
                ],
              ),
            ),

          // Display the groups
          if (groups.isNotEmpty)
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                String membersText = 'Участников: ?';
                if (group.membersCount != null) {
                  membersText =
                      '${formatter.format(group.membersCount)} участ.';
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(group.avatarUrl),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  title: Text(group.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(membersText,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              },
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 0.5, indent: 60),
            ),
        ],
      ),
    );
  }
}
// --- END NEW WIDGET ---

class PhotosGallery extends StatelessWidget {
  // ... existing PhotosGallery code ...
  final List<String> photos;

  const PhotosGallery({
    required this.photos,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // If photos are empty, return SizedBox.shrink() BUT keep the header outside
    if (photos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      // Consider adjusting height based on whether groups are present?
      // Maybe a fixed height is better for consistency.
      height: size.height * 0.35, // Reduced height a bit
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // Added vertical padding
        shrinkWrap: false,
        // Allow internal scrolling
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Keep 2 rows for horizontal scroll
          crossAxisSpacing: 10, // Reduced spacing
          mainAxisSpacing: 10, // Reduced spacing
          childAspectRatio:
              0.8, // Adjust aspect ratio if needed (taller images?)
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, photos, index),
            child: Hero(
              tag: 'photo_$index',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.15), // Slightly darker shadow
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, widget, imageLoadingProgress) {
                      if (imageLoadingProgress == null) return widget;
                      return Container(
                        // Add background during loading
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: imageLoadingProgress.cumulativeBytesLoaded /
                                (imageLoadingProgress.expectedTotalBytes ?? 1),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
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

  void _showFullScreenImage(
      BuildContext context, List<String> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black, // Keep black background
          appBar: AppBar(
              backgroundColor:
                  Colors.black.withOpacity(0.5), // Semi-transparent AppBar
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )),
          body: Container(
            // Wrap PageView for safe area handling etc.
            color: Colors.black,
            child: PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Hero(
                    tag: 'photo_$index',
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8, // Allow slightly smaller zoom out
                      maxScale: 4.0, // Allow more zoom in
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.contain,
                        loadingBuilder:
                            (context, widget, imageLoadingProgress) {
                          if (imageLoadingProgress == null) return widget;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Colors.white.withOpacity(0.7),
                              // Make indicator slightly transparent
                              value: imageLoadingProgress
                                      .cumulativeBytesLoaded /
                                  (imageLoadingProgress.expectedTotalBytes ??
                                      1),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                                child: Icon(Icons.error,
                                    color: Colors.red, size: 50)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
