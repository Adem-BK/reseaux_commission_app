// lib/views/admin/admin_transaction_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Required for generating unique IDs for commissions

// Import models
import 'package:reseaux_commission_app/models/transactions.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/models/commissions.dart'; // Import your Commissions model

// Import the shared TransactionWithCompteDetails class (this class will remain in the modal file)
import 'package:reseaux_commission_app/views/shared/modals/admin_transaction_details_modal.dart';

class AdminTransactionDetailsPage extends StatefulWidget {
  final TransactionWithCompteDetails transactionDetails;

  const AdminTransactionDetailsPage(
      {super.key, required this.transactionDetails});

  @override
  State<AdminTransactionDetailsPage> createState() =>
      _AdminTransactionDetailsPageState();
}

class _AdminTransactionDetailsPageState
    extends State<AdminTransactionDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid(); // Instantiate Uuid here for use in this page

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
          style: Theme.of(context)
              .textTheme
              .bodyMedium, // Use bodyMedium from theme
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

  /// Calculates the commission amount based on the transaction amount and stage rules.
  /// Returns a map containing 'amount' and 'percentage'.
  Map<String, double> _calculateCommissionAmountAndPercentage(
      double transactionAmount, int stage) {
    double commissionAmount = 0.0;
    double commissionPercentage = 0.0;

    // Normalize transactionAmount to nearest multiple of 50 for calculation
    // e.g., if amount is 120, calculation is for 100. If 40, calculation is for 0.
    int multiplesOf50 = (transactionAmount / 50).floor();

    if (multiplesOf50 > 0) {
      if (stage == 1) {
        commissionAmount = multiplesOf50 * 10.0; // 10 TND for each 50 TND
        commissionPercentage = 20.0; // (10 / 50) * 100 = 20%
      } else if (stage >= 2 && stage <= 4) {
        commissionAmount = multiplesOf50 * 8.0; // 8 TND for each 50 TND
        commissionPercentage = 16.0; // (8 / 50) * 100 = 16%
      }
    }
    print(
        'DEBUG: Commission calculation for amount $transactionAmount, stage $stage: Multiples of 50: $multiplesOf50, Calculated Amount: $commissionAmount, Percentage: $commissionPercentage%');
    return {
      'amount': commissionAmount,
      'percentage': commissionPercentage,
    };
  }

  /// Calculates and saves a commission for an approved transaction,
  /// specifically for the recruiting account if applicable.
  Future<void> _calculateAndSaveCommission(
      Transactions transaction, Compte associatedCompte) async {
    print(
        'DEBUG: Starting _calculateAndSaveCommission for transaction ${transaction.transaction_id}');

    // Condition 1: Only for 'Crédit' transactions
    if (transaction.type != 'Crédit') {
      print(
          'DEBUG: Skipping commission calculation. Transaction type is not "Crédit".');
      return;
    }

    // Condition 2: Commission not already calculated
    if (transaction.is_commission_calculated) {
      print(
          'DEBUG: Skipping commission calculation. Commission already calculated for transaction ${transaction.transaction_id}.');
      return;
    }

    // Condition 3: Associated account must have a recruiter (account ID)
    if (associatedCompte.recruiter_id == null ||
        associatedCompte.recruiter_id!.isEmpty) {
      print(
          'DEBUG: Skipping commission calculation. Associated account ${associatedCompte.num_cpt} has no recruiter_id.');
      return;
    }

    // Now, recruiter_id is expected to be an Account ID.
    final String recruiterAccountId = associatedCompte.recruiter_id!;
    print(
        'DEBUG: Account has recruiter account: $recruiterAccountId. Proceeding to calculate commission.');

    try {
      // We need to fetch the recruiter account's owner_uid to associate with the commission.
      final DocumentSnapshot recruiterAccountDoc =
          await _firestore.collection('compte').doc(recruiterAccountId).get();

      String? recruiterOwnerUid;
      // You mentioned stages 1,2,3,4 but haven't specified how to determine the stage for a transaction.
      // For now, assuming a default stage 1 for direct commissions.
      // If a 'stage' field exists in 'compte' or 'transaction' that dictates commission stage,
      // you would fetch it here.
      int commissionStage =
          1; // Defaulting to stage 1 as per previous working example.
      // Example if stage was on the recruiter account:
      // if (recruiterAccountDoc.exists) {
      //   commissionStage = (recruiterAccountDoc.data() as Map<String, dynamic>)['commission_stage'] as int? ?? 1;
      // }

      if (recruiterAccountDoc.exists && recruiterAccountDoc.data() != null) {
        recruiterOwnerUid = (recruiterAccountDoc.data()
            as Map<String, dynamic>)['owner_uid'] as String?;
      }

      if (recruiterOwnerUid == null || recruiterOwnerUid.isEmpty) {
        print(
            'ERROR: Recruiter account $recruiterAccountId does not have an owner_uid. Cannot create commission.');
        return;
      }

      final Map<String, double> calculatedCommission =
          _calculateCommissionAmountAndPercentage(
              transaction.amount, commissionStage);
      final double commissionAmount = calculatedCommission['amount']!;
      final double commissionPercentage = calculatedCommission['percentage']!;

      if (commissionAmount <= 0) {
        print(
            'WARNING: Calculated commission amount is 0 or less for recruiter account $recruiterAccountId. Skipping commission creation.');
        return;
      }

      // Create a new commission record
      final String commissionId = _uuid.v4();

      final Commissions newCommission = Commissions(
        commissions_id: commissionId,
        from_compte_id: transaction
            .compte_id, // The account from which the transaction originated
        to_compte_id:
            recruiterAccountId, // The recruiting account ID that earns the commission
        owner_uid:
            recruiterOwnerUid, // The UID of the owner of the recruiting account
        stage:
            commissionStage, // The stage of this commission (e.g., 1, 2, 3, 4)
        amount: commissionAmount,
        transaction_id: transaction.transaction_id,
        commission_percentage:
            commissionPercentage, // The calculated percentage based on stage rules
        date_earned: DateTime.now(),
        status:
            'en attente', // Commission created, now waiting for admin validation
      );

      await _firestore
          .collection('commissions')
          .doc(commissionId)
          .set(newCommission.toMap()); // Use .toMap() for your model

      print(
          'SUCCESS: Commission $commissionId saved successfully for recruiter account $recruiterAccountId (owner UID: $recruiterOwnerUid).');

      // Update the transaction to mark commission as calculated
      await _firestore
          .collection('transactions')
          .doc(transaction.transaction_id)
          .update({'is_commission_calculated': true});

      // Update local state to reflect the change for UI
      setState(() {
        _currentTransaction =
            _currentTransaction.copyWith(is_commission_calculated: true);
      });

      print(
          'SUCCESS: Transaction ${transaction.transaction_id} marked as commission calculated.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Commission générée pour le compte recruteur.')),
        );
      }
    } on FirebaseException catch (e) {
      print(
          'ERROR: Firebase Exception during commission calculation/saving: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Firebase: ${e.message}')),
        );
      }
    } catch (e) {
      print(
          'ERROR: General Exception during commission calculation/saving: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  /// Handles the update of a transaction's status.
  /// If approved, it also triggers account balance update and commission calculation.
  Future<void> _updateTransactionStatus(String newStatus) async {
    setState(() {
      _isProcessing = true;
    });

    final currentAdminId = _auth.currentUser?.uid;

    try {
      // 1. Update the transaction document in Firestore
      await _firestore
          .collection('transactions')
          .doc(_currentTransaction.transaction_id)
          .update({
        'status': newStatus,
        'admin_approver_id': currentAdminId,
        'approval_date': Timestamp.now(),
      });

      // Update local transaction state for immediate UI refresh
      setState(() {
        _currentTransaction = _currentTransaction.copyWith(
          status: newStatus,
          admin_approver_id: currentAdminId,
          approval_date: DateTime.now(),
        );
      });

      // 2. If approved, handle account balance update and commission calculation
      if (newStatus == 'Approuvé' &&
          widget.transactionDetails.associatedCompte != null) {
        print(
            'DEBUG: Transaction approved. Processing account balance and commission.');
        final Compte associatedCompte =
            widget.transactionDetails.associatedCompte!;
        double newBalance = associatedCompte.solde;

        if (_currentTransaction.type == 'Crédit') {
          newBalance += _currentTransaction.amount;
        } else if (_currentTransaction.type == 'Débit') {
          // Check for sufficient balance for debit transactions
          if (newBalance < _currentTransaction.amount) {
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
                'status': 'En Attente',
                'admin_approver_id': null,
                'approval_date': null,
              });
              setState(() {
                // Update UI to reflect the reverted status
                _currentTransaction = _currentTransaction.copyWith(
                  status: 'En Attente',
                  admin_approver_id: null,
                  approval_date: null,
                );
                _isProcessing = false;
              });
              return; // Stop processing if balance is insufficient
            }
          }
          newBalance -= _currentTransaction.amount;
        }

        // Update the account balance in Firestore
        await _firestore
            .collection('compte')
            .doc(associatedCompte.num_cpt)
            .update({'solde': newBalance});

        print(
            'DEBUG: Account balance updated for ${associatedCompte.num_cpt}. New balance: $newBalance');

        // --- Commission Calculation Call ---
        // Conditions for commission: Approved, 'Crédit' type, NOT already calculated, AND has a recruiter.
        if (_currentTransaction.type == 'Crédit' &&
            !(_currentTransaction.is_commission_calculated ?? false) &&
            associatedCompte.recruiter_id != null &&
            associatedCompte.recruiter_id!.isNotEmpty) {
          print(
              'INFO: Conditions met for commission generation. Calling _calculateAndSaveCommission...');
          await _calculateAndSaveCommission(
              _currentTransaction, associatedCompte);
        } else {
          print(
              'INFO: Commission generation skipped for this transaction. Reasons: Type=${_currentTransaction.type}, Calculated=${_currentTransaction.is_commission_calculated}, Recruiter ID Present=${associatedCompte.recruiter_id != null && associatedCompte.recruiter_id!.isNotEmpty}');
        }
        // --- End Commission Calculation Call ---

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Transaction ${newStatus}e et solde du compte mis à jour.')),
          );
        }
      } else {
        // If status is not approved, or associatedCompte is null
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaction ${newStatus}e avec succès!')),
          );
        }
      }

      if (mounted) {
        // Pop with true on success, signaling the previous page (AdminManageTransactions) to refresh
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (e) {
      print(
          'ERROR: Firebase Exception in _updateTransactionStatus: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Firebase: ${e.message}')),
        );
      }
    } catch (e) {
      print('ERROR: General Exception in _updateTransactionStatus: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations sur la Transaction',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                        'ID Transaction:', _currentTransaction.transaction_id),
                    _buildDetailRow(
                        'Compte ID:', _currentTransaction.compte_id),
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
                    _buildDetailRow('Données QR Code:',
                        _currentTransaction.qr_code_data ?? 'N/A'),
                    _buildDetailRow(
                        'Notes:', _currentTransaction.notes ?? 'N/A'),
                    _buildDetailRow(
                        'Commission Calculée:',
                        _currentTransaction.is_commission_calculated
                            ? 'Oui'
                            : 'Non'),
                  ],
                ),
              ),
            ),
            if (associatedCompte != null)
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails du Compte Associé',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                          'Numéro de Compte:', associatedCompte.num_cpt),
                      _buildDetailRow('Solde Actuel:',
                          '${associatedCompte.solde.toStringAsFixed(2)} TND'),
                      _buildDetailRow('Agence:', associatedCompte.agence),
                      _buildDetailRow(
                          'UID Propriétaire:', associatedCompte.owner_uid),
                      // Display recruiter ID if available
                      if (associatedCompte.recruiter_id != null &&
                          associatedCompte.recruiter_id!.isNotEmpty)
                        _buildDetailRow(
                            'ID Recruteur:', associatedCompte.recruiter_id!),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Aucun compte associé trouvé pour cette transaction.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic, color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _currentTransaction.status == 'En Attente'
          ? BottomAppBar(
              elevation: 8,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isProcessing
                            ? const CircularProgressIndicator.adaptive(
                                strokeWidth: 2)
                            : const Icon(Icons.check_circle_outline),
                        label:
                            Text(_isProcessing ? 'Traitement...' : 'Approuver'),
                        onPressed: _isProcessing
                            ? null
                            : () => _updateTransactionStatus('Approuvé'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 16), 
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isProcessing
                            ? const CircularProgressIndicator.adaptive(
                                strokeWidth: 2)
                            : const Icon(Icons.cancel_outlined),
                        label:
                            Text(_isProcessing ? 'Traitement...' : 'Refuser'),
                        onPressed: _isProcessing
                            ? null
                            : () => _updateTransactionStatus('Refusé'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null, // No BottomAppBar if not 'En Attente'
    );
  }
}
