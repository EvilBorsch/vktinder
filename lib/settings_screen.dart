import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController {
  String vkToken;
  String defaultMessage;

  /// Holds user's desired theme mode: "system", "light", or "dark".
  String selectedTheme;

  SettingsController({
    required this.vkToken,
    required this.defaultMessage,
    required this.selectedTheme,
  });

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController(
      vkToken: prefs.getString('vkToken') ?? '',
      defaultMessage: prefs.getString('defaultMessage') ?? '',
      selectedTheme: prefs.getString('selectedTheme') ?? 'system',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vkToken', vkToken);
    await prefs.setString('defaultMessage', defaultMessage);
    await prefs.setString('selectedTheme', selectedTheme);
  }
}

class SettingsScreen extends StatefulWidget {
  final SettingsController controller;
  final VoidCallback onThemeChange;

  const SettingsScreen({
    super.key,
    required this.controller,
    required this.onThemeChange,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _c1;
  late TextEditingController _c2;
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _c1 = TextEditingController(text: widget.controller.vkToken);
    _c2 = TextEditingController(text: widget.controller.defaultMessage);
    _selectedTheme = widget.controller.selectedTheme;
  }

  Future<void> _onSave() async {
    widget.controller.vkToken = _c1.text;
    widget.controller.defaultMessage = _c2.text;
    widget.controller.selectedTheme = _selectedTheme;
    await widget.controller.save();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
    widget.onThemeChange();
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
            controller: _c1,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'VK токен',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _c2,
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
