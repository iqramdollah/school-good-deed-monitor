import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/auth_provider.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget page;
  const NavItem({required this.label, required this.icon, required this.page});
}

class AppShell extends ConsumerStatefulWidget {
  final String title;
  final Color accentColor;
  final List<NavItem> items;

  const AppShell({
    super.key,
    required this.title,
    required this.accentColor,
    required this.items,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return isMobile ? _mobileLayout() : _desktopLayout();
  }

  Widget _mobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.accentColor,
        actions: [_signOutButton()],
      ),
      body: widget.items[_selectedIndex].page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        indicatorColor: widget.accentColor.withOpacity(0.15),
        destinations: widget.items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _desktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation
          NavigationRail(
            extended: true,
            minExtendedWidth: 220,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            indicatorColor: widget.accentColor.withOpacity(0.15),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Turquoise',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _signOutButton(),
            ),
            destinations: widget.items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(child: widget.items[_selectedIndex].page),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sign out',
      onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
    );
  }
}
