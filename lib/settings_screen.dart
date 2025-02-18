import 'package:flutter/material.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController controller;
  const SettingsScreen({Key? key, required this.controller}) : super(key: key);

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
    _vkTokenController = TextEditingController(text: widget.controller.vkToken);
    _defaultMsgController = TextEditingController(
      text: widget.controller.defaultMessage,
    );
    _themeChoice = widget.controller.selectedTheme;
  }

  Future<void> _onSave() async {
    widget.controller.vkToken = _vkTokenController.text;
    widget.controller.defaultMessage = _defaultMsgController.text;
    widget.controller.selectedTheme = _themeChoice;
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _vkTokenController,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'VK токен',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _defaultMsgController,
            style: theme.textTheme.bodyMedium,
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
