// --- File: lib/presentation/pages/full_user_info.dart ---
// lib/presentation/pages/full_user_info.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/data/models/vk_group_info.dart';
import 'package:vktinder/presentation/controllers/user_detail_controller.dart';
import 'package:vktinder/routes/app_pages.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:transparent_image/transparent_image.dart'; // If using

// Placeholder for kTransparentImage
final kTransparentImage = Uri.parse(
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7')
    .data!
    .contentAsBytes();

class UserDetailsPage extends GetView<UserDetailsController> {
  const UserDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('ru_RU');
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
            controller.user.value != null
                ? '${controller.user.value!.name} ${controller.user.value!.surname}'
                : 'Профиль',
            overflow: TextOverflow.ellipsis)),
        actions: [
          Obx(() => controller.isLoading.value && controller.user.value == null
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- UPDATED: More Visible Button ---
                    Padding(
                      // Add some vertical padding to align better and horizontal for spacing
                      padding: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        // Keep icon small
                        label: const Text('Открыть в VK'),
                        // Concise label
                        onPressed: controller.user.value == null
                            ? null
                            : () => controller.openVkProfile(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          // Adjust horizontal padding
                          visualDensity: VisualDensity.comfortable,
                          // Make button height less imposing
                          // Optionally customize colors if defaults aren't enough:
                          // backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          // foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          elevation: 2, // Slight elevation
                        ),
                      ),
                    ),
                    const SizedBox(width: 4), // Smaller space between buttons

                    // --- Keep message button as IconButton for contrast ---
                    IconButton(
                      icon: const Icon(Icons.message_outlined),
                      tooltip: 'Написать сообщение',
                      onPressed: controller.user.value == null
                          ? null
                          : () => controller.sendMessage(),
                    ),
                    const SizedBox(width: 8), // Padding at the end
                  ],
                )),
        ],
      ),
      body: Obx(() {
        // --- Loading State ---
        if (controller.isLoading.value && controller.user.value == null) {
          return const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка профиля...')
              ]));
        }
        // --- Error State ---
        if (!controller.isLoading.value && controller.user.value == null) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            const Text("Не удалось загрузить профиль",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(
                                controller.isLoading.value
                                    ? 'Проверьте ID или токен'
                                    : 'Пользователь не найден или произошла ошибка.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey[600], height: 1.4)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Вернуться назад'),
                                onPressed: () {
                                  if (Get.key.currentState?.canPop() ?? false) {
                                    Get.back();
                                  } else {
                                    Get.offAllNamed(Routes.MAIN);
                                  }
                                })
                          ])))));
        }
        // --- Content State ---
        return RefreshIndicator(
          onRefresh: () async {
            if (controller.user.value != null) {
              await controller.loadFullProfile(controller.user.value!.userID);
            }
          },
          child: ListView(
            // Main vertical scroll
            padding: EdgeInsets.zero,
            children: [
              DetailedProfileHeader(controller: controller),
              const SizedBox(height: 16),

              // Status Section
              Obx(() {
                /* ... Status code same as before ... */
                final statusValue = controller.status.value;
                if (statusValue.isNotEmpty && statusValue != 'null') {
                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSection(
                          context: context,
                          title: 'Статус',
                          icon: Icons.format_quote,
                          contentWidget: Text(statusValue,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontStyle: FontStyle.italic))));
                }
                return const SizedBox.shrink();
              }),
              if (controller.status.value.isNotEmpty &&
                  controller.status.value != 'null')
                const SizedBox(height: 16),

              // About Section
              Obx(() {
                /* ... About code same as before ... */
                final aboutText = controller.user.value?.about;
                if (aboutText != null &&
                    aboutText.isNotEmpty &&
                    aboutText != 'null') {
                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSection(
                          context: context,
                          title: 'О себе',
                          icon: Icons.person_outline,
                          contentWidget: Text(aboutText,
                              style: Theme.of(context).textTheme.bodyLarge)));
                }
                return const SizedBox.shrink();
              }),
              if (controller.user.value?.about != null &&
                  controller.user.value!.about!.isNotEmpty &&
                  controller.user.value!.about != 'null')
                const SizedBox(height: 16),

              // Interests Section
              Obx(() {
                /* ... Interests code same as before ... */
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
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer
                                          .withOpacity(0.7),
                                      labelStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide.none),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap))
                                  .toList())));
                }
                return const SizedBox.shrink();
              }),
              if (controller.user.value?.interests != null &&
                  controller.user.value!.interests.isNotEmpty)
                const SizedBox(height: 16),

              // --- Photos Section ---
              Obx(() {
                // Photos section (structure unchanged)
                final photos = controller.photos;
                if (photos.isEmpty && !controller.isLoading.value) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                          title:
                              'Фотографии${photos.isNotEmpty ? ' (${photos.length})' : ''}',
                          icon: Icons.photo_library_outlined,
                          context: context),
                      const SizedBox(height: 12),
                      PhotosGallery(photos: photos),
                      // PhotosGallery widget itself is unchanged
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16), // Spacing after photos

              UserGroupsList(
                  groups: controller.groups,
                  isLoading: controller.isLoading.value),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // --- Helper Widgets/Methods (No changes) ---
  Widget _buildSectionHeader(
      {required String title,
      required IconData icon,
      required BuildContext context}) {
    /* ... Same ... */
    return Row(children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis))
    ]);
  }

  Widget _buildSection(
      {required BuildContext context,
      required String title,
      required IconData icon,
      required Widget contentWidget}) {
    /* ... Same ... */
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(title: title, icon: icon, context: context),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: contentWidget,
      )
    ]);
  }
}

