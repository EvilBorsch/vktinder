import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => _buildSettingsForm()),
    );
  }

  Widget _buildSettingsForm() {
    // Create controllers with current values
    final vkTokenController = TextEditingController(text: controller.vkToken);
    final defaultMsgController =
        TextEditingController(text: controller.defaultMessage);
    final themeValue = controller.theme.obs;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // VK Token Input
        const Text(
          'VK Токен',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: vkTokenController,
          decoration: const InputDecoration(
            hintText: 'Введите VK токен',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.key),
          ),
        ),
        const SizedBox(height: 24),

        // Default Message Input
        const Text(
          'Стандартное сообщение',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: defaultMsgController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Стандартный текст сообщения',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.message),
          ),
        ),
        const SizedBox(height: 24),

        // Theme Selection
        const Text(
          'Тема приложения',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Card(
              elevation: 2,
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Системная'),
                    value: 'system',
                    groupValue: themeValue.value,
                    onChanged: (value) {
                      if (value != null) themeValue.value = value;
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Светлая'),
                    value: 'light',
                    groupValue: themeValue.value,
                    onChanged: (value) {
                      if (value != null) themeValue.value = value;
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Темная'),
                    value: 'dark',
                    groupValue: themeValue.value,
                    onChanged: (value) {
                      if (value != null) themeValue.value = value;
                    },
                  ),
                ],
              ),
            )),
        const SizedBox(height: 32),

        // Save Button
        ElevatedButton.icon(
          onPressed: () {
            controller.saveSettings(
              vkToken: vkTokenController.text.trim(),
              defaultMessage: defaultMsgController.text.trim(),
              theme: themeValue.value,
            );
          },
          icon: const Icon(Icons.save),
          label: const Text(
            'Сохранить настройки',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
