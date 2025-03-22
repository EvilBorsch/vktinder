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
        title: Text("Подробнее"),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              DetailedAbout(controller: controller),
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

class DetailedAbout extends StatelessWidget {
  const DetailedAbout({
    super.key,
    required this.controller,
  });

  final UserDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(
        radius: 40,
        backgroundImage:
            NetworkImage(controller.user.value?.avatar ?? ''),
      ),
      const SizedBox(height: 16),
      Text(
        '${controller.user.value?.name} ${controller.user.value?.surname}',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      if (controller.user.value?.groups != null)
        Text(
          'Groups: ${controller.user.value?.groups?.join(', ') ?? ''}',
          style: const TextStyle(color: Colors.grey),
        ),
      const SizedBox(height: 16),
      if (controller.user.value?.interests != null)
        Text(
          'Interests: ${controller.user.value?.interests?.join(', ') ?? ''}',
          style: const TextStyle(color: Colors.grey),
        ),
      const SizedBox(height: 16),
    ]);
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
        const Text(
          'Photos',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: size.height * 0.4, // 40% of the screen height
          child: GridView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
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
                      Icon(Icons.error, color: Colors.red),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
