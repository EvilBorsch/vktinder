import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simplified Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
    );
  }
}

// A controller that manages two strings, with optional methods to load/save
class SettingsController {
  String value1;
  String value2;
  SettingsController({required this.value1, required this.value2});

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsController(
      value1: prefs.getString('value1') ?? '',
      value2: prefs.getString('value2') ?? '',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('value1', value1);
    await prefs.setString('value2', value2);
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late SettingsController _controller;
  final _pages = <Widget>[];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = await SettingsController.load();
    // Once loaded, build the pages
    _pages.add(HomeScreen(controller: _controller));
    _pages.add(SettingsScreen(controller: _controller));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Simplified Example')),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final SettingsController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cards = <String>[];
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _generateCards();
  }

  void _generateCards() {
    _cards.clear();
    for (int i = 0; i < 5; i++) {
      final randomWord = 'Random #${_rand.nextInt(1000)}';
      _cards.add(
        '$randomWord + ${widget.controller.value1} + ${widget.controller.value2}',
      );
    }
    setState(() {});
  }

  void _removeTopCard() {
    if (_cards.isNotEmpty) {
      _cards.removeAt(0);
    }
    if (_cards.isEmpty) {
      _generateCards();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            readOnly: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Значение (поле 1)',
            ),
            controller: TextEditingController(text: widget.controller.value1),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(_cards.length, (index) {
              final dataIndex = _cards.length - 1 - index;
              return Draggable(
                axis: Axis.horizontal,
                feedback: CardWidget(text: _cards[dataIndex]),
                childWhenDragging: const SizedBox.shrink(),
                onDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx.abs() > 300) {
                    _removeTopCard();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Свайп прошел успешно')),
                    );
                  }
                },
                child: CardWidget(text: _cards[dataIndex]),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 250,
        height: 300,
        child: Center(child: Text(text, textAlign: TextAlign.center)),
      ),
    );
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
    _c1 = TextEditingController(text: widget.controller.value1);
    _c2 = TextEditingController(text: widget.controller.value2);
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller’s values change externally, update our fields
    if (widget.controller.value1 != _c1.text) {
      _c1.text = widget.controller.value1;
    }
    if (widget.controller.value2 != _c2.text) {
      _c2.text = widget.controller.value2;
    }
  }

  Future<void> _onSave() async {
    widget.controller.value1 = _c1.text;
    widget.controller.value2 = _c2.text;
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
            labelText: 'Введите текст (поле 1)',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _c2,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Введите текст (поле 2)',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _onSave, child: const Text('Сохранить')),
      ],
    );
  }
}
