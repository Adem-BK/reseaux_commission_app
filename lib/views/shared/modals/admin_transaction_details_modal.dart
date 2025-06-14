import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart'; // NO LONGER NEEDED HERE!

// Import models using your specified paths
import 'package:reseaux_commission_app/models/transactions.dart';
import 'package:reseaux_commission_app/models/compte.dart';
// import 'package:reseaux_commission_app/models/users.dart'; // NO LONGER NEEDED HERE!
// import 'package:reseaux_commission_app/models/commissions.dart'; // NO LONGER NEEDED HERE!

// Helper class for the main page to pass all necessary data to the modal
class TransactionWithCompteDetails {
  final Transactions transaction;
  final Compte? associatedCompte; // Can be null if account not found

  TransactionWithCompteDetails(
      {required this.transaction, this.associatedCompte});
}

// Enum to represent the outcome of the modal
enum TransactionModalOutcome {
  approved,
  refused,
  cancelled,
  error,
}

class AdminTransactionDetailsModal extends StatefulWidget {
  final TransactionWithCompteDetails transactionDetails;

  const AdminTransactionDetailsModal(
      {super.key, required this.transactionDetails});

  @override
  State<AdminTransactionDetailsModal> createState() =>
      _AdminTransactionDetailsModalState();
}

class _AdminTransactionDetailsModalState
    extends State<AdminTransactionDetailsModal> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final Uuid _uuid = Uuid(); // REMOVED: Uuid is no longer needed in the modal

  late Transactions _currentTransaction;
  bool _isProcessing = false; // To disable buttons during async operations

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transactionDetails.transaction;
  }

  // Helper for building detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // This method is greatly simplified.
  // It only handles updating the transaction status and the account balance.
  // It DOES NOT handle commission calculation.
  Future<void> _updateTransactionStatus(String newStatus) async {
    setState(() {
      _isProcessing = true;
    });

    final currentAdminId = _auth.currentUser?.uid;

    try {
      // 1. Update the transaction document
      await _firestore
          .collection('transactions')
          .doc(_currentTransaction.transaction_id)
          .update({
        'status': newStatus,
        'admin_approver_id': currentAdminId,
        'approval_date': Timestamp.now(),
      });

      // Update local state (for UI refresh, though modal will likely close)
      setState(() {
        _currentTransaction = _currentTransaction.copyWith(
          status: newStatus,
          admin_approver_id: currentAdminId,
          approval_date: DateTime.now(),
        );
      });

      // 2. Handle account balance update ONLY if transaction is approved
      if (newStatus == 'Approuvé' &&
          widget.transactionDetails.associatedCompte != null) {
        print(
            'DEBUG (Modal): Transaction Approved. Attempting account balance update.');
        final Compte associatedCompte =
            widget.transactionDetails.associatedCompte!;
        double newBalance = associatedCompte.solde;

        if (_currentTransaction.type == 'Crédit') {
          newBalance += _currentTransaction.amount;
        } else if (_currentTransaction.type == 'Débit') {
          if (newBalance < _currentTransaction.amount) {
            // Insufficient balance, revert status and inform user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Erreur: Solde insuffisant pour la transaction de débit. Revertissement à "En Attente".')),
              );
              // Revert transaction status if balance is insufficient
              await _firestore
                  .collection('transactions')
                  .doc(_currentTransaction.transaction_id)
                  .update({
                'status': 'En Attente', // Revert to pending
                'admin_approver_id': null,
                'approval_date': null,
              });
              setState(() {
                _currentTransaction = _currentTransaction.copyWith(
                  status: 'En Attente',
                  admin_approver_id: null,
                  approval_date: null,
                );
              });
              // Pop with error/cancelled status
              if (mounted)
                Navigator.of(context).pop(TransactionModalOutcome.error);
              return; // Stop processing
            }
          }
          newBalance -= _currentTransaction.amount;
        }

        // Update the account balance in Firestore
        await _firestore
            .collection('compte')
            .doc(associatedCompte.num_cpt)
            .update({
          'solde': newBalance,
        });

        print(
            'DEBUG (Modal): Account balance updated for ${associatedCompte.num_cpt}: $newBalance');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Transaction ${newStatus}e et solde du compte mis à jour.')),
          );
        }
        if (mounted) {
          Navigator.of(context)
              .pop(TransactionModalOutcome.approved); // Signal success
        }
      } else if (newStatus == 'Refusé') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaction ${newStatus}e avec succès!')),
          );
        }
        if (mounted) {
          Navigator.of(context)
              .pop(TransactionModalOutcome.refused); // Signal refusal
        }
      } else {
        // Should not happen for 'En Attente' status, but as a fallback
        if (mounted) {
          Navigator.of(context).pop(TransactionModalOutcome.cancelled);
        }
      }
    } on FirebaseException catch (e) {
      print(
          'ERROR (Modal): Firebase Exception in _updateTransactionStatus: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Firebase: ${e.message}')),
        );
        Navigator.of(context).pop(TransactionModalOutcome.error);
      }
    } catch (e) {
      print('ERROR (Modal): General Exception in _updateTransactionStatus: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        Navigator.of(context).pop(TransactionModalOutcome.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Compte? associatedCompte = widget.transactionDetails.associatedCompte;

    return AlertDialog(
      title: const Text('Détails de la Transaction'),
      content: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: 0.0, vertical: 8.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
                'ID Transaction:', _currentTransaction.transaction_id),
            _buildDetailRow('Compte ID:', _currentTransaction.compte_id),
            _buildDetailRow('Type:', _currentTransaction.type),
            _buildDetailRow('Montant:',
                '${_currentTransaction.amount.toStringAsFixed(2)} TND'),
            _buildDetailRow('Statut:', _currentTransaction.status),
            _buildDetailRow(
                'Date de Création:',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(_currentTransaction.date_creation)),
            _buildDetailRow('ID Approbateur Admin:',
                _currentTransaction.admin_approver_id ?? 'N/A'),
            _buildDetailRow(
                'Date d\'Approbation:',
                _currentTransaction.approval_date != null
                    ? DateFormat('dd/MM/yyyy HH:mm')
                        .format(_currentTransaction.approval_date!)
                    : 'N/A'),
            _buildDetailRow('URL Reçu Image:',
                _currentTransaction.receipt_image_url ?? 'N/A'),
            _buildDetailRow(
                'Données QR Code:', _currentTransaction.qr_code_data ?? 'N/A'),
            _buildDetailRow('Notes:', _currentTransaction.notes ?? 'N/A'),
            _buildDetailRow('Commission Calculée:',
                _currentTransaction.is_commission_calculated ? 'Oui' : 'Non'),
            if (associatedCompte != null) ...[
              const Divider(),
              Text(
                'Détails du Compte Associé:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _buildDetailRow('Numéro de Compte:', associatedCompte.num_cpt),
              _buildDetailRow('Solde Actuel:',
                  '${associatedCompte.solde.toStringAsFixed(2)} TND'),
              _buildDetailRow('Agence:', associatedCompte.agence),
              _buildDetailRow('UID Propriétaire:', associatedCompte.owner_uid),
              if (associatedCompte.recruiter_id != null &&
                  associatedCompte.recruiter_id!.isNotEmpty)
                _buildDetailRow(
                    'ID Recruteur:', associatedCompte.recruiter_id!),
            ] else ...[
              const Divider(),
              const Text('Aucun compte associé trouvé pour cette transaction.',
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing
              ? null
              : () => Navigator.of(context).pop(
                  TransactionModalOutcome.cancelled), // Disable if processing
          child: const Text('Fermer'),
        ),
        if (_currentTransaction.status == 'En Attente') ...[
          ElevatedButton.icon(
            icon: _isProcessing
                ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                : const Icon(Icons.check_circle_outline),
            label: Text(_isProcessing ? 'Traitement...' : 'Approuver'),
            onPressed: _isProcessing
                ? null
                : () => _updateTransactionStatus('Approuvé'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            icon: _isProcessing
                ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                : const Icon(Icons.cancel_outlined),
            label: Text(_isProcessing ? 'Traitement...' : 'Refuser'),
            onPressed:
                _isProcessing ? null : () => _updateTransactionStatus('Refusé'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ],
    );
  }
}
