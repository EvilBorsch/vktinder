import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_controller.dart';

class HomeScreen extends StatefulWidget {
  final SettingsController controller;
  const HomeScreen({Key? key, required this.controller}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasLoaded = false;
  final _rand = Random();
  List<VKGroupUser> _groupUserInfo = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleSettingsChange);
    _loadCards();
  }

  void _handleSettingsChange() {
    // If the token changes, reload cards
    _loadCards();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSettingsChange);
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() => _hasLoaded = false);
    if (widget.controller.vkToken.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final storedCardsRaw = prefs.getString('persisted_cards');
      if (storedCardsRaw != null && storedCardsRaw.isNotEmpty) {
        final List decoded = jsonDecode(storedCardsRaw);
        _groupUserInfo =
            decoded
                .map(
                  (item) => VKGroupUser.fromJson(item as Map<String, dynamic>),
                )
                .toList();
      } else {
        _generateInitialCards();
      }
    } else {
      _groupUserInfo.clear();
    }
    setState(() => _hasLoaded = true);
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persisted_cards', jsonEncode(_groupUserInfo));
  }

  void _generateInitialCards() {
    _groupUserInfo.clear();
    // Generate 5 random cards
    for (int i = 0; i < 5; i++) {
      final randomWord = 'Random #${_rand.nextInt(1000)}';
      _groupUserInfo.add(
        VKGroupUser(
          name: '$randomWord + ${widget.controller.vkToken}',
          surname: "constant surname",
        ),
      );
    }
    _saveCards();
  }

  Future<void> _sendVKMessage(String msg) async {
    // Replace with real messaging logic if needed
    debugPrint("Sending message to VK: $msg");
  }

  Future<void> _showSwipeDialog() async {
    final inputController = TextEditingController(
      text: widget.controller.defaultMessage,
    );
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Что напишем?'),
            content: TextField(
              controller: inputController,
              decoration: const InputDecoration(
                labelText: 'Сообщение',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Не писать'),
              ),
              TextButton(
                onPressed: () {
                  _sendVKMessage(inputController.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Отправить'),
              ),
            ],
          ),
    );
  }

  void _dismissTopCard(DismissDirection dir) async {
    if (_groupUserInfo.isNotEmpty) {
      _groupUserInfo.removeAt(0);
      if (dir == DismissDirection.startToEnd) {
        await _showSwipeDialog();
      }
      if (_groupUserInfo.isEmpty) {
        _generateInitialCards();
      } else {
        _saveCards();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.controller.vkToken.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Задайте VK Token в настройках",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(_groupUserInfo.length, (index) {
              final cardIndex = _groupUserInfo.length - 1 - index;
              final cardUserInfo = _groupUserInfo[cardIndex];
              return Dismissible(
                key: ValueKey(cardUserInfo),
                direction: DismissDirection.horizontal,
                resizeDuration: null,
                onDismissed: (dir) => _dismissTopCard(dir),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: VKGroupUserWidget(userInfo: cardUserInfo),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// Simple model for a "VKGroupUser"
class VKGroupUser {
  final String name;
  final String surname;

  const VKGroupUser({required this.name, required this.surname});

  Map<String, dynamic> toJson() => {'name': name, 'surname': surname};

  factory VKGroupUser.fromJson(Map<String, dynamic> json) => VKGroupUser(
    name: json['name'] as String,
    surname: json['surname'] as String,
  );

  @override
  String toString() => '{name: $name, surname: $surname}';
}

class VKGroupUserWidget extends StatelessWidget {
  final VKGroupUser userInfo;
  const VKGroupUserWidget({Key? key, required this.userInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox.expand(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userInfo.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  userInfo.surname,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
