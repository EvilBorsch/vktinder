import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vktinder/settings_controller.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final SettingsController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VKGroupUser> _groupUserInfo = [];
  final _rand = Random();
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _loadCards();
  }

  /// Reload if token changes
  void _onControllerChanged() {
    _loadCards();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  /// Load cards from SharedPreferences (if they exist).
  Future<void> _loadCards() async {
    _hasLoaded = false;
    if (widget.controller.vkToken.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      var storedCardsRaw = prefs.getString('persisted_cards');
      if (storedCardsRaw != null && storedCardsRaw.isNotEmpty) {
        _groupUserInfo = jsonDecode(storedCardsRaw);
        debugPrint(
          "Loaded existing cards from SharedPreferences: $_groupUserInfo",
        );
      } else {
        _generateCards();
      }
    } else {
      _groupUserInfo.clear();
      debugPrint("vkToken is empty; clearing cards");
    }
    _hasLoaded = true;
    setState(() {});
  }

  /// Save cards to SharedPreferences.
  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    String marshalledGroupUserInfo = jsonEncode(_groupUserInfo);
    await prefs.setString('persisted_cards', marshalledGroupUserInfo);
    debugPrint("Saved cards to SharedPreferences: $_groupUserInfo");
  }

  void _generateCards() {
    _groupUserInfo.clear();
    for (int i = 0; i < 5; i++) {
      final randomWord = 'Random #${_rand.nextInt(1000)}';
      _groupUserInfo.add(
        VKGroupUser(
          name:
              '$randomWord + ${widget.controller.vkToken} + ${widget.controller.defaultMessage}',
          surname: "constant surname",
        ),
      );
    }
    debugPrint("Generating new cards: $_groupUserInfo");
    _saveCards(); // Save new set to SharedPreferences
  }

  Future<void> sendVKMessage(String msg) async {
    debugPrint("Sending message to vk $msg");
  }

  Future<void> _showSwipeDialog() async {
    final inputController = TextEditingController(
      text: widget.controller.defaultMessage,
    );
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
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
              child: const Text('Не будем писать'),
            ),
            TextButton(
              onPressed:
                  () => {
                    sendVKMessage(inputController.text),
                    Navigator.of(context).pop(),
                  },
              child: const Text('Отправляем'),
            ),
          ],
        );
      },
    );
  }

  void _removeTopCard() {
    if (_groupUserInfo.isNotEmpty) {
      _groupUserInfo.removeAt(0);
    }
    if (_groupUserInfo.isEmpty) {
      // Regenerate if empty
      _generateCards();
    } else {
      // Otherwise, just save the updated list
      _saveCards();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    // Wait for the async data to load
    if (!_hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // If vkToken is empty, skip showing any cards and prompt user
    if (widget.controller.vkToken.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                onDismissed: (dir) async {
                  _removeTopCard();
                  if (dir == DismissDirection.startToEnd) {
                    await _showSwipeDialog();
                  }
                },
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

class VKGroupUser {
  final String name;
  final String surname;

  const VKGroupUser({required this.name, required this.surname});

  Map toJson() => {'name': name, 'surname': surname};
}

class VKGroupUserWidget extends StatelessWidget {
  final VKGroupUser userInfo;
  const VKGroupUserWidget({super.key, required this.userInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox.expand(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  userInfo.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
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
