import 'package:flutter/material.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _vkTokenController;
  late TextEditingController _defaultMsgController;
  late String _themeChoice;

  @override
  void initState() {
    super.initState();
    _vkTokenController = TextEditingController(
      text: widget.controller.settings.vkToken,
    );
    _defaultMsgController = TextEditingController(
      text: widget.controller.settings.defaultMessage,
    );
    _themeChoice = widget.controller.settings.selectedTheme;
  }

  Future<void> _onSave() async {
    widget.controller.settings = Settings(
      vkToken: _vkTokenController.text,
      defaultMessage: _defaultMsgController.text,
      selectedTheme: _themeChoice,
    );
    await widget.controller.save();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Настройки сохранены'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
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
          DropdownButtonFormField<String>(
            value: _themeChoice,
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
                setState(() => _themeChoice = value);
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onSave,
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
