import 'package:flutter/material.dart';
import 'package:vktinder/data/models/home_screen.dart';
import 'package:vktinder/domain/user_group_info.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';
import 'package:vktinder/presentation/widgets/user_preview.dart';

class HomeScreen extends StatefulWidget {
  final SettingsController settingsController;
  final GroupUsersUsecase usecase;

  const HomeScreen({
    super.key,
    required this.settingsController,
    required this.usecase,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasLoaded = false;
  List<VKGroupUser> _groupUserInfo = [];

  @override
  void initState() {
    super.initState();
    widget.settingsController.addListener(_loadCards);

    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _hasLoaded = false);
    _groupUserInfo = await widget.usecase.get(
      widget.settingsController.settings.vkToken,
    );
    setState(() => _hasLoaded = true);
  }

  Future<void> _sendVKMessage(String msg) async {
    // Replace with real messaging logic if needed
    debugPrint("Sending message to VK: $msg");
  }

  Future<void> _showSwipeDialog() async {
    final inputController = TextEditingController(
      text: widget.settingsController.settings.defaultMessage,
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
    if (dir == DismissDirection.startToEnd) {
      await _showSwipeDialog();
    }
    _groupUserInfo = await widget.usecase.removeFirst(
      widget.settingsController.settings.vkToken,
      _groupUserInfo,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.settingsController.settings.vkToken.isEmpty) {
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
