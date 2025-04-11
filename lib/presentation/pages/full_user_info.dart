import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/user_detail_controller.dart';

class UserDetailsPage extends GetView<UserDetailsController> {
  const UserDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Подробная информация"),
        actions: [
          Obx(() => controller.isLoading.value
              ? const SizedBox.shrink()
              : IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => controller.sendMessage(),
          )
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              DetailedProfile(controller: controller),
              PhotosGallery(
                photos: controller.user.value?.photos ?? [],
              ),
            ],
          ),
        );
      }),
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
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(user.avatar ?? ''),
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Online status
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: user.online == true
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  user.online == true
                      ? 'В сети'
                      : 'Не в сети',
                  style: TextStyle(
                    color: user.online == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location
            if (user.city != null || user.country != null)
        Row(
    children: [
    const Icon(Icons.location_on,
        size: 16,
        color: Colors.grey
    ),
    const SizedBox(width: 4),
    Expanded(
    child: Text(
    [
    if (user.city != null) user.city,
    if (user.country != null) user.country,
    ].join(', '),
    style: const TextStyle(color: Colors.grey),
    ),
    ),
    ],
        ),

                // Birthday if available
                if (user.bdate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.cake,
                            size: 16,
                            color: Colors.grey
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.bdate!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                // Relationship status if available
                if (user.relation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite,
                            size: 16,
                            color: Colors.grey
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getRelationshipStatus(user.relation!),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ),
          ],
          ),

            const SizedBox(height: 24),

            // Status if available
            if (user.status != null && user.status!.isNotEmpty)
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.format_quote, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.status!,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // About section if available
            if (user.about != null && user.about!.isNotEmpty)
              _buildSection(
                context: context,
                title: 'О себе',
                icon: Icons.person,
                content: user.about!,
              ),

            // Interests section if available
            if (user.interests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.interests, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Интересы',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests.map((interest) =>
                          Chip(
                            label: Text(interest),
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          )
                      ).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String content
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  String _getRelationshipStatus(int relation) {
    switch (relation) {
      case 1: return 'Не женат/не замужем';
      case 2: return 'Есть друг/подруга';
      case 3: return 'Помолвлен(а)';
      case 4: return 'Женат/замужем';
      case 5: return 'Всё сложно';
      case 6: return 'В активном поиске';
      case 7: return 'Влюблён(а)';
      case 8: return 'В гражданском браке';
      default: return 'Не указано';
    }
  }
}

class PhotosGallery extends StatelessWidget {
  final List<String> photos;

  const PhotosGallery({
    required this.photos,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (photos.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Row(
            children: [
              const Icon(Icons.photo_library, size: 20),
              const SizedBox(width: 8),
              Text(
                'Фотографии (${photos.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: size.height * 0.5, // 50% of the screen height
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
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
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 4,
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
                          return Center(
                            child: CircularProgressIndicator(
                              value: imageLoadingProgress.cumulativeBytesLoaded /
                                  (imageLoadingProgress.expectedTotalBytes ?? 1),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, List<String> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: 'photo_$index',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      photos[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, widget, imageLoadingProgress) {
                        if (imageLoadingProgress == null) return widget;
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value: imageLoadingProgress.cumulativeBytesLoaded /
                                (imageLoadingProgress.expectedTotalBytes ?? 1),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
