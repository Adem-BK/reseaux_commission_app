import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // Center the entire column content horizontally
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // The main title card for "Conditions Générales d’Utilisation"
              // Wrapped in a Center and FractionallySizedBox for consistent width and centering
              Center(
                child: FractionallySizedBox(
                  widthFactor:
                      0.8, // Adjust as needed, e.g., 80% of available width
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 72,
                            color: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Conditions Générales d’Utilisation',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Dynamically build the list of terms cards
              ..._buildTermsList(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTermsList(BuildContext context) {
    final onBackgroundColor = Theme.of(context).colorScheme.onBackground;
    final surfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    final terms = [
      {
        'title': '1. Acceptation des conditions',
        'content':
            'En accédant à cette application, vous acceptez d’être lié par les présentes conditions générales d’utilisation.',
      },
      {
        'title': '2. Utilisation de l’application',
        'content':
            'Vous vous engagez à utiliser cette application uniquement à des fins légales et conformément à la réglementation en vigueur.',
      },
      {
        'title': '3. Propriété intellectuelle',
        'content':
            'Tous les contenus présents dans l’application (textes, images, logos, etc.) sont la propriété exclusive de leurs auteurs respectifs.',
      },
      {
        'title': '4. Responsabilités',
        'content':
            'Nous ne sommes pas responsables des erreurs, interruptions ou dommages liés à l’utilisation de l’application.',
      },
      {
        'title': '5. Modifications',
        'content':
            'Nous nous réservons le droit de modifier les présentes conditions à tout moment. Les changements seront effectifs dès leur publication.',
      },
    ];

    return terms.map((term) {
      return Center(
        // Center each card horizontally
        child: FractionallySizedBox(
          widthFactor: 0.8, // Make each card take 80% of the available width
          child: Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Keep text left-aligned within the card
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    term['title']!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onBackgroundColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    term['content']!,
                    style: TextStyle(fontSize: 16, color: surfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
