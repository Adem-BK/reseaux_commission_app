// ignore_for_file: file_names

import 'package:flutter/material.dart';
// No need to import main.dart here directly for theme access, as Theme.of(context) is sufficient

class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;
    final bool isLandscape = size.width > size.height;

    // Correctly extract colors from the current active theme
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onBackgroundColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Flex(
              direction: isSmallScreen && isLandscape
                  ? Axis.horizontal
                  : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  flex: 2,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bienvenue sur l\'application Réseaux & Commissions',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      primaryColor, // Uses themed primaryColor
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gérez efficacement votre réseau de vente, suivez vos commissions, et développez votre activité grâce à nos outils intuitifs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  onBackgroundColor, // Uses themed onBackgroundColor
                            ),
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: [
                              _AccueilCard(
                                icon: Icons.group,
                                title: 'Mon Réseau',
                                description:
                                    'Visualisez et gérez la structure de vos agents.',
                                iconColor: secondaryColor,
                                textColor: onSurfaceColor,
                                cardColor: surfaceColor,
                              ),
                              _AccueilCard(
                                icon: Icons.trending_up,
                                title: 'Mes Commissions',
                                description:
                                    'Consultez vos gains en temps réel.',
                                iconColor: secondaryColor,
                                textColor: onSurfaceColor,
                                cardColor: surfaceColor,
                              ),
                              _AccueilCard(
                                icon: Icons.shopping_cart,
                                title: 'Boutique',
                                description:
                                    'Accédez à notre catalogue de produits et passez vos commandes.',
                                iconColor: secondaryColor,
                                textColor: onSurfaceColor,
                                cardColor: surfaceColor,
                              ),
                              _AccueilCard(
                                icon: Icons.support_agent,
                                title: 'Assistance',
                                description:
                                    'Contactez notre équipe ou consultez la FAQ.',
                                iconColor: secondaryColor,
                                textColor: onSurfaceColor,
                                cardColor: surfaceColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccueilCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;
  final Color? textColor;
  final Color? cardColor;

  const _AccueilCard({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.textColor,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 400 ? screenWidth * 0.8 : 180.0;

    // Use theme's colors as fallbacks if no specific color is provided
    final onSurfaceColorFromTheme = Theme.of(context).colorScheme.onSurface;
    final surfaceColorFromTheme = Theme.of(context).colorScheme.surface;
    final secondaryColorFromTheme = Theme.of(context).colorScheme.secondary;

    return SizedBox(
      width: cardWidth,
      height: 200,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Use provided cardColor or default to theme's surface color
        color: cardColor ?? surfaceColorFromTheme,
        child: InkWell(
          onTap: () {
            // Action au click
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 40,
                  // Use the provided iconColor, falling back to secondaryColorFromTheme
                  color: iconColor ?? secondaryColorFromTheme,
                ),
                Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        // Use the provided textColor, falling back to onSurfaceColorFromTheme
                        color: textColor ?? onSurfaceColorFromTheme,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        // Use the provided textColor, falling back to onSurfaceColorFromTheme
                        color: textColor ?? onSurfaceColorFromTheme,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
