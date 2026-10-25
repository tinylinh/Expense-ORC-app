import 'package:flutter/material.dart';

import '../analytics/analytics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../scanner/receipt_scanner_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  Future<void> _openScanner() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [DashboardScreen(), AnalyticsScreen()],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        tooltip: 'Add receipt',
        backgroundColor: theme.brightness == Brightness.dark
            ? const Color(0xFF8DDCF5)
            : Colors.black,
        foregroundColor: theme.brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              const SizedBox(width: 48),
              _NavItem(
                icon: Icons.query_stats_outlined,
                label: 'Analytics',
                selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 21),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
