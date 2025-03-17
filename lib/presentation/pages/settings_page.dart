import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
      ),
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
      padding: const EdgeInsets.all(24),
      children: [
        // VK Token Input
        _buildSectionHeader('VK Токен', Icons.key),
        const SizedBox(height: 12),
        TextField(
          controller: vkTokenController,
          decoration: const InputDecoration(
            hintText: 'Введите VK токен',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.key),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Токен необходим для доступа к API ВКонтакте',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 32),

        // Default Message Input
        _buildSectionHeader('Стандартное сообщение', Icons.message),
        const SizedBox(height: 12),
        TextField(
          controller: defaultMsgController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Стандартный текст сообщения',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.message),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Будет использоваться как шаблон при отправке сообщений',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 32),

        // Theme Selection
        _buildSectionHeader('Тема приложения', Icons.palette),
        const SizedBox(height: 12),
        Obx(() => Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildThemeOption(
                    'Системная',
                    'Следовать настройкам системы',
                    Icons.settings_suggest,
                    'system',
                    themeValue,
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    'Светлая',
                    'Использовать светлую тему',
                    Icons.wb_sunny,
                    'light',
                    themeValue,
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    'Темная',
                    'Использовать темную тему',
                    Icons.nights_stay,
                    'dark',
                    themeValue,
                  ),
                ],
              ),
            )),
        const SizedBox(height: 40),

        // Save Button
        ElevatedButton.icon(
          onPressed: () {
            controller.saveSettings(
              vkToken: vkTokenController.text.trim(),
              defaultMessage: defaultMsgController.text.trim(),
              theme: themeValue.value,
            );
          },
          icon: const Icon(Icons.save, size: 24),
          label: const Text(
            'Сохранить настройки',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Get.theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(String title, String subtitle, IconData icon, String value, RxString groupValue) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: groupValue.value,
      onChanged: (value) {
        if (value != null) groupValue.value = value;
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
