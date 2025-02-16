import 'package:flutter/material.dart';
import 'package:vktinder/settings_controller.dart';
import 'package:vktinder/util.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _vkTokenController;
  late TextEditingController _defaultMessageController;
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _vkTokenController = TextEditingController(text: widget.controller.vkToken);
    _defaultMessageController = TextEditingController(
      text: widget.controller.defaultMessage,
    );
    _selectedTheme = widget.controller.selectedTheme;
  }

  Future<void> _onSave() async {
    // Update the controller fields, which triggers notifyListeners()
    widget.controller.vkToken = _vkTokenController.text;
    widget.controller.defaultMessage = _defaultMessageController.text;
    widget.controller.selectedTheme = _selectedTheme;

    // Persist the settings
    await widget.controller.save();

    // Provide user feedback
    toast(context, 'Настройки сохранены');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _vkTokenController,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'VK токен',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _defaultMessageController,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Сообщение при свайпе',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTheme,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Выберите тему',
            ),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('Системная')),
              DropdownMenuItem(value: 'light', child: Text('Светлая')),
              DropdownMenuItem(value: 'dark', child: Text('Тёмная')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedTheme = value);
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _onSave, child: const Text('Сохранить')),
        ],
      ),
    );
  }
}
