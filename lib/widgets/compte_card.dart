// lib/widgets/compte_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reseaux_commission_app/models/compte.dart';

class CompteCard extends StatelessWidget {
  final Compte compte;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const CompteCard({
    super.key,
    required this.compte,
    required this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define responsive font and icon sizes
    // Slightly reduced font sizes for mobile to help with encapsulation and prevent overflow
    double idFontSize =
        screenWidth > 800 ? 18.0 : 14.0; // Slightly smaller on mobile
    double mainDetailFontSize =
        screenWidth > 800 ? 15.0 : 12.0; // Slightly smaller on mobile
    double secondaryDetailFontSize =
        screenWidth > 800 ? 13.0 : 10.0; // Slightly smaller on mobile
    double actionIconSize =
        screenWidth > 800 ? 28.0 : 20.0; // Bigger on web, regular on mobile
    double detailIconSize =
        screenWidth > 800 ? 24.0 : 18.0; // Bigger on web, regular on mobile
    double buttonSpacing = screenWidth > 800 ? 16.0 : 4.0; // More space on web

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(
              screenWidth > 800 ? 20.0 : 16.0), // Responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Ensure the main column fills available height, and its children are sized properly.
            // Using a combination of Expanded and MainAxisSize.min to manage vertical space.
            children: [
              // Top Row: Compte ID and Action Buttons (takes its natural size)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Compte ID: ${compte.num_cpt}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: idFontSize, // Responsive font size
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit,
                            color: primaryColor,
                            size: actionIconSize), // Responsive icon size
                        onPressed: onEdit,
                        tooltip: 'Modifier',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(
                          width:
                              buttonSpacing), // Responsive spacing for buttons
                      if (onDelete != null)
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: Theme.of(context).colorScheme.error,
                              size: actionIconSize), // Responsive icon size
                          onPressed: onDelete,
                          tooltip: 'Supprimer',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8), // Standard spacing

              // This Expanded widget is crucial for the Column to fill the remaining vertical space.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisSize.min is correct for a column inside an Expanded,
                  // as it tells the column to only occupy as much space as its children need,
                  // letting the Expanded distribute the rest.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                        context,
                        Icons.account_balance_wallet,
                        'Solde:',
                        '${compte.solde.toStringAsFixed(2)} TND',
                        onSurfaceColor,
                        fontSize: mainDetailFontSize,
                        detailIconSize: detailIconSize),
                    const SizedBox(height: 8), // Standard spacing
                    _buildDetailRow(context, Icons.layers, 'Stage:',
                        compte.stage.toString(), onSurfaceColor,
                        fontSize: mainDetailFontSize,
                        detailIconSize: detailIconSize),

                    const SizedBox(height: 8), // Standard spacing

                    // Secondary Details: Agence, Recruiter ID, Date Création
                    _buildDetailRow(context, Icons.business, 'Agence:',
                        compte.agence, onSurfaceColor,
                        fontSize: secondaryDetailFontSize,
                        detailIconSize: detailIconSize),
                    const SizedBox(height: 8), // Standard spacing
                    _buildDetailRow(
                        context,
                        Icons.person,
                        'Recruiter ID:',
                        compte.recruiter_id != null &&
                                compte.recruiter_id!.length > 10
                            ? '${compte.recruiter_id!.substring(0, 10)}...'
                            : compte.recruiter_id ?? 'N/A',
                        onSurfaceColor,
                        fontSize: secondaryDetailFontSize,
                        detailIconSize: detailIconSize),
                    const SizedBox(height: 8), // Standard spacing
                    _buildDetailRow(
                        context,
                        Icons.calendar_today,
                        'Date Création:',
                        DateFormat('dd/MM/yyyy').format(compte.date_creation),
                        onSurfaceColor,
                        fontSize: secondaryDetailFontSize,
                        detailIconSize: detailIconSize),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generalized helper function with adjustable font and icon sizes
  Widget _buildDetailRow(BuildContext context, IconData icon, String label,
      String value, Color color,
      {required double fontSize, required double detailIconSize}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 2.0), // Minimal vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: detailIconSize,
              color: color.withOpacity(0.8)), // Used detailIconSize
          const SizedBox(width: 8),
          Expanded(
            // Ensures the text takes available horizontal space and wraps if needed
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: fontSize, // Dynamic font size
                        ),
                  ),
                  TextSpan(
                    text: ' $value',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color.withOpacity(0.9),
                          fontSize: fontSize, // Dynamic font size
                        ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1, // Keep maxLines to prevent excessive vertical growth
            ),
          ),
        ],
      ),
    );
  }
}
