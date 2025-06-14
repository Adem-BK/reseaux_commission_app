// lib/views/user/user_transactions_view.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

// Ensure these imports point to your actual model files
import 'package:reseaux_commission_app/models/transactions.dart'; // Import Transactions model
import 'package:reseaux_commission_app/views/user/user_transaction_detail_view.dart'; // Updated import for the new detail view

// Enum to define sorting options for transactions
enum TransactionSortOption {
  dateCreation,
  amount,
  type,
  status,
  none, // Represents no specific sorting, reverts to default fetch order
}

class UserTransactionsView extends StatefulWidget {
  const UserTransactionsView({super.key});

  @override
  State<UserTransactionsView> createState() => _UserTransactionsViewState();
}

class _UserTransactionsViewState extends State<UserTransactionsView> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = ''; // State variable to hold the current search query
  List<Transactions> _allTransactions = []; // Holds all fetched transactions
  List<Transactions> _filteredTransactions =
      []; // Holds transactions after search filter

  bool _isLoading = true; // Added loading state
  String? _errorMessage; // To display specific error messages

  // State variables for sorting
  TransactionSortOption _currentSortOption = TransactionSortOption.dateCreation;
  bool _isSortDescending =
      true; // Default to descending for date (latest first)

  @override
  void initState() {
    super.initState();
    _fetchTransactionsAndSetState(); // Call a dedicated method
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactionsAndSetState() async {
    if (!mounted) return; // Prevent setState if widget is disposed

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      final transactions = await _fetchTransactions();
      if (!mounted) return; // Re-check mounted after async operation
      setState(() {
        _allTransactions = transactions;
        _filterAndSortTransactions(); // Apply both filter and sort
        _isLoading = false;
      });
    } catch (e) {
      print(
          'Error fetching transactions: $e'); // Keep print for console debugging
      if (!mounted) return; // Re-check mounted before setState
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des transactions: $e';
        // Check for specific Firestore error messages
        if (e is FirebaseException && e.code == 'failed-precondition') {
          _errorMessage =
              'Erreur Firestore: L\'index requis est en cours de construction ou n\'est pas configuré. '
              'Vérifiez la console Firebase pour l\'état de l\'index (compte_id asc, date_creation desc).';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_errorMessage ?? 'Une erreur inattendue est survenue.')),
      );
    }
  }

  // Method to update search text and trigger filtering and sorting
  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      _filterAndSortTransactions(); // Re-filter and re-sort when search text changes
    });
  }

  // New method to combine filtering and sorting logic
  void _filterAndSortTransactions() {
    // 1. Apply search filter
    List<Transactions> tempTransactions;
    if (_searchText.isEmpty) {
      tempTransactions = List.from(_allTransactions);
    } else {
      tempTransactions = _allTransactions.where((transaction) {
        final query = _searchText;

        // Convert all relevant fields to lowercase for case-insensitive search
        final transactionId = transaction.transaction_id.toLowerCase();
        final compteId = transaction.compte_id.toLowerCase();
        final amount = transaction.amount.toString().toLowerCase();
        final status = transaction.status.toLowerCase();
        final type = transaction.type.toLowerCase();
        final dateCreation = DateFormat('dd/MM/yyyy HH:mm')
            .format(transaction.date_creation)
            .toLowerCase();
        final adminApproverId =
            transaction.admin_approver_id?.toLowerCase() ?? '';
        final notes = transaction.notes?.toLowerCase() ?? '';

        return transactionId.contains(query) ||
            compteId.contains(query) ||
            amount.contains(query) ||
            status.contains(query) ||
            type.contains(query) ||
            dateCreation.contains(query) ||
            adminApproverId.contains(query) ||
            notes.contains(query);
      }).toList();
    }

    // 2. Apply sorting
    if (_currentSortOption != TransactionSortOption.none) {
      tempTransactions.sort((a, b) {
        int comparison = 0;
        switch (_currentSortOption) {
          case TransactionSortOption.dateCreation:
            // Compare dates. Latest date is "greater" for descending.
            comparison = a.date_creation.compareTo(b.date_creation);
            break;
          case TransactionSortOption.amount:
            // Compare amounts. Higher amount is "greater".
            comparison = a.amount.compareTo(b.amount);
            break;
          case TransactionSortOption.type:
            // Compare types alphabetically.
            comparison = a.type.toLowerCase().compareTo(b.type.toLowerCase());
            break;
          case TransactionSortOption.status:
            // Compare statuses alphabetically.
            comparison =
                a.status.toLowerCase().compareTo(b.status.toLowerCase());
            break;
          case TransactionSortOption.none:
            // Should not happen due to if condition, but handled for completeness
            comparison = 0;
            break;
        }
        // Apply descending order if needed
        return _isSortDescending ? -comparison : comparison;
      });
    }

    _filteredTransactions = tempTransactions;
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

  Future<List<Transactions>> _fetchTransactions() async {
    // This method remains focused on fetching data from Firestore.
    // Sorting logic will be handled client-side in _filterAndSortTransactions.
    if (user == null) {
      print('DEBUG: No user logged in. Cannot fetch user-specific accounts.');
      return []; // Return empty list if no user
    }

    print('DEBUG: User logged in with UID: ${user!.uid}');

    try {
      // Fetch all accounts owned by the current user
      final comptesSnapshot = await FirebaseFirestore.instance
          .collection('compte')
          .where('owner_uid', isEqualTo: user!.uid)
          .get();

      final List<String> userCompteIds = [];
      for (var doc in comptesSnapshot.docs) {
        userCompteIds.add(doc.id);
      }

      print('DEBUG: Number of user accounts found: ${userCompteIds.length}');
      print('DEBUG: Found user account IDs: $userCompteIds');

      if (userCompteIds.isEmpty) {
        return []; // No accounts for this user, so no transactions to fetch
      }

      List<Transactions> allTransactions = [];
      const int chunkSize = 10; // Firestore `whereIn` limit is 10
      for (int i = 0; i < userCompteIds.length; i += chunkSize) {
        final chunk = userCompteIds.sublist(
            i,
            (i + chunkSize > userCompteIds.length)
                ? userCompteIds.length
                : i + chunkSize);

        print('DEBUG: Fetching transactions for account ID chunk: $chunk');

        // Fetch transactions where 'compte_id' is in the current chunk.
        // Sorting here is for initial Firestore retrieval, client-side sorting will override.
        final transactionsSnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('compte_id', whereIn: chunk)
            // It's good practice to have an initial order for consistency,
            // but client-side sorting will handle user's preference.
            .orderBy('date_creation', descending: true)
            .get();

        print(
            'DEBUG: Found ${transactionsSnapshot.docs.length} transactions in this chunk.');

        allTransactions.addAll(transactionsSnapshot.docs.map((doc) {
          final data = doc.data();
          return Transactions.fromJson(doc.id, data);
        }).toList());
      }
      return allTransactions;
    } on FirebaseException catch (e) {
      print(
          'Firebase Error fetching transactions in _fetchTransactions: ${e.code} - ${e.message}');
      rethrow; // Re-throw to be caught by _fetchTransactionsAndSetState
    } catch (e) {
      print('General Error fetching transactions in _fetchTransactions: $e');
      rethrow; // Re-throw to be caught by _fetchTransactionsAndSetState
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final errorColor = Theme.of(context).colorScheme.error;

    if (user == null &&
        !_isLoading &&
        _allTransactions.isEmpty &&
        _errorMessage == null) {
      return Scaffold(
        // Removed AppBar
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
                  'Veuillez vous connecter pour voir vos transactions.',
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
      // Removed AppBar
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // Padding around the top card
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Theme.of(context).colorScheme.surface,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child: Icon(Icons.receipt_long, color: primaryColor),
                ),
                title: Text(
                  'Mes Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                ),
                subtitle: Text(
                  'Historique complet de vos transactions.',
                  style: TextStyle(
                    color: onSurfaceColor.withOpacity(0.7),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sort Options Dropdown
                    PopupMenuButton<TransactionSortOption>(
                      onSelected: (TransactionSortOption result) {
                        if (result == _currentSortOption) {
                          // If the same option is selected, toggle descending order
                          setState(() {
                            _isSortDescending = !_isSortDescending;
                            _filterAndSortTransactions();
                          });
                        } else {
                          // If a new option is selected, set it and default to descending (e.g., latest date, highest amount)
                          setState(() {
                            _currentSortOption = result;
                            _isSortDescending = (_currentSortOption ==
                                    TransactionSortOption.dateCreation ||
                                _currentSortOption ==
                                    TransactionSortOption
                                        .amount); // Default for date/amount
                            _filterAndSortTransactions();
                          });
                        }
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
                          _filterAndSortTransactions();
                        });
                      },
                      tooltip: _isSortDescending
                          ? 'Ordre décroissant'
                          : 'Ordre croissant',
                    ),
                  ],
                ),
              ),
            ),
          ),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 80, color: errorColor),
                              const SizedBox(height: 20),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: errorColor),
                              ),
                              const SizedBox(height: 10),
                              if (_errorMessage!.contains('index'))
                                Text(
                                  'Veuillez vérifier l\'onglet "Index" dans votre console Firebase pour le projet rca-demo-db. Assurez-vous que l\'index composite (compte_id asc, date_creation desc) est "Activé".',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              TextButton.icon(
                                onPressed: _fetchTransactionsAndSetState,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _allTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.money_off,
                                    size: 80,
                                    color: primaryColor.withOpacity(0.6)),
                                const SizedBox(height: 20),
                                Text(
                                  'Aucune transaction trouvée pour vos comptes.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: primaryColor),
                                ),
                              ],
                            ),
                          )
                        : _filteredTransactions.isEmpty &&
                                _searchText.isNotEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 80,
                                        color: onSurfaceColor.withOpacity(0.6)),
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
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                itemCount: _filteredTransactions.length,
                                itemBuilder: (context, index) {
                                  final transaction =
                                      _filteredTransactions[index];

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
                                    case 'dépôt': // Assuming 'Dépôt' might be a type
                                      transactionColor = Colors.blue;
                                      transactionIcon =
                                          Icons.account_balance_wallet;
                                      break;
                                    case 'retrait': // Assuming 'Retrait' might be a type
                                      transactionColor = Colors.purple;
                                      transactionIcon = Icons.credit_card_off;
                                      break;
                                    default:
                                      transactionColor =
                                          onSurfaceColor.withOpacity(0.7);
                                      transactionIcon = Icons.swap_horiz;
                                  }

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            transactionColor.withOpacity(0.2),
                                        child: Icon(transactionIcon,
                                            color: transactionColor),
                                      ),
                                      title: Text(
                                        '${transaction.type} : ${transaction.amount.toStringAsFixed(2)} TND',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: transactionColor,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID Transaction: ${transaction.transaction_id}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.0)),
                                          ),
                                          Text(
                                            'Compte ID: ${transaction.compte_id}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.8)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2.0),
                                            child: Text(
                                              'Statut: ${transaction.status}',
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                    transaction.status,
                                                    context),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.date_creation)}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.7)),
                                          ),
                                          if (transaction.notes != null &&
                                              transaction.notes!.isNotEmpty)
                                            Text(
                                              'Notes: ${transaction.notes}',
                                              style: TextStyle(
                                                  color: onSurfaceColor
                                                      .withOpacity(0.7)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                      trailing: Icon(Icons.arrow_forward_ios,
                                          color:
                                              onSurfaceColor.withOpacity(0.5),
                                          size: 16),
                                      onTap: () {
                                        // Navigate to the new UserTransactionDetailView
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                UserTransactionDetailView(
                                                    transaction: transaction),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}
