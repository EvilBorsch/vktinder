import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController {
  String vkToken;
  String defaultMessage;

  SettingsController({required this.vkToken, required this.defaultMessage});

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController(
      vkToken: prefs.getString('vkToken') ?? '',
      defaultMessage: prefs.getString('defaultMessage') ?? '',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vkToken', vkToken);
    await prefs.setString('defaultMessage', defaultMessage);
  }
}

class SettingsScreen extends StatefulWidget {
  final SettingsController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _c1;
  late TextEditingController _c2;

  @override
  void initState() {
    super.initState();
    _c1 = TextEditingController(text: widget.controller.vkToken);
    _c2 = TextEditingController(text: widget.controller.defaultMessage);
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.vkToken != _c1.text) {
      _c1.text = widget.controller.vkToken;
    }
    if (widget.controller.defaultMessage != _c2.text) {
      _c2.text = widget.controller.defaultMessage;
    }
  }

  Future<void> _onSave() async {
    widget.controller.vkToken = _c1.text;
    widget.controller.defaultMessage = _c2.text;
    await widget.controller.save();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _c1,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'VK токен',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _c2,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Сообщение при свайпе',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _onSave, child: const Text('Сохранить')),
      ],
    );
  }
}
