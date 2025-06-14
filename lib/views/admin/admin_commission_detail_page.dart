// lib/views/admin/admin_commission_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current admin's UID/ID
import 'package:intl/intl.dart';

// Import your models - Ensure these models correctly handle nullable fields
import 'package:reseaux_commission_app/models/commissions.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/models/transactions.dart';

class AdminCommissionDetailPage extends StatefulWidget {
  final Commissions commission; // Only accepting the Commissions model

  const AdminCommissionDetailPage({super.key, required this.commission});

  @override
  State<AdminCommissionDetailPage> createState() =>
      _AdminCommissionDetailPageState();
}

class _AdminCommissionDetailPageState extends State<AdminCommissionDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Commissions _currentCommission;
  Compte? _fromCompte;
  Compte? _toCompte;
  Transactions? _sourceTransaction;

  bool _isProcessingStatus = false; // For status update buttons
  bool _isLoadingRelatedData =
      true; // For fetching related accounts/transaction
  String? _relatedDataErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentCommission = widget.commission;
    _fetchRelatedDetails();
  }

  Future<void> _fetchRelatedDetails() async {
    if (!mounted) return; // Important: Prevent setState if widget is disposed

    setState(() {
      _isLoadingRelatedData = true;
      _relatedDataErrorMessage = null;
    });

    try {
      // Fetch fromCompte
      final fromCompteDoc = await _firestore
          .collection('compte')
          .doc(_currentCommission.from_compte_id)
          .get();
      if (fromCompteDoc.exists && fromCompteDoc.data() != null) {
        _fromCompte = Compte.fromJson(
            fromCompteDoc.id, fromCompteDoc.data() as Map<String, dynamic>);
      } else {
        // Log a warning if the document doesn't exist or has no data
        print(
            'WARNING: fromCompte for ID ${_currentCommission.from_compte_id} not found or data is null.');
        _fromCompte = null; // Ensure it's null if not found
      }

      // Fetch toCompte
      final toCompteDoc = await _firestore
          .collection('compte')
          .doc(_currentCommission.to_compte_id)
          .get();
      if (toCompteDoc.exists && toCompteDoc.data() != null) {
        _toCompte = Compte.fromJson(
            toCompteDoc.id, toCompteDoc.data() as Map<String, dynamic>);
      } else {
        // Log a warning if the document doesn't exist or has no data
        print(
            'WARNING: toCompte for ID ${_currentCommission.to_compte_id} not found or data is null.');
        _toCompte = null; // Ensure it's null if not found
      }

      // Fetch sourceTransaction
      final transactionDoc = await _firestore
          .collection('transactions')
          .doc(_currentCommission.transaction_id)
          .get();
      if (transactionDoc.exists && transactionDoc.data() != null) {
        _sourceTransaction = Transactions.fromJson(
            transactionDoc.id, transactionDoc.data() as Map<String, dynamic>);
      } else {
        // Log a warning if the document doesn't exist or has no data
        print(
            'WARNING: Source transaction for ID ${_currentCommission.transaction_id} not found or data is null.');
        _sourceTransaction = null; // Ensure it's null if not found
      }
    } on FirebaseException catch (e) {
      _relatedDataErrorMessage =
          'Erreur lors du chargement des détails liés: ${e.message}';
      print('Firebase Error fetching related data: ${e.code} - ${e.message}');
    } catch (e) {
      _relatedDataErrorMessage =
          'Une erreur inattendue est survenue lors du chargement des détails liés: $e';
      print('General Error fetching related data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRelatedData = false;
        });
      }
    }
  }

  // Helper for building detail rows
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value ?? 'N/A'), // Display 'N/A' if value is null
          ],
        ),
      ),
    );
  }

  Future<void> _updateCommissionStatus(String newStatus) async {
    if (!mounted) return; // Important: Prevent setState if widget is disposed

    setState(() {
      _isProcessingStatus = true;
    });

    final currentAdminId = _auth.currentUser?.uid;
    if (currentAdminId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Erreur: Utilisateur admin non connecté. Veuillez vous reconnecter.')),
        );
      }
      setState(() {
        _isProcessingStatus = false;
      });
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final commissionRef = _firestore
            .collection('commissions')
            .doc(_currentCommission.commissions_id);

        // --- ALL READS MUST BE EXECUTED BEFORE ANY WRITES ---

        // 1. Read the commission document to get its latest state
        final commissionSnapshot = await transaction.get(commissionRef);

        if (!commissionSnapshot.exists || commissionSnapshot.data() == null) {
          throw Exception("Commission introuvable ou données manquantes.");
        }
        final latestCommissionData = commissionSnapshot.data()!;
        final latestCommission =
            Commissions.fromJson(commissionSnapshot.id, latestCommissionData);

        // Check if the commission is already in a non-'en attente' state
        if (latestCommission.status.toLowerCase() != 'en attente') {
          throw Exception(
              "La commission n'est plus en attente (statut actuel: ${latestCommission.status}).");
        }

        // Only read the recipient's account if the status is changing to 'Payé'
        // This ensures the read is conditional and still part of the initial read phase.
        DocumentSnapshot<Map<String, dynamic>>? toCompteSnapshot;
        if (newStatus.toLowerCase() == 'payé') {
          final toCompteRef = _firestore
              .collection('compte')
              .doc(latestCommission.to_compte_id);
          toCompteSnapshot = await transaction.get(toCompteRef);

          if (!toCompteSnapshot.exists || toCompteSnapshot.data() == null) {
            throw Exception(
                "Compte bénéficiaire (ID: ${latestCommission.to_compte_id}) introuvable pour la mise à jour du solde.");
          }
        }

        // --- END OF READS, NOW PERFORM WRITES ---

        // 1. Update commission status
        transaction.update(commissionRef, {
          'status': newStatus,
          'admin_approver_id': currentAdminId,
          'date_approved': FieldValue.serverTimestamp(),
        });

        // 2. If marking as 'Payé', update the recipient's account balance
        if (newStatus.toLowerCase() == 'payé' && toCompteSnapshot != null) {
          final currentToCompteBalance =
              (toCompteSnapshot.data()!['solde'] as num?)?.toDouble() ?? 0.0;
          final newToCompteBalance =
              currentToCompteBalance + latestCommission.amount;

          transaction.update(toCompteSnapshot.reference, {
            'solde': newToCompteBalance,
          });
        }
      });

      // If the transaction is successful, update the UI and notify
      if (mounted) {
        // Update local state to reflect the changes immediately
        setState(() {
          _currentCommission = _currentCommission.copyWith(status: newStatus);
          if (newStatus.toLowerCase() == 'payé' && _toCompte != null) {
            // Only update if _toCompte was successfully loaded initially
            _toCompte = _toCompte!
                .copyWith(solde: _toCompte!.solde + _currentCommission.amount);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Statut de la commission mis à jour à "$newStatus" avec succès!')),
        );
        // Pop and signal success to previous page (if any) to refresh list
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        String errorMessage =
            'Erreur Firebase (${e.code}): ${e.message ?? "Une erreur est survenue."}';
        // Provide more user-friendly messages for specific Firebase errors
        if (e.code == 'unavailable') {
          errorMessage =
              'La connexion au serveur est indisponible. Veuillez vérifier votre connexion internet.';
        } else if (e.code == 'permission-denied') {
          errorMessage =
              'Vous n\'avez pas la permission d\'effectuer cette action.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      print('Firebase Error updating commission: ${e.code} - ${e.message}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erreur inattendue: ${e.toString()}')), // Use toString() for generic exceptions
        );
      }
      print('General Error updating commission status or account balance: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingStatus = false;
        });
      }
    }
  }

  // Helper for status icon (re-used from list page)
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'payé':
        return Icons.check_circle;
      case 'en attente':
        return Icons.hourglass_empty;
      case 'annulé':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Helper for status color (re-used from list page)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'payé':
        return Colors.green;
      case 'en attente':
        return Colors.orange;
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Commission'),
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
                      'Informations sur la Commission',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                        'ID Commission:', _currentCommission.commissions_id),
                    _buildDetailRow('Montant:',
                        '${_currentCommission.amount.toStringAsFixed(2)} TND'),
                    _buildDetailRow('Pourcentage:',
                        '${_currentCommission.commission_percentage.toStringAsFixed(2)}%'),
                    _buildDetailRow('Statut:', _currentCommission.status),
                    _buildDetailRow('Niveau de Référence:',
                        _currentCommission.stage.toString()),
                    _buildDetailRow('ID Compte Source (from):',
                        _currentCommission.from_compte_id),
                    _buildDetailRow('ID Compte Bénéficiaire (to):',
                        _currentCommission.to_compte_id),
                    _buildDetailRow('UID Propriétaire Bénéficiaire:',
                        _currentCommission.owner_uid),
                    _buildDetailRow('ID Transaction Source:',
                        _currentCommission.transaction_id),
                    _buildDetailRow(
                        'Date Gagnée:',
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(_currentCommission.date_earned)),
                  ],
                ),
              ),
            ),
            _isLoadingRelatedData
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))
                : _relatedDataErrorMessage != null
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _relatedDataErrorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ))
                    : Column(
                        // Display related details once loaded
                        children: [
                          if (_sourceTransaction != null)
                            Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Détails de la Transaction Source',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                    ),
                                    const Divider(height: 20),
                                    _buildDetailRow('ID Transaction:',
                                        _sourceTransaction!.transaction_id),
                                    _buildDetailRow(
                                        'Type:', _sourceTransaction!.type),
                                    _buildDetailRow('Montant Transaction:',
                                        '${_sourceTransaction!.amount.toStringAsFixed(2)} TND'),
                                    _buildDetailRow('Statut Transaction:',
                                        _sourceTransaction!.status),
                                    _buildDetailRow(
                                        'Date de Création:',
                                        DateFormat('dd/MM/yyyy HH:mm').format(
                                            _sourceTransaction!.date_creation)),
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
                                  'Aucune transaction source trouvée pour cette commission.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          if (_fromCompte != null)
                            Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Détails du Compte Source (from_compte_id)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                    ),
                                    const Divider(height: 20),
                                    _buildDetailRow('Numéro de Compte:',
                                        _fromCompte!.num_cpt),
                                    _buildDetailRow('Solde Actuel:',
                                        '${_fromCompte!.solde.toStringAsFixed(2)} TND'),
                                    _buildDetailRow(
                                        'Agence:', _fromCompte!.agence),
                                    _buildDetailRow('UID Propriétaire:',
                                        _fromCompte!.owner_uid),
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
                                  'Aucun compte source (from_compte_id) trouvé pour cette commission.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          if (_toCompte != null)
                            Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Détails du Compte Bénéficiaire (to_compte_id)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                    ),
                                    const Divider(height: 20),
                                    _buildDetailRow('Numéro de Compte:',
                                        _toCompte!.num_cpt),
                                    _buildDetailRow('Solde Actuel:',
                                        '${_toCompte!.solde.toStringAsFixed(2)} TND'),
                                    _buildDetailRow(
                                        'Agence:', _toCompte!.agence),
                                    _buildDetailRow('UID Propriétaire:',
                                        _toCompte!.owner_uid),
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
                                  'Aucun compte bénéficiaire (to_compte_id) trouvé pour cette commission.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[600]),
                                ),
                              ),
                            ),
                        ],
                      ),
          ],
        ),
      ),
      bottomNavigationBar: _currentCommission.status.toLowerCase() ==
              'en attente'
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
                        icon: _isProcessingStatus
                            ? const SizedBox(
                                width: 20, // Adjust size as needed
                                height: 20,
                                child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_isProcessingStatus
                            ? 'Traitement...'
                            : 'Marquer comme Payé'),
                        onPressed: _isProcessingStatus
                            ? null
                            : () => _updateCommissionStatus('Payé'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isProcessingStatus
                            ? const SizedBox(
                                width: 20, // Adjust size as needed
                                height: 20,
                                child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.cancel_outlined),
                        label: Text(_isProcessingStatus
                            ? 'Traitement...'
                            : 'Annuler la Commission'),
                        onPressed: _isProcessingStatus
                            ? null
                            : () => _updateCommissionStatus('Annulé'),
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
