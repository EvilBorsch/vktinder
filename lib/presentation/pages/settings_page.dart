// --- File: lib/presentation/pages/settings_page.dart ---
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vktinder/presentation/controllers/settings_controller.dart';

import '../../data/providers/vk_api_provider.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are initialized when the widget builds
    // This is safe because loadSettings also initializes them if null
    controller.vkTokenController ??= TextEditingController(text: controller.vkToken);
    controller.defaultMsgController ??= TextEditingController(text: controller.defaultMessage);
    controller.citiesController ??= TextEditingController(text: controller.cities.join(', '));
    controller.ageFromController ??= TextEditingController(text: controller.ageFrom.value?.toString() ?? '');
    controller.ageToController ??= TextEditingController(text: controller.ageTo.value?.toString() ?? '');
    controller.newGroupUrlController ??= TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 1, // Subtle shadow
      ),
      body: _buildSettingsForm(context),
    );
  }

  Widget _buildSettingsForm(BuildContext context) {
    // Access controllers directly from the SettingsController instance
    final vkTokenController = controller.vkTokenController!;
    final defaultMsgController = controller.defaultMsgController!;
    final citiesController = controller.citiesController!;
    final ageFromController = controller.ageFromController!;
    final ageToController = controller.ageToController!;
    final newGroupUrlController = controller.newGroupUrlController!;

    // Use the controller's RxString for theme selection directly
    final themeValue = controller.theme; // Already RxString in controller

    return ListView(
      padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.open_in_new, size: 18),
          // Keep icon small
          label: const Text('Получить VK Token (выберите vk.com)'),
          // Concise label
          onPressed: () async => await launchUrl(Uri.parse('https://vkhost.github.io/'), mode: LaunchMode.externalApplication),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // Adjust horizontal padding
            visualDensity: VisualDensity.standard,
            elevation: 2, // Slight elevation
          ),
        ),
        const SizedBox(height: 24),

        // --- Search Filters ---
        _buildSectionHeader('Фильтры поиска', Icons.filter_alt_outlined),
        const SizedBox(height: 12),

        // Group Bank First (logical flow: define *where* to search first)
        _buildSectionHeader('В каких группах ищем?', Icons.groups_2_outlined),
        const SizedBox(height: 12),
        _buildGroupManagementSection(context, newGroupUrlController),
        _buildHelpText('Поиск будет вестись по участникам всех добавленных групп.'),
        const SizedBox(height: 24),


        // Cities Input
        _buildTextField(
          controller: citiesController,
          labelText: 'Города для поиска',
          hintText: 'Напр: Москва, Ялта',
          icon: Icons.location_city,
        ),
        _buildHelpText('Введите названия городов через запятую. Оставьте пустым для поиска по всем городам.'),
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
        const SizedBox(height: 16),

        // Sex Filter
        Obx(() => Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildSexOption(
                'Любой пол', 'Показывать всех пользователей', Icons.people_outline, 0, controller.sexFilter,
              ),
              const Divider(height: 0, indent: 50),
              _buildSexOption(
                'Женский', 'Показывать только женщин', Icons.female, 1, controller.sexFilter,
              ),
              const Divider(height: 0, indent: 50),
              _buildSexOption(
                'Мужской', 'Показывать только мужчин', Icons.male, 2, controller.sexFilter,
              ),
            ],
          ),
        )),
        _buildHelpText('Выберите пол пользователей для поиска.'),
        const SizedBox(height: 16),

        // Skip Closed Profiles Option
        Obx(() => SwitchListTile(
          title: const Row(
            children: [
              Icon(Icons.visibility_off_outlined, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('Пропускать профили с ограниченным доступом',
                    style: TextStyle(fontWeight: FontWeight.w500)), // Simplified style
              ),
            ],
          ),
          value: controller.skipClosedProfiles.value,
          onChanged: (value) {
            controller.skipClosedProfiles.value = value;
          },
          // Use same card styling as theme/sex options
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Get.theme.cardTheme.color ?? Get.theme.cardColor, // Use theme card color
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          dense: true,
        )),
        _buildHelpText('Такие профили часто бесполезны, т.к. нельзя посмотреть фото или инфо.'),
        const SizedBox(height: 16), // Spacing after switch

        // --- NEW: Skip Relation Filter ---
        Obx(() => SwitchListTile(
          title: const Row(
            children: [
              Icon(Icons.family_restroom_outlined, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text('Искать только свободных / в поиске',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          value: controller.skipRelationFilter.value,
          onChanged: (value) {
            controller.skipRelationFilter.value = value;
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Get.theme.cardTheme.color ?? Get.theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          dense: true,
        )),
        _buildHelpText('Позволяет отфильтровать тех, кто уже в отношениях, помолвлен, женат/замужем и т.д.'),
        const SizedBox(height: 24), // Spacing after switch


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
        _buildHelpText('Используйте как основу для вашего первого сообщения при свайпе вправо.'),
        const SizedBox(height: 24),

        // --- Theme Selection ---
        _buildSectionHeader('Тема приложения', Icons.palette_outlined),
        const SizedBox(height: 12),
        Obx(() => Card( // Obx needed for groupValue reactivity
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildThemeOption(
                'Системная', 'Следовать настройкам системы', Icons.settings_suggest_outlined, 'system', themeValue.obs,
              ),
              const Divider(height: 0, indent: 50),
              _buildThemeOption(
                'Светлая', 'Светлое оформление', Icons.wb_sunny_outlined, 'light', themeValue.obs,
              ),
              const Divider(height: 0, indent: 50),
              _buildThemeOption(
                'Темная', 'Темное оформление', Icons.nights_stay_outlined, 'dark', themeValue.obs,
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

            // Call saveSettings with all values
            controller.saveSettings(
              vkToken: vkTokenController.text.trim(),
              defaultMessage: defaultMsgController.text.trim(),
              theme: themeValue, // Get value from the reactive variable
              currentCities: citiesList,
              ageFromString: ageFromController.text.trim(),
              ageToString: ageToController.text.trim(),
              sexFilter: controller.sexFilter.value, // Pass the sex filter value
              currentGroupUrls: controller.groupUrls.toList(), // Get current list from controller
              skipClosedProfiles: controller.skipClosedProfiles.value, // Pass reactive value
              skipRelationFilter: controller.skipRelationFilter.value, // Pass reactive value
            );
            // Unfocus keyboard
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
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        labelText: labelText,
        hintText: hintText,
        filled: true,
        isDense: true,
        // Use inputDecorationTheme defaults
        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        // enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        // focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                // Clear only if add logic didn't show an error keeping the text field populated
                // Check isGroupUrlValidating again, as it might be set to false even on error by the controller.
                // A better approach might be for addGroupUrl to return a bool indicating success.
                if (!controller.isGroupUrlValidating.value && newGroupUrlController.text == url) {
                  // Assume success if value hasn't changed and validation finished.
                  // This isn't perfect, relies on timing.
                  final groupInfo = await controller.isGroupUrlValidating(false); // temporary hack
                  final groupInfo2 = await Get.find<VkApiProvider>().getGroupInfoByScreenName(controller.vkToken, url); // Re-validate without UI block
                  if (groupInfo2 != null && controller.groupUrls.contains(url)) { // If it exists now, clear
                    newGroupUrlController.clear();
                  }
                }
                // Alternative: Always clear, user needs to re-enter on validation failure.
                // newGroupUrlController.clear();
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
                // Extract a display name (improve this logic if needed)
                String displayName = url;
                try {
                  if (url.startsWith('http')) {
                    Uri uri = Uri.parse(url);
                    if (uri.pathSegments.isNotEmpty) {
                      displayName = uri.pathSegments.last;
                      if (displayName.isEmpty && uri.pathSegments.length > 1) {
                        displayName = uri.pathSegments[uri.pathSegments.length - 2]; // Fallback for trailing slash
                      }
                    }
                  }
                  // Remove potential leading 'club' or 'public' for cleaner display if it's just that + ID
                  displayName = displayName.replaceFirstMapped(RegExp(r'^(club|public)(\d+)'), (match) => 'ID ${match.group(2)}');

                } catch (e) {
                  print("Error parsing group URL for display name: $url");
                }


                return ListTile(
                  leading: Icon(Icons.group, color: Get.theme.colorScheme.primary),
                  title: Text(displayName, overflow: TextOverflow.ellipsis),
                  subtitle: Text(url, style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis), // Show full url subtly
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), // Use clearer red
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
        // Removed redundant help text from here, now placed after the group management section
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
      padding: const EdgeInsets.only(left: 4.0, top: 4.0, right: 4.0), // Added right padding
      child: Text(
        text,
        style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey[600], height: 1.3), // Adjusted line height
      ),
    );
  }

  Widget _buildThemeOption(String title, String subtitle, IconData icon, String value, RxString groupValue) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), // Adjusted style
        ],
      ),
      subtitle: Text(subtitle, style: Get.textTheme.bodySmall),
      value: value,
      groupValue: groupValue.value, // Reactive group value
      onChanged: (newValue) {
        if (newValue != null) {
          groupValue.value = newValue; // Update the controller's reactive variable directly
        }
      },
      shape: const RoundedRectangleBorder(), // Remove individual shape, rely on Card
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }

  Widget _buildSexOption(String title, String subtitle, IconData icon, int value, RxInt groupValue) {
    return RadioListTile<int>(
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), // Adjusted style
        ],
      ),
      subtitle: Text(subtitle, style: Get.textTheme.bodySmall),
      value: value,
      groupValue: groupValue.value, // Reactive group value
      onChanged: (newValue) {
        if (newValue != null) {
          groupValue.value = newValue; // Update the controller's reactive variable
        }
      },
      shape: const RoundedRectangleBorder(), // Remove individual shape, rely on Card
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }
}