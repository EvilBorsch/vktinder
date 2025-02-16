import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vktinder/settings_controller.dart';

class HomeScreen extends StatefulWidget {
  final SettingsController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _cards = [];
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
      final storedCards = prefs.getStringList('persisted_cards');

      if (storedCards != null && storedCards.isNotEmpty) {
        _cards.clear();
        _cards.addAll(storedCards);
        debugPrint("Loaded existing cards from SharedPreferences: $_cards");
      } else {
        _generateCards();
      }
    } else {
      _cards.clear();
      debugPrint("vkToken is empty; clearing cards");
    }
    _hasLoaded = true;
    setState(() {});
  }

  /// Save cards to SharedPreferences.
  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('persisted_cards', _cards);
    debugPrint("Saved cards to SharedPreferences: $_cards");
  }

  void _generateCards() {
    _cards.clear();
    for (int i = 0; i < 5; i++) {
      final randomWord = 'Random #${_rand.nextInt(1000)}';
      _cards.add(
        '$randomWord + ${widget.controller.vkToken} + ${widget.controller.defaultMessage}',
      );
    }
    debugPrint("Generating new cards: $_cards");
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
    if (_cards.isNotEmpty) {
      _cards.removeAt(0);
    }
    if (_cards.isEmpty) {
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
            children: List.generate(_cards.length, (index) {
              final cardIndex = _cards.length - 1 - index;
              final cardText = _cards[cardIndex];
              return Dismissible(
                key: ValueKey(cardText),
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
                  child: CardWidget(text: cardText),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class CardWidget extends StatelessWidget {
  final String text;
  const CardWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox.expand(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
