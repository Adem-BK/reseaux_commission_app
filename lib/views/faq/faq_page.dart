import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // For modern icons

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/faq.svg', // Replace with your SVG asset path
                  height: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Foire Aux Questions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildModernFaqItem(
              context: context,
              question: '💡 Qu’est-ce que cette application ?',
              answer:
                  'Il s’agit d’une application dédiée à la formation, au départ. Dans sa deuxième phase de développement, elle évoluera pour intégrer une fonctionnalité e-commerce complète.',
            ),
            const SizedBox(height: 16),
            _buildModernFaqItem(
              context: context,
              question: '🔐 Mes données sont-elles sécurisées ?',
              answer:
                  'Oui, nous mettons en œuvre des mesures de sécurité pour protéger vos informations personnelles. Aucune donnée ne sera partagée sans votre consentement.',
            ),
            const SizedBox(height: 16),
            _buildModernFaqItem(
              context: context,
              question: '📱 Puis-je accéder à l\'application sur mobile ?',
              answer:
                  'Absolument ! L’application est conçue pour être entièrement responsive et accessible depuis un ordinateur, une tablette ou un smartphone.',
            ),
            const SizedBox(height: 16),
            _buildModernFaqItem(
              context: context,
              question: '💬 Comment puis-je contacter le support ?',
              answer:
                  'Vous pouvez nous contacter via la page “Contactez-nous”. Une équipe dédiée est prête à répondre à vos questions rapidement.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onBackgroundColor = Theme.of(context).colorScheme.onSurface;
    final surfaceVariant =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.question_mark_rounded, color: primaryColor),
        title: Text(
          question,
          style:
              TextStyle(fontWeight: FontWeight.w600, color: onBackgroundColor),
        ),
        childrenPadding: const EdgeInsets.all(16),
        collapsedBackgroundColor: surfaceVariant,
        backgroundColor: surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: <Widget>[
          Text(
            answer,
            style: TextStyle(color: onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
