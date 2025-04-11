import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:get/get.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({Key? key}) : super(key: key);

  // Define controllers here to manage their lifecycle within the page
  // Note: Initialize them in build or initState if needed, or pass from controller if complex
  // For simplicity here, we create them in the build method when needed.

  @override
  Widget build(BuildContext context) {
    // Use Obx only around parts that need to rebuild based on controller state
    return Scaffold(
        appBar: AppBar(
          title: const Text('Настройки'),
          elevation: 1, // Subtle shadow
        ),
        body: Obx(() => _buildSettingsForm(context))); // Rebuild whole form on any change for simplicity now
  }

  Widget _buildSettingsForm(BuildContext context) {
    // Create controllers HERE, initialized with current values from the GetX controller
    // This ensures they reset correctly if the user navigates away and back without saving
    final vkTokenController = TextEditingController(text: controller.vkToken);
    final defaultMsgController = TextEditingController(text: controller.defaultMessage);
    final citiesController = TextEditingController(text: controller.cities.join(', '));
    final ageFromController = TextEditingController(text: controller.ageFrom.value?.toString() ?? '');
    final ageToController = TextEditingController(text: controller.ageTo.value?.toString() ?? '');
    final newGroupUrlController = TextEditingController();
    final themeValue = controller.theme.obs; // Use local obs for RadioListTile

    // Ensure selection is maintained if user edits text field
    vkTokenController.selection = TextSelection.fromPosition(TextPosition(offset: vkTokenController.text.length));
    defaultMsgController.selection = TextSelection.fromPosition(TextPosition(offset: defaultMsgController.text.length));
    citiesController.selection = TextSelection.fromPosition(TextPosition(offset: citiesController.text.length));
    ageFromController.selection = TextSelection.fromPosition(TextPosition(offset: ageFromController.text.length));
    ageToController.selection = TextSelection.fromPosition(TextPosition(offset: ageToController.text.length));


    return ListView(
      padding: const EdgeInsets.all(16), // Reduced padding slightly
      children: [
        // --- VK Token ---
        _buildSectionHeader('Авторизация', Icons.key_rounded),
        const SizedBox(height: 12),
        _buildTextField(
          controller: vkTokenController,
          labelText: 'VK API Токен',
          hintText: 'Вставьте ваш VK токен сюда',
          icon: Icons.vpn_key_outlined,
          obscureText: true, // Hide token
        ),
        const SizedBox(height: 4),
        _buildHelpText('Токен необходим для доступа к API ВКонтакте. Получите его <ссылка> (добавьте реальную ссылку или инструкцию).'), // TODO: Add link/instructions
        const SizedBox(height: 24),

        // --- Search Filters ---
        _buildSectionHeader('Фильтры поиска', Icons.filter_alt_outlined),
        const SizedBox(height: 12),

        // Cities Input
        _buildTextField(
          controller: citiesController,
          labelText: 'Города для поиска',
          hintText: 'Например: Москва, Санкт-Петербург, Ялта',
          icon: Icons.location_city,
        ),
        _buildHelpText('Введите названия городов через запятую.'),
        const SizedBox(height: 16),

        // Age Range Input
        Row(
          children: [
            Expanded(
                child: _buildTextField(
                    controller: ageFromController,
                    labelText: 'Возраст от',
                    hintText: 'Напр. 18',
                    icon: Icons.calendar_view_day_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]
                )
            ),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTextField(
                    controller: ageToController,
                    labelText: 'Возраст до',
                    hintText: 'Напр. 30',
                    icon: Icons.calendar_view_day,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]
                )
            ),
          ],
        ),
        _buildHelpText('Оставьте поля пустыми, чтобы не ограничивать возраст.'),
        const SizedBox(height: 24),

        // --- Group Bank ---
        _buildSectionHeader('Банк групп для поиска', Icons.groups_2_outlined),
        const SizedBox(height: 12),
        _buildGroupManagementSection(context, newGroupUrlController), // Extracted for clarity
        const SizedBox(height: 24),


        // --- Default Message ---
        _buildSectionHeader('Стандартное сообщение', Icons.message_outlined),
        const SizedBox(height: 12),
        _buildTextField(
          controller: defaultMsgController,
          labelText: 'Шаблон сообщения',
          hintText: 'Будет подставлено при свайпе вправо',
          icon: Icons.edit_note,
          maxLines: 3,
        ),
        _buildHelpText('Используйте как основу для вашего первого сообщения.'),
        const SizedBox(height: 24),

        // --- Theme Selection ---
        _buildSectionHeader('Тема приложения', Icons.palette_outlined),
        const SizedBox(height: 12),
        Obx(() => Card( // Keep Obx around the Card for theme radios
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildThemeOption(
                'Системная', 'Следовать настройкам системы', Icons.settings_suggest_outlined, 'system', themeValue,
              ),
              const Divider(height: 0, indent: 50),
              _buildThemeOption(
                'Светлая', 'Светлое оформление', Icons.wb_sunny_outlined, 'light', themeValue,
              ),
              const Divider(height: 0, indent: 50),
              _buildThemeOption(
                'Темная', 'Темное оформление', Icons.nights_stay_outlined, 'dark', themeValue,
              ),
            ],
          ),
        )),
        const SizedBox(height: 32),

        // --- Save Button ---
        ElevatedButton.icon(
          onPressed: () {
            // Read current values from text controllers
            final citiesList = citiesController.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();

            controller.saveSettings(
              vkToken: vkTokenController.text.trim(),
              defaultMessage: defaultMsgController.text.trim(),
              theme: themeValue.value, // Use the local reactive theme value
              currentCities: citiesList,
              ageFromString: ageFromController.text.trim(),
              ageToString: ageToController.text.trim(),
              currentGroupUrls: controller.groupUrls.toList(), // Get current list from controller
            );
            // Consider unfocusing keyboard
            FocusScope.of(context).unfocus();
          },
          icon: const Icon(Icons.save_alt_rounded, size: 20),
          label: const Text(
            'Сохранить настройки',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24), // Bottom padding
      ],
    );
  }

  // Helper to build consistent TextFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // Use theme's default
        // enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[400]!)),
        // focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Get.theme.primaryColor, width: 1.5)),
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        labelText: labelText,
        hintText: hintText,
        // contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Adjust padding
        filled: true, // Use theme defaults for fill color
        // fillColor: Get.theme.inputDecorationTheme.fillColor,
        isDense: true, // Make it slightly more compact
      ),
    );
  }


  Widget _buildGroupManagementSection(BuildContext context, TextEditingController newGroupUrlController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Row for adding new group
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
          children: [
            Expanded(
              child: _buildTextField(
                controller: newGroupUrlController,
                labelText: 'URL или Короткое Имя Группы',
                hintText: 'vk.com/example или example',
                icon: Icons.link,
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => IconButton(
              icon: controller.isGroupUrlValidating.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_circle_outline, size: 28), // Make icon larger
              onPressed: controller.isGroupUrlValidating.value ? null : () async {
                final url = newGroupUrlController.text;
                await controller.addGroupUrl(url);
                if (!controller.isGroupUrlValidating.value) { // Clear only if validation didn't fail immediately
                  newGroupUrlController.clear();
                }
              },
              tooltip: 'Добавить группу',
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(12), // Increase tap area
                backgroundColor: Get.theme.colorScheme.primaryContainer,
                foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
              ),
            )),
          ],
        ),
        const SizedBox(height: 12),

        // List of added groups
        Obx(() {
          if (controller.groupUrls.isEmpty) {
            return Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                    color: Get.theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Get.theme.dividerColor)
                ),
                child: const Center(child: Text('Добавьте группы для поиска', style: TextStyle(color: Colors.grey)))
            );
          }
          return Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // List is inside a ListView
              itemCount: controller.groupUrls.length,
              itemBuilder: (context, index) {
                final url = controller.groupUrls[index];
                final displayName = url.startsWith('http') ? Uri.tryParse(url)?.pathSegments.last ?? url : url;
                return ListTile(
                  // leading: CircleAvatar(child: Text('${index + 1}')), // Optional: index number
                  leading: Icon(Icons.group, color: Get.theme.colorScheme.primary),
                  title: Text(displayName, overflow: TextOverflow.ellipsis),
                  subtitle: Text(url, style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis), // Show full url subtly
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent[100]),
                    onPressed: () => controller.removeGroupUrl(url),
                    tooltip: 'Удалить группу',
                  ),
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 16, right: 8), // Adjust padding
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 0, indent: 52),
            ),
          );
        }),
        _buildHelpText('Поиск будет вестись по участникам всех добавленных групп.'),
      ],
    );
  }


  // Helper for section headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Get.theme.colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), // Bolder title
        ),
      ],
    );
  }

  // Helper for help text below fields
  Widget _buildHelpText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 4.0), // Adjust as needed
      child: Text(
        text,
        style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
    );
  }


  // Copied from original _buildThemeOption, adjusted slightly
  Widget _buildThemeOption(String title, String subtitle, IconData icon, String value, RxString groupValue) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 20), // Slightly smaller icon
          const SizedBox(width: 12),
          Text(title, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)), // Adjusted style
        ],
      ),
      subtitle: Text(subtitle, style: Get.textTheme.bodySmall),
      value: value,
      groupValue: groupValue.value, // Reactive group value
      onChanged: (newValue) {
        if (newValue != null) {
          groupValue.value = newValue; // Update the local RxString
          // No need to call controller.saveSettings here, it's done via the main button
        }
      },
      shape: const RoundedRectangleBorder(), // Remove individual shape, rely on Card
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
      dense: true, // Make tile more compact
    );
  }
}
