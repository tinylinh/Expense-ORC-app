import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../receipts/receipt_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final darkModeEnabled =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && brightness == Brightness.dark);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: SwitchListTile(
              value: darkModeEnabled,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).state =
                    value ? ThemeMode.dark : ThemeMode.light;
              },
              title: const Text('Dark mode'),
              subtitle: const Text('Use a darker appearance throughout the app'),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phonelink_lock_outlined),
              title: const Text('Private and offline'),
              subtitle: const Text(
                'Receipt images and records are stored on this device. OCR runs locally.',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Expense Orc'),
              subtitle: const Text('Receipt OCR & expense tracker · v1.0.0'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Expense Orc',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Offline-first receipt expense tracking.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
