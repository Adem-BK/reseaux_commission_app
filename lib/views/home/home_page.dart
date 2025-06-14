import 'package:flutter/material.dart';
import 'package:reseaux_commission_app/main.dart'; // Import main.dart to access themeModeNotifier
import 'package:reseaux_commission_app/views/auth/login/login_page.dart';
import 'package:reseaux_commission_app/views/auth/signup/signup_page.dart';
import 'package:reseaux_commission_app/views/contact/contact_page.dart';
import 'package:reseaux_commission_app/views/faq/faq_page.dart';
import 'package:reseaux_commission_app/views/home/Accueil_page.dart'; // This is the actual welcome content
import 'package:reseaux_commission_app/views/terms/terms_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedPage = 'Accueil';

  final List<Map<String, dynamic>> _menuItems = [
    {'label': 'Accueil', 'icon': Icons.home},
    {'label': 'Se connecter', 'icon': Icons.login},
    {'label': 'S\'inscrire', 'icon': Icons.app_registration},
    {'label': 'A propos', 'icon': Icons.info_outline},
    {'label': 'Contactez-nous', 'icon': Icons.contact_mail},
    {'label': 'Conditions', 'icon': Icons.rule},
  ];

  final Map<String, Widget> _pageWidgets = {
    'Accueil': const AccueilPage(), // This is the nested welcome page
    'Se connecter': const LoginPage(),
    "S'inscrire": const SignupPage(),
    'A propos': const FaqPage(),
    'Contactez-nous': const ContactUsPage(),
    'Conditions': const TermsConditionsPage(),
  };

  // Handles navigation when a drawer item or nav bar item is tapped
  void _handleNavigation(BuildContext context, String item) {
    setState(() {
      _selectedPage = item;
    });
    // Close the drawer after selection (if it's open)
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Widget _drawer(BuildContext context, bool isDarkMode) => Drawer(
        child: ListView(
          padding: EdgeInsets.zero, // Important for full-height drawer header
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[850]
                    : Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Menu Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // Loop through menu items to create ListTile entries
            ..._menuItems.map((item) {
              final isSelected = _selectedPage == item['label'];
              return ListTile(
                leading: Icon(
                  item['icon'],
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primary // Highlight selected icon with primary color
                      : Theme.of(context)
                          .colorScheme
                          .onBackground, // Icon color adapts to theme
                ),
                title: Text(
                  item['label'],
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onBackground, // Text color adapts to theme
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: Colors
                    .transparent, // Prevents extra background on selection
                onTap: () {
                  _handleNavigation(context, item['label']);
                },
              );
            }).toList(),
            // No "Se déconnecter" or "Mon profil" as this is for unauthenticated users.
          ],
        ),
      );

  Widget _navBarItems() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _menuItems.map((item) {
          final isSelected = _selectedPage == item['label'];
          // These colors will automatically adapt based on the 'Theme' widget wrapping the Scaffold
          final primaryColor = Theme.of(context).colorScheme.primary;
          final onBackgroundColor = Theme.of(context).colorScheme.onBackground;

          return InkWell(
            onTap: () {
              _handleNavigation(context, item['label']);
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              child: Text(
                item['label'],
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected ? primaryColor : onBackgroundColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 800;

    // Initialize isDarkMode here where context is available
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                ), // Icon color adapts to theme
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Title left, actions right
            children: [
              Text(
                "Logo", // Your app's logo text
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .primary, // Use theme's primary color
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLargeScreen)
                Expanded(
                    child: _navBarItems()), // Horizontal nav for large screens
            ],
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: _ThemeModeIcon(), // No need to pass callbacks or state here
          ),
        ],
      ),
      // Pass both context and the calculated isDarkMode to _drawer()
      drawer: isLargeScreen
          ? null
          : _drawer(context, isDarkMode), // Show drawer on small screens
      body: Center(
        child: _pageWidgets[_selectedPage] ?? const Text("Page not found"),
      ),
    );
  }
}

class _ThemeModeIcon extends StatelessWidget {
  const _ThemeModeIcon({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current theme brightness directly from the context
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      icon: Icon(
        // The icon in the AppBar should reflect the current theme mode
        isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        // The color of the icon will adapt to the current theme's onBackground color
        color: Theme.of(context).colorScheme.onBackground,
      ),
      offset: const Offset(0, 40),
      onSelected: (String value) {
        if (value == 'Mode clair') {
          themeModeNotifier.value = ThemeMode.light;
        } else if (value == 'Mode sombre') {
          themeModeNotifier.value = ThemeMode.dark;
        } else if (value == 'Mode système') {
          themeModeNotifier.value = ThemeMode.system;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'Mode clair',
          child: Row(
            children: [
              // Icon for "Light Mode" option: should be a contrasting color (dark icon)
              Icon(
                Icons.light_mode, // Filled icon for better contrast
                color: isDarkMode
                    ? Colors.white
                    : Colors.black, // Explicitly set color
              ),
              const SizedBox(width: 8),
              Text(
                'Mode clair',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Explicitly set text color
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Mode sombre',
          child: Row(
            children: [
              // Icon for "Dark Mode" option: should be a contrasting color (light icon)
              Icon(
                Icons.dark_mode, // Filled icon for better contrast
                color: isDarkMode
                    ? Colors.white
                    : Colors.black, // Explicitly set color
              ),
              const SizedBox(width: 8),
              Text(
                'Mode sombre',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Explicitly set text color
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Mode système',
          child: Row(
            children: [
              // Icon for "System Mode" option: should be a contrasting color
              Icon(
                Icons.brightness_auto,
                color: isDarkMode
                    ? Colors.white
                    : Colors.black, // Explicitly set color
              ),
              const SizedBox(width: 8),
              Text(
                'Mode système',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Explicitly set text color
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
