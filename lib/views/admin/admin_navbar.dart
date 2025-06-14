// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:reseaux_commission_app/views/admin/admin_dashboard.dart';
import 'package:reseaux_commission_app/views/admin/admin_manage_commissions.dart';
import 'package:reseaux_commission_app/views/admin/admin_manage_comptes.dart';
import 'package:reseaux_commission_app/views/admin/admin_manage_transactions.dart';
import 'package:reseaux_commission_app/views/admin/admin_manage_users.dart';
import 'package:reseaux_commission_app/views/shared/profile.dart'; // Ensure this path is correct
import 'package:reseaux_commission_app/main.dart'; // Import main.dart to access themeModeNotifier

class AdminNavBarPage extends StatefulWidget {
  const AdminNavBarPage({super.key});

  @override
  State<AdminNavBarPage> createState() => _AdminNavBarPageState();
}

class _AdminNavBarPageState extends State<AdminNavBarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedPage = 'Dashboard'; // Initial page

  // Removed _isDarkMode state here, as theme will be controlled globally by themeModeNotifier

  final List<Map<String, dynamic>> _menuItems = [
    {'label': 'Dashboard', 'icon': Icons.dashboard},
    {'label': 'Comptes', 'icon': Icons.account_box},
    {'label': 'Utilisateurs', 'icon': Icons.group},
    {'label': 'Transactions', 'icon': Icons.swap_horiz},
    {'label': 'Commissions', 'icon': Icons.attach_money},
  ];

  // Method to handle logout
  void _logout(BuildContext context) {
    // Implement your actual logout logic here, such as:
    // 1. Clearing user session data (e.g., tokens, user info)
    // 2. Navigating the user to the login screen
    // Example navigation to a hypothetical login page:
    Navigator.pushReplacementNamed(context, '/');
  }

  void _handleNavigation(BuildContext context, String item) {
    setState(() {
      _selectedPage = item;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context); // Close the drawer
    }
  }

  Widget _drawer(BuildContext context) {
    // Get the current theme from the context
    final currentTheme = Theme.of(context);
    // Determine if the current effective theme is dark (used for old hardcoded colors, now largely replaced by theme colors)
    final bool isCurrentlyDarkMode = currentTheme.brightness == Brightness.dark;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: isCurrentlyDarkMode
                  ? Colors.grey[850]
                  : Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Admin Menu',
              style: TextStyle(
                color: Colors.white, // Text color on primary
                fontSize: 24,
              ),
            ),
          ),
          ..._menuItems.map((item) {
            final isSelected = _selectedPage == item['label'];
            return ListTile(
              leading: Icon(
                item['icon'],
                color: isSelected
                    ? currentTheme.colorScheme.primary
                    : currentTheme.colorScheme.onSurface
                        .withOpacity(0.7), // Use onSurface for icons
              ),
              title: Text(
                item['label'],
                style: TextStyle(
                  color: isSelected
                      ? currentTheme.colorScheme.primary
                      : currentTheme
                          .colorScheme.onSurface, // Use onSurface for text
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedTileColor: currentTheme.colorScheme.primary
                  .withOpacity(0.1), // Themed selection color
              onTap: () {
                _handleNavigation(context, item['label']);
              },
            );
            // ignore: unnecessary_to_list_in_spreads
          }).toList(),
        ],
      ),
    );
  }

  Widget _navBarItems(BuildContext context) {
    // Get the current theme from the context
    final currentTheme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _menuItems
          .map(
            (item) => InkWell(
              onTap: () => _handleNavigation(context, item['label']),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      item['icon'],
                      color: _selectedPage == item['label']
                          ? currentTheme.colorScheme.primary
                          : currentTheme
                              .colorScheme.onSurface, // Use onSurface for icons
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['label'],
                      style: TextStyle(
                        fontSize: 18,
                        color: _selectedPage == item['label']
                            ? currentTheme.colorScheme.primary
                            : currentTheme.colorScheme
                                .onSurface, // Use onSurface for text
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _bodyContent() {
    switch (_selectedPage) {
      case 'Dashboard':
        return const AdminDashboard();
      case 'Comptes':
        return const AdminManageComptes();
      case 'Utilisateurs':
        return const AdminManageUsers();
      case 'Transactions':
        return const AdminManageTransactions();
      case 'Commissions':
        return const AdminManageCommissions();
      case 'Mon profil': // Handle 'Mon profil' to show Profile widget
        return const Profile(); // Profile will now inherit the global theme
      default:
        return const Center(
          child: Text(
            "Admin Body Content",
            style: TextStyle(fontSize: 24),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 800;
    final currentTheme = Theme.of(context); // Get the theme from the context

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // Set transparent to let background shine
        elevation: 0, // No shadow
        titleSpacing: 0,
        leading: isLargeScreen
            ? null // No drawer icon on large screens if using persistent nav
            : IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Admin Panel",
                style: currentTheme.textTheme.headlineSmall?.copyWith(
                  // Use headlineSmall for app bar title
                  color: currentTheme
                      .colorScheme.primary, // Text color should be onPrimary
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLargeScreen) Expanded(child: _navBarItems(context))
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _ProfileIcon(
              onThemeChanged: (isDark) {
                // Update the global themeModeNotifier
                themeModeNotifier.value =
                    isDark ? ThemeMode.dark : ThemeMode.light;
              },
              isDarkMode: currentTheme.brightness ==
                  Brightness.dark, // Pass current theme brightness
              onLogout: () => _logout(context),
              onProfileSelected: () {
                setState(() {
                  _selectedPage = 'Mon profil';
                });
              },
            ),
          )
        ],
      ),
      drawer: isLargeScreen ? null : _drawer(context),
      body: _bodyContent(),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon(
      {required this.onThemeChanged,
      required this.isDarkMode,
      this.onLogout,
      required this.onProfileSelected});

  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;
  final VoidCallback? onLogout;
  final VoidCallback onProfileSelected;

  @override
  Widget build(BuildContext context) {
    // Get the current theme from the context to style the PopupMenuButton's icon and items
    final currentTheme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(Icons.person,
          color: currentTheme.colorScheme.onSurface), // Icon color from theme
      offset: const Offset(0, 40),
      onSelected: (String value) {
        if (value == 'Mon profil') {
          onProfileSelected();
        } else if (value == 'Mode clair') {
          onThemeChanged(false);
        } else if (value == 'Mode sombre') {
          onThemeChanged(true);
        } else if (value == 'Se déconnecter') {
          if (onLogout != null) {
            onLogout!();
          }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'Mon profil',
          child: Row(
            children: [
              Icon(Icons.person_outline,
                  color: currentTheme.colorScheme.onSurface), // Themed icon
              const SizedBox(width: 8),
              Text('Mon profil',
                  style: TextStyle(
                      color:
                          currentTheme.colorScheme.onSurface)), // Themed text
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: isDarkMode ? 'Mode clair' : 'Mode sombre',
          child: Row(
            children: [
              Icon(
                  isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: currentTheme.colorScheme.onSurface), // Themed icon
              const SizedBox(width: 8),
              Text(isDarkMode ? 'Mode clair' : 'Mode sombre',
                  style: TextStyle(
                      color:
                          currentTheme.colorScheme.onSurface)), // Themed text
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Se déconnecter',
          child: Row(
            children: [
              Icon(Icons.logout,
                  color: currentTheme.colorScheme.onSurface), // Themed icon
              const SizedBox(width: 8),
              Text('Se déconnecter',
                  style: TextStyle(
                      color:
                          currentTheme.colorScheme.onSurface)), // Themed text
            ],
          ),
        ),
      ],
    );
  }
}
