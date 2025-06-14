// lib/views/user/compte_transactions_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:reseaux_commission_app/models/compte.dart'; // Import Compte model
import 'package:reseaux_commission_app/models/transactions.dart'; // Import Transactions model
import 'package:reseaux_commission_app/views/shared/modals/add_transaction_modal.dart'; // Import the new modal
import 'package:reseaux_commission_app/views/user/user_transaction_detail_view.dart'; // NEW: Import the transaction detail view

// Enum to define sorting options for transactions
enum TransactionSortOption {
  dateCreation,
  amount,
  type,
  status,
  none, // Represents no specific sorting, reverts to default fetch order
}

class CompteTransactionsView extends StatefulWidget {
  final Compte compte; // Receive the specific account

  const CompteTransactionsView({super.key, required this.compte});

  @override
  State<CompteTransactionsView> createState() => _CompteTransactionsViewState();
}

class _CompteTransactionsViewState extends State<CompteTransactionsView> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = ''; // State variable to hold the current search query

  // State variables for sorting
  TransactionSortOption _currentSortOption = TransactionSortOption.dateCreation;
  bool _isSortDescending =
      true; // Default to descending for date (latest first)

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Method to update search text and trigger UI rebuild
  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      // No direct call to sort here; sorting is handled in the StreamBuilder's builder
    });
  }

  // Helper method to perform client-side sorting on the list of transactions
  List<Transactions> _sortTransactions(List<Transactions> transactions) {
    if (_currentSortOption == TransactionSortOption.none) {
      return transactions; // Return as is if no specific sort option is selected
    }

    transactions.sort((a, b) {
      int comparison = 0;
      switch (_currentSortOption) {
        case TransactionSortOption.dateCreation:
          comparison = a.date_creation.compareTo(b.date_creation);
          break;
        case TransactionSortOption.amount:
          comparison = a.amount.compareTo(b.amount);
          break;
        case TransactionSortOption.type:
          comparison = a.type.toLowerCase().compareTo(b.type.toLowerCase());
          break;
        case TransactionSortOption.status:
          comparison = a.status.toLowerCase().compareTo(b.status.toLowerCase());
          break;
        case TransactionSortOption.none:
          // Should not be reached due to the initial check
          break;
      }
      return _isSortDescending ? -comparison : comparison;
    });
    return transactions;
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

  void _showAddTransactionModal() {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Veuillez vous connecter pour ajouter une transaction.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddTransactionModal(
          compteId: widget.compte.num_cpt, // Pass the current account's ID
        );
      },
    );
  }

  // Helper method for showing image dialog (reused from previous implementation)
  void _showImageDialogInView(BuildContext context, String imageUrl) {
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final errorColor = Theme.of(context).colorScheme.error;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off,
                    size: 80, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 20),
                Text(
                  'Veuillez vous connecter pour voir et ajouter des transactions.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Account Info Card (updated to resemble the images)
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color:
                  primaryColor, // Using primary color for the card background
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Compte Courant', // Or a dynamic account type if available
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '**** **** **** ${widget.compte.num_cpt.substring(widget.compte.num_cpt.length - 4)}', // Mask account number
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agence',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.compte.agence,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Solde',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withOpacity(
                                        0.2), // Subtle background for balance
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.compte.solde.toStringAsFixed(2)} TND',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Title and Sort Options
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toutes les transactions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sort Options Dropdown
                    PopupMenuButton<TransactionSortOption>(
                      onSelected: (TransactionSortOption result) {
                        setState(() {
                          if (result == _currentSortOption) {
                            // If the same option is selected, toggle descending order
                            _isSortDescending = !_isSortDescending;
                          } else {
                            // If a new option is selected, set it and default to descending for numeric/date
                            _currentSortOption = result;
                            _isSortDescending = (_currentSortOption ==
                                    TransactionSortOption.dateCreation ||
                                _currentSortOption ==
                                    TransactionSortOption.amount);
                          }
                          // No need to call a sort function here, setState will trigger StreamBuilder to rebuild
                          // and the sorting logic will be applied within the builder.
                        });
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<TransactionSortOption>>[
                        const PopupMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.dateCreation,
                          child: Text('Date'),
                        ),
                        const PopupMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.amount,
                          child: Text('Montant'),
                        ),
                        const PopupMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.type,
                          child: Text('Type'),
                        ),
                        const PopupMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.status,
                          child: Text('Statut'),
                        ),
                        const PopupMenuItem<TransactionSortOption>(
                          value: TransactionSortOption.none,
                          child: Text('Défaut (Date descendante)'),
                        ),
                      ],
                      icon: Icon(Icons.sort,
                          color: Theme.of(context)
                                  .appBarTheme
                                  .actionsIconTheme
                                  ?.color ??
                              onSurfaceColor),
                      tooltip: 'Trier les transactions',
                    ),
                    IconButton(
                      icon: Icon(
                        _isSortDescending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: Theme.of(context)
                                .appBarTheme
                                .actionsIconTheme
                                ?.color ??
                            onSurfaceColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSortDescending = !_isSortDescending;
                        });
                      },
                      tooltip: _isSortDescending
                          ? 'Ordre décroissant'
                          : 'Ordre croissant',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une transaction...',
                prefixIcon:
                    Icon(Icons.search, color: onSurfaceColor.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 16.0),
              ),
              style: TextStyle(color: onSurfaceColor),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('compte_id',
                      isEqualTo: widget
                          .compte.num_cpt) // Filter by current account's ID
                  .snapshots(), // Remove orderBy here to allow client-side sorting for all fields
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 80, color: errorColor),
                          const SizedBox(height: 20),
                          Text(
                            'Erreur lors du chargement des transactions: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: errorColor),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Veuillez vous assurer que l\'index Firestore est créé et configuré correctement (compte_id ASC).',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off,
                            size: 80, color: primaryColor.withOpacity(0.6)),
                        const SizedBox(height: 20),
                        Text(
                          'Aucune transaction trouvée pour ce compte.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: primaryColor),
                        ),
                      ],
                    ),
                  );
                }

                // Map data to Transactions objects
                List<Transactions> transactions =
                    snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Transactions.fromJson(
                      doc.id, data); // Pass doc.id as transaction_id
                }).toList();

                // Apply search filter to the list of transactions
                final filteredTransactions = transactions.where((transaction) {
                  final query = _searchText;
                  if (query.isEmpty) {
                    return true; // No filter, show all
                  }

                  // Convert relevant fields to lowercase for case-insensitive search
                  final transactionId =
                      transaction.transaction_id.toLowerCase();
                  final amount = transaction.amount.toString().toLowerCase();
                  final status = transaction.status.toLowerCase();
                  final type = transaction.type.toLowerCase();
                  final dateCreation = DateFormat('dd/MM/yyyy HH:mm')
                      .format(transaction.date_creation)
                      .toLowerCase();
                  final notes = transaction.notes?.toLowerCase() ?? '';

                  return transactionId.contains(query) ||
                      amount.contains(query) ||
                      status.contains(query) ||
                      type.contains(query) ||
                      dateCreation.contains(query) ||
                      notes.contains(query);
                }).toList();

                // Apply sorting to the filtered list
                final sortedTransactions =
                    _sortTransactions(List.from(filteredTransactions));

                if (sortedTransactions.isEmpty && _searchText.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 80, color: onSurfaceColor.withOpacity(0.6)),
                        const SizedBox(height: 20),
                        Text(
                          'Aucune transaction trouvée pour la recherche "$_searchController.text".',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: onSurfaceColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  itemCount: sortedTransactions.length, // Use sorted list
                  itemBuilder: (context, index) {
                    final transaction =
                        sortedTransactions[index]; // Use sorted list

                    Color transactionColor;
                    IconData transactionIcon;
                    switch (transaction.type.toLowerCase()) {
                      case 'crédit':
                        transactionColor = Colors.green;
                        transactionIcon = Icons.arrow_upward;
                        break;
                      case 'débit':
                        transactionColor = errorColor;
                        transactionIcon = Icons.arrow_downward;
                        break;
                      default:
                        transactionColor = onSurfaceColor.withOpacity(0.7);
                        transactionIcon = Icons.swap_horiz;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      color: Theme.of(context).colorScheme.surface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: transactionColor.withOpacity(0.2),
                          child: Icon(transactionIcon, color: transactionColor),
                        ),
                        title: Text(
                          '${transaction.type} : ${transaction.amount.toStringAsFixed(2)} TND',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transactionColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID Transaction: ${transaction.transaction_id}',
                              style: TextStyle(
                                  color: onSurfaceColor.withOpacity(0.8)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                'Statut: ${transaction.status}',
                                style: TextStyle(
                                  color: _getStatusColor(
                                      transaction.status, context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.date_creation)}',
                              style: TextStyle(
                                  color: onSurfaceColor.withOpacity(0.7)),
                            ),
                            if (transaction.notes != null &&
                                transaction.notes!.isNotEmpty)
                              Text(
                                'Notes: ${transaction.notes}',
                                style: TextStyle(
                                    color: onSurfaceColor.withOpacity(0.7)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (transaction.receipt_image_url != null &&
                                transaction.receipt_image_url!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: InkWell(
                                  onTap: () {
                                    _showImageDialogInView(context,
                                        transaction.receipt_image_url!);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image,
                                          size: 18, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text('Voir Reçu',
                                          style:
                                              TextStyle(color: primaryColor)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: onSurfaceColor.withOpacity(0.5), size: 16),
                        onTap: () {
                          // Navigate to the UserTransactionDetailView
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserTransactionDetailView(
                                  transaction:
                                      transaction), // Pass the transaction object
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionModal,
        label: const Text('Ajouter Transaction'),
        icon: const Icon(Icons.add),
        backgroundColor: primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
