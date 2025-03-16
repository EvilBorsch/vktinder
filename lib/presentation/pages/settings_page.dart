import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create controllers with current values
    final vkTokenController = TextEditingController(text: controller.vkToken);
    final defaultMsgController = TextEditingController(text: controller.defaultMessage);
    final themeChoice = controller.selectedTheme.obs;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: vkTokenController,
            decoration: const InputDecoration(
              labelText: 'VK токен',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: defaultMsgController,
            decoration: const InputDecoration(
              labelText: 'Сообщение при свайпе',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => DropdownButtonFormField<String>(
            value: themeChoice.value,
            decoration: const InputDecoration(
              labelText: 'Выберите тему',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('Системная')),
              DropdownMenuItem(value: 'light', child: Text('Светлая')),
              DropdownMenuItem(value: 'dark', child: Text('Тёмная')),
            ],
            onChanged: (value) {
              if (value != null) {
                themeChoice.value = value;
              }
            },
          )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              controller.save(
                vkTokenController.text,
                defaultMsgController.text,
                themeChoice.value,
              );

              Get.snackbar(
                'Успех',
                'Настройки сохранены',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
              );
            },
            child: const Text(
              'Сохранить',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}