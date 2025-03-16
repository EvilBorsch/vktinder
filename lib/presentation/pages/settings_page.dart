import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class SettingsPage extends GetView {
  SettingsPage({Key? key}) : super(key: key);

  final _vkTokenController = TextEditingController();
  final _defaultMsgController = TextEditingController();
  final _themeChoice = RxString('system');

  @override
  Widget build(BuildContext context) {
    // Initialize controllers with current values
    _vkTokenController.text = controller.vkToken;
    _defaultMsgController.text = controller.defaultMessage;
    _themeChoice.value = controller.selectedTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _vkTokenController,
            decoration: const InputDecoration(
              labelText: 'VK токен',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _defaultMsgController,
            decoration: const InputDecoration(
              labelText: 'Сообщение при свайпе',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => DropdownButtonFormField(
            value: _themeChoice.value,
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
                _themeChoice.value = value;
              }
            },
          )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _onSave(),
            child: const Text(
              'Сохранить',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onSave() async {
    await controller.save(
      _vkTokenController.text,
      _defaultMsgController.text,
      _themeChoice.value,
    );

    Get.snackbar(
      'Успех',
      'Настройки сохранены',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }
}