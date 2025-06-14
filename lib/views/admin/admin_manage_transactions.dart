// lib/views/admin/admin_manage_transactions.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import models
import 'package:reseaux_commission_app/models/transactions.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/views/admin/admin_transaction_detail_page.dart';
// Import the shared TransactionWithCompteDetails class
import 'package:reseaux_commission_app/views/shared/modals/admin_transaction_details_modal.dart';

class AdminManageTransactions extends StatefulWidget {
  const AdminManageTransactions({super.key});

  @override
  State<AdminManageTransactions> createState() =>
      _AdminManageTransactionsState();
}

class _AdminManageTransactionsState extends State<AdminManageTransactions> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<TransactionWithCompteDetails> _allTransactionsWithDetails = [];
  List<TransactionWithCompteDetails> _filteredTransactionsWithDetails = [];

  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();

  // Sorting options
  String _sortColumn = 'date_creation'; // Default sort
  bool _sortAscending = false; // Default: descending for date

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _searchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTransactions);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionSnapshot =
          await _firestore.collection('transactions').get();
      List<TransactionWithCompteDetails> fetchedTransactionsWithDetails = [];

      // Cache for Compte documents to avoid redundant fetches
      Map<String, Compte> comptesCache = {};

      for (var doc in transactionSnapshot.docs) {
        if (doc.data().isNotEmpty) {
          try {
            // Attempt to parse the transaction using your model
            final transaction = Transactions.fromJson(
                doc.id, doc.data() as Map<String, dynamic>);

            Compte? associatedCompte;
            // Fetch associated account details
            if (comptesCache.containsKey(transaction.compte_id)) {
              associatedCompte = comptesCache[transaction.compte_id];
            } else {
              // Fetch from Firestore
              final compteDoc = await _firestore
                  .collection('compte')
                  .doc(transaction.compte_id)
                  .get();
              if (compteDoc.exists && compteDoc.data() != null) {
                try {
                  associatedCompte = Compte.fromJson(
                      compteDoc.id, compteDoc.data() as Map<String, dynamic>);
                  comptesCache[transaction.compte_id] =
                      associatedCompte; // Cache it
                } catch (e) {
                  print(
                      'ERROR: Failed to parse associated Compte ${compteDoc.id}: $e');
                }
              } else {
                print(
                    'WARNING: Associated Compte ${transaction.compte_id} not found for transaction ${transaction.transaction_id}');
              }
            }
            fetchedTransactionsWithDetails.add(TransactionWithCompteDetails(
              transaction: transaction,
              associatedCompte: associatedCompte,
            ));
          } catch (e) {
            print(
                'ERROR: Failed to parse Transaction document ID: ${doc.id}, Error: $e, Data: ${doc.data()}');
            // Log the error but continue processing other documents
          }
        } else {
          print('WARNING: Skipping empty Transaction document ID: ${doc.id}');
        }
      }

      setState(() {
        _allTransactionsWithDetails = fetchedTransactionsWithDetails;
        _filterTransactions(); // Apply initial filter and sort
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des transactions: ${e.message}';
        print('Firebase Error: ${e.code} - ${e.message}');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue: $e';
        print('General Error: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTransactions() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTransactionsWithDetails =
          _allTransactionsWithDetails.where((data) {
        final transaction = data.transaction;
        final compte = data.associatedCompte;

        // Search by Transaction fields
        if (transaction.transaction_id.toLowerCase().contains(query))
          return true;
        if (transaction.compte_id.toLowerCase().contains(query)) return true;
        if (transaction.amount.toStringAsFixed(2).contains(query)) return true;
        if (transaction.status.toLowerCase().contains(query)) return true;
        if (transaction.type.toLowerCase().contains(query)) return true;
        if (DateFormat('dd/MM/yyyy HH:mm')
            .format(transaction.date_creation)
            .toLowerCase()
            .contains(query)) return true;
        if (transaction.receipt_image_url != null &&
            transaction.receipt_image_url!.toLowerCase().contains(query))
          return true;
        if (transaction.notes != null &&
            transaction.notes!.toLowerCase().contains(query)) return true;

        // Search by Associated Compte details
        if (compte != null) {
          if (compte.num_cpt.toLowerCase().contains(query)) return true;
          if (compte.agence.toLowerCase().contains(query)) return true;
          if (compte.owner_uid.toLowerCase().contains(query)) return true;
        }

        return false;
      }).toList();
      _sortTransactions(); // Re-apply sort after filtering
    });
  }

  void _sortTransactions() {
    _filteredTransactionsWithDetails.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'date_creation':
          comparison = a.transaction.date_creation
              .compareTo(b.transaction.date_creation);
          break;
        case 'amount':
          comparison = a.transaction.amount.compareTo(b.transaction.amount);
          break;
        case 'status':
          comparison = a.transaction.status.compareTo(b.transaction.status);
          break;
        case 'type':
          comparison = a.transaction.type.compareTo(b.transaction.type);
          break;
        case 'compte_id': // Sort by compte_id, then by num_cpt if Compte is available
          comparison =
              a.transaction.compte_id.compareTo(b.transaction.compte_id);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        // Default for date and amount is descending, others ascending
        _sortAscending =
            (column == 'date_creation' || column == 'amount') ? false : true;
      }
      _sortTransactions();
    });
  }

  Future<void> _viewTransactionDetails(
      TransactionWithCompteDetails details) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminTransactionDetailsPage(transactionDetails: details),
      ),
    );

    if (result == true) {
      _fetchTransactions(); // Refresh the list if transaction status was updated on the details page
    }
  }

  // Helper for status icon
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approuvé':
        return Icons.check_circle;
      case 'En Attente':
        return Icons.hourglass_empty;
      case 'Refusé':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Helper for status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approuvé':
        return Colors.green;
      case 'En Attente':
        return Colors.orange;
      case 'Refusé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar is removed
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 80,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchTransactions,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Card replacing AppBar
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.swap_horiz, // Icon for transactions
                                  size: 40,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Gérer les Transactions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ],
                            ),
                            const SizedBox(
                                height:
                                    16), // Spacing between title/icon and search bar
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText:
                                    'Rechercher par ID, compte ID, montant, statut, type, date, notes ou compte associé...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              'Total: ${_filteredTransactionsWithDetails.length} transactions'),
                          PopupMenuButton<String>(
                            onSelected: _onSort,
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'date_creation',
                                child: Text('Trier par Date de Création'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'amount',
                                child: Text('Trier par Montant'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'status',
                                child: Text('Trier par Statut'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'type',
                                child: Text('Trier par Type'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'compte_id',
                                child: Text('Trier par ID Compte'),
                              ),
                            ],
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Text('Trier'),
                                  Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredTransactionsWithDetails.length,
                        itemBuilder: (context, index) {
                          final data = _filteredTransactionsWithDetails[index];
                          final transaction = data.transaction;
                          final associatedCompte = data.associatedCompte;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            elevation: 1,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    _getStatusColor(transaction.status),
                                child: Icon(_getStatusIcon(transaction.status),
                                    color: Colors.white, size: 20),
                              ),
                              title: Text(
                                'Transaction ID: ${transaction.transaction_id}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                  'Type: ${transaction.type} - Montant: ${transaction.amount.toStringAsFixed(2)} TND\nStatut: ${transaction.status} - Compte: ${transaction.compte_id}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Colors.green),
                                onPressed: () => _viewTransactionDetails(
                                    data), // Navigate to the new page
                                tooltip: 'Voir les détails et gérer',
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow(
                                          'Date de Création:',
                                          DateFormat('dd/MM/yyyy HH:mm').format(
                                              transaction.date_creation)),
                                      _buildDetailRow(
                                          'URL Reçu:',
                                          transaction.receipt_image_url ??
                                              'N/A'),
                                      _buildDetailRow('Données QR:',
                                          transaction.qr_code_data ?? 'N/A'),
                                      _buildDetailRow(
                                          'Notes:', transaction.notes ?? 'N/A'),
                                      _buildDetailRow(
                                          'Commission Calculée:',
                                          transaction.is_commission_calculated
                                              ? 'Oui'
                                              : 'Non'),
                                      if (transaction.status !=
                                          'En Attente') ...[
                                        _buildDetailRow(
                                            'Approuvé par:',
                                            transaction.admin_approver_id ??
                                                'N/A'),
                                        _buildDetailRow(
                                            'Date d\'Approbation:',
                                            transaction.approval_date != null
                                                ? DateFormat('dd/MM/yyyy HH:mm')
                                                    .format(transaction
                                                        .approval_date!)
                                                : 'N/A'),
                                      ],
                                      if (associatedCompte != null) ...[
                                        const Divider(),
                                        Text(
                                          'Détails du Compte Associé (Expansion):',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        _buildDetailRow('Numéro de Compte:',
                                            associatedCompte.num_cpt),
                                        _buildDetailRow('Solde Actuel:',
                                            '${associatedCompte.solde.toStringAsFixed(2)} TND'),
                                        _buildDetailRow(
                                            'Agence:', associatedCompte.agence),
                                        _buildDetailRow('UID Propriétaire:',
                                            associatedCompte.owner_uid),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // Helper for building detail rows (replicated here for convenience, could be in a shared utility)
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
}