// --- DetailedProfileHeader Widget (No Changes) ---
class DetailedProfileHeader extends StatelessWidget {
  /* ... Same as previous version ... */
  final UserDetailsController controller;

  const DetailedProfileHeader({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    /* ... Same ... */
    return Obx(() {
      final userName = controller.user.value?.name ?? '...';
      final userSurname = controller.user.value?.surname ?? '...';
      final avatar = controller.avatarUrl.value;
      final isOnline = controller.onlineStatus.value;
      final locationText = controller.location.value;
      final bDateText = controller.bDate.value;
      final relationValue = controller.relation.value;
      final userId = controller.user.value?.userID ?? 'loading';
      return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Hero(
                  tag: 'user_avatar_$userId',
                  child: CircleAvatar(
                      radius: 55,
                      backgroundImage:
                          (avatar.isNotEmpty && avatar.startsWith('http'))
                              ? NetworkImage(avatar)
                              : null,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceVariant,
                      child: (avatar.isEmpty || !avatar.startsWith('http'))
                          ? const Icon(Icons.person, size: 50)
                          : null)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('$userName $userSurname',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.circle,
                          size: 12,
                          color: isOnline ? Colors.green : Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                          isOnline
                              ? 'В сети'
                              : _getLastSeenInfo(
                                      controller.user.value?.lastSeen) ??
                                  'Не в сети',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: isOnline ? Colors.green : Colors.grey))
                    ]),
                    const SizedBox(height: 8),
                    if (locationText.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _buildInfoRow(
                              icon: Icons.location_on_outlined,
                              text: locationText,
                              context: context)),
                    if (bDateText.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _buildInfoRow(
                              icon: Icons.cake_outlined,
                              text: _formatBDate(bDateText),
                              context: context)),
                    if (relationValue != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _buildInfoRow(
                              icon: _getRelationIcon(relationValue),
                              text: _getRelationshipStatus(relationValue),
                              context: context))
                  ]))
            ]),
            const SizedBox(height: 16),
            Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5))
          ]));
    });
  }

  String _formatBDate(String? bdate) {
    /* ... Same ... */ if (bdate == null || bdate.isEmpty) return '';
    try {
      List<String> parts = bdate.split('.');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        DateTime birthDate = DateTime(year, month, day);
        DateTime today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        String formattedDate = DateFormat.yMMMMd('ru_RU').format(birthDate);
        return '$formattedDate ($age ${_getAgeSuffix(age)})';
      } else if (parts.length == 2) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        DateTime birthDate = DateTime(2000, month, day);
        return DateFormat('d MMMM', 'ru_RU').format(birthDate);
      }
    } catch (e) {
      print("Error parsing bdate '$bdate': $e");
      return bdate;
    }
    return bdate;
  }

  String _getAgeSuffix(int age) {
    /* ... Same ... */ if (age % 100 >= 11 && age % 100 <= 14) return 'лет';
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

  String? _getLastSeenInfo(Map<String, dynamic>? lastSeenData) {
    /* ... Same ... */ if (lastSeenData == null ||
        !lastSeenData.containsKey('time')) return null;
    try {
      final int timestamp = lastSeenData['time'];
      final lastSeenDateTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final now = DateTime.now();
      final difference = now.difference(lastSeenDateTime);
      if (difference.inMinutes < 5) return 'недавно';
      if (difference.inHours < 1)
        return 'был(а) ${difference.inMinutes} мин. назад';
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final lastSeenDay = DateTime(
          lastSeenDateTime.year, lastSeenDateTime.month, lastSeenDateTime.day);
      final timeFormat = DateFormat('HH:mm', 'ru_RU');
      final dateFormat = DateFormat('d MMM', 'ru_RU');
      final yearFormat = DateFormat('d MMM yyyy', 'ru_RU');
      if (lastSeenDay == today)
        return 'был(а) сегодня в ${timeFormat.format(lastSeenDateTime)}';
      if (lastSeenDay == yesterday)
        return 'был(а) вчера в ${timeFormat.format(lastSeenDateTime)}';
      if (lastSeenDateTime.year == now.year)
        return 'был(а) ${dateFormat.format(lastSeenDateTime)} в ${timeFormat.format(lastSeenDateTime)}';
      return 'был(а) ${yearFormat.format(lastSeenDateTime)}';
    } catch (e) {
      print("Error formatting last seen: $e");
      return null;
    }
  }

  Widget _buildInfoRow(
      {required IconData icon,
      required String text,
      required BuildContext context,
      bool primaryColor = false}) {
    /* ... Same ... */
    final textColor = primaryColor
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodyMedium?.color;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 16, color: textColor)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textColor))),
    ]);
  }

  IconData _getRelationIcon(int relation) {
    /* ... Same ... */ switch (relation) {
      case 1:
        return Icons.person_outline;
      case 2:
        return Icons.favorite_border;
      case 3:
        return Icons.ring_volume_outlined;
      case 4:
        return Icons.favorite;
      case 5:
        return Icons.sync_problem_outlined;
      case 6:
        return Icons.search;
      case 7:
        return Icons.sentiment_satisfied_alt_outlined;
      case 8:
        return Icons.home_work_outlined;
      case 0:
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getRelationshipStatus(int relation) {
    /* ... Same ... */ switch (relation) {
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
        return 'Статус не указан';
      default:
        return 'Статус не указан';
    }
  }
}

// --- UserGroupsList Widget (No Changes) ---
class UserGroupsList extends StatelessWidget {
  /* ... Same as previous version ... */
  final List<VKGroupInfo> groups;
  final bool isLoading;

  const UserGroupsList(
      {required this.groups, required this.isLoading, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading && groups.isEmpty) {
      return const SizedBox.shrink();
    }
    final formatter = NumberFormat('#,###', 'ru_RU');
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UserDetailsPage(key: key)._buildSectionHeader(
              title:
                  'Группы и паблики${groups.isNotEmpty ? ' (${groups.length})' : ''}',
              icon: Icons.group_work_outlined,
              context: context),
          const SizedBox(height: 12),
          if (isLoading && groups.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2))),
          if (groups.isNotEmpty)
            ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  String membersText = 'Подписчиков: ?';
                  if (group.membersCount != null) {
                    membersText =
                        '${formatter.format(group.membersCount)} подпис.';
                  }
                  return ListTile(
                      leading: CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(group.avatarUrl),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant),
                      title: Text(group.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(membersText,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 0),
                      onTap: () => _openVkGroup(group.screenName),
                      visualDensity: VisualDensity.compact);
                },
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, thickness: 0.5, indent: 52))
        ]));
  }

  void _openVkGroup(String screenName) async {
    /* ... Same ... */ if (screenName.isEmpty) return;
    final url = 'https://vk.com/$screenName';
    final uri = Uri.parse(url);
    try {
      bool launched = false;
      if (!GetPlatform.isWeb) {
        try {
          launched = await launchUrl(Uri.parse('vk://vk.com/$screenName'),
              mode: LaunchMode.externalApplication);
        } catch (e) {
          print("Failed vk://vk.com/ link for group: $e");
        }
      }
      if (!launched) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось открыть группу: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

// --- PhotosGallery Widget (Grid, 2 rows, horizontal scroll - Unchanged from previous fix) ---
class PhotosGallery extends StatelessWidget {
  final List<String> photos;

  const PhotosGallery({required this.photos, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserDetailsController>();
    if (photos.isEmpty) {
      if (!controller.isLoading.value) {
        return const SizedBox.shrink();
      } else {
        return const SizedBox.shrink();
      }
    }
    const double itemHeight = 200.0;
    const double crossAxisSpacing = 8.0;
    const double mainAxisSpacing = 8.0;
    const double childAspectRatio = 4 / 5;
    const double totalGalleryHeight = (itemHeight * 2) + crossAxisSpacing;

    return SizedBox(
        height: totalGalleryHeight,
        child: GridView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photoUrl = photos[index];
              return GestureDetector(
                  onTap: () => _showFullScreenImage(context, photos, index),
                  child: Hero(
                      tag: 'photo_$index',
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(photoUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant,
                                    child: Center(
                                        child: Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null))));
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      child: Center(
                                          child: Icon(
                                              Icons.broken_image_outlined,
                                              size: 40,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withOpacity(0.5))))))));
            }));
  }

  void _showFullScreenImage(
      BuildContext context, List<String> photos, int initialIndex) {
    /* ... Same as previous version ... */
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black.withOpacity(animation.value),
          appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop())),
          body: Container(
            color: Colors.transparent,
            child: PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Center(
                    child: Hero(
                        tag: 'photo_$index',
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 5.0,
                          // child: FadeInImage.memoryNetwork(placeholder: kTransparentImage, image: photos[index], fit: BoxFit.contain, imageErrorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50))), // If using transparent_image
                          child: Image.network(photos[index],
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, widget, imageLoadingProgress) {
                                if (imageLoadingProgress == null) return widget;
                                return Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white.withOpacity(0.7),
                                        value: imageLoadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? imageLoadingProgress
                                                    .cumulativeBytesLoaded /
                                                imageLoadingProgress
                                                    .expectedTotalBytes!
                                            : null));
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Icon(Icons.error,
                                          color: Colors.red, size: 50))),
                        )));
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
// --- END PhotosGallery Widget ---
