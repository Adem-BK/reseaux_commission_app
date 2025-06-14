import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onBackgroundColor = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final outlineColor = Theme.of(context).colorScheme.outline;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    // Card wrapping the icon and title
                    elevation: 4.0, // Add a subtle shadow
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.support_agent, // Using a stock Flutter icon
                            size: 72,
                            color: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Contactez-nous',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
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
                  const SizedBox(height: 32),
                  Text(
                    'Nous sommes impatients de vous entendre ! Que vous ayez une question, une suggestion ou que vous ayez besoin d\'assistance, remplissez simplement le formulaire ci-dessous et nous vous répondrons dans les plus brefs délais.',
                    style: TextStyle(fontSize: 18, color: onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // --- Contact Form ---
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      labelStyle: TextStyle(color: onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Adresse e-mail',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      labelStyle: TextStyle(color: onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Votre message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      labelStyle: TextStyle(color: onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Envoyer le message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Message envoyé ! (Fonctionnalité à implémenter)')),
                      );
                    },
                    icon: Icon(
                      Icons.send_rounded,
                      color: primaryColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                    label: Text('Envoyer le message',
                        style: TextStyle(
                            color: primaryColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Divider(color: outlineColor),
                  const SizedBox(height: 24),
                  Text(
                    'Ou contactez-nous directement :',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onBackgroundColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    icon: Icons.email_rounded,
                    text: 'support@tonapp.com',
                    color: primaryColor,
                    textColor: onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    icon: Icons.phone_rounded,
                    text: '+212 6 12 34 56 78',
                    color: primaryColor,
                    textColor: onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      ],
    );
  }
}
