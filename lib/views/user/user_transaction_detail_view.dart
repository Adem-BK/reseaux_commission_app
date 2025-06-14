// lib/views/user/user_transaction_detail_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transactions.dart'; // Adjust path if necessary based on your project structure

class UserTransactionDetailView extends StatelessWidget {
  final Transactions transaction;

  const UserTransactionDetailView({super.key, required this.transaction});

  // Helper method for showing image dialog (reusing from UserTransactionsView logic)
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Image de Reçu'),
          content: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (ctx, error, stacktrace) =>
                      const Icon(Icons.broken_image, size: 50),
                )
              : const Text('URL d\'image non valide.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to determine the color for transaction status
  Color _getStatusColor(String status, BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    switch (status.toLowerCase()) {
      case 'en attente':
        return Colors.orange.shade700;
      case 'approuvé':
        return Colors.green.shade700;
      case 'rejeté':
        return errorColor;
      default:
        return onSurfaceColor.withOpacity(0.7);
    }
  }

  // A helper widget builder for consistent row layout for details
  Widget _buildDetailRow(
      BuildContext context, String label, String value, TextStyle? valueStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge;
    final boldTextStyle = textStyle?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(context, 'ID Transaction:',
                    transaction.transaction_id, boldTextStyle),
                _buildDetailRow(
                    context, 'Compte ID:', transaction.compte_id, textStyle),
                _buildDetailRow(
                  context,
                  'Montant:',
                  '${transaction.amount.toStringAsFixed(2)} TND',
                  boldTextStyle?.copyWith(
                      color: transaction.type.toLowerCase() == 'crédit'
                          ? Colors.green.shade700
                          : theme.colorScheme.error),
                ),
                _buildDetailRow(context, 'Type:', transaction.type, textStyle),
                _buildDetailRow(
                  context,
                  'Statut:',
                  transaction.status,
                  boldTextStyle?.copyWith(
                      color: _getStatusColor(transaction.status, context)),
                ),
                _buildDetailRow(
                    context,
                    'Date de Création:',
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(transaction.date_creation),
                    textStyle),
                if (transaction.admin_approver_id != null &&
                    transaction.admin_approver_id!.isNotEmpty)
                  _buildDetailRow(context, 'Approbateur Admin:',
                      transaction.admin_approver_id!, textStyle),
                if (transaction.notes != null && transaction.notes!.isNotEmpty)
                  _buildDetailRow(
                      context, 'Notes:', transaction.notes!, textStyle),
                if (transaction.receipt_image_url != null &&
                    transaction.receipt_image_url!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 30),
                      Text('Preuve de Réçu:', style: boldTextStyle),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: () => _showImageDialog(
                              context, transaction.receipt_image_url!),
                          child: Container(
                            height: 200, // Fixed height for the image preview
                            width: double.infinity, // Take full width
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.5)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                transaction.receipt_image_url!,
                                fit: BoxFit
                                    .cover, // Cover the box, crop if necessary
                                loadingBuilder: (ctx, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (ctx, error, stacktrace) =>
                                    Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          size: 50,
                                          color: theme.colorScheme.error),
                                      const SizedBox(height: 8),
                                      const Text(
                                          'Échec du chargement de l\'image'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '(Appuyez sur l\'image pour l\'agrandir)',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
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
