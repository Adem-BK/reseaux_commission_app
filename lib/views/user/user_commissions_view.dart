// lib/views/user/user_commissions_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reseaux_commission_app/models/commissions.dart';
import 'package:intl/intl.dart';

// Enum to define sorting options for commissions
enum CommissionSortOption {
  dateEarned,
  amount,
  commissionPercentage,
  status,
  stage,
  none, // Represents no specific sorting, reverts to default fetch order
}

class UserCommissionsView extends StatefulWidget {
  const UserCommissionsView({super.key});

  @override
  State<UserCommissionsView> createState() => _UserCommissionsViewState();
}

class _UserCommissionsViewState extends State<UserCommissionsView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = ''; // State variable to hold the current search query
  List<Commissions> _allCommissions = []; // Holds all fetched commissions
  List<Commissions> _filteredCommissions =
      []; // Holds commissions after search filter

  bool _isLoading = true; // Added loading state
  String? _errorMessage; // To display specific error messages

  // State variables for sorting
  CommissionSortOption _currentSortOption = CommissionSortOption.dateEarned;
  bool _isSortDescending =
      true; // Default to descending for date (latest first)

  @override
  void initState() {
    super.initState();
    _fetchCommissionsAndSetState(); // Call a dedicated method to fetch and set state
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Method to fetch commissions and update state
  Future<void> _fetchCommissionsAndSetState() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // No error message here, as it's handled by the specific UI below
        });
      }
      return; // Exit if no user is logged in
    }

    try {
      final commissionsSnapshot = await FirebaseFirestore.instance
          .collection('commissions')
          .where('owner_uid', isEqualTo: currentUser.uid)
          .orderBy('date_earned',
              descending: true) // Initial order from Firestore
          .get();

      if (!mounted) return;

      final List<Commissions> fetchedCommissions =
          commissionsSnapshot.docs.map((doc) {
        return Commissions.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      setState(() {
        _allCommissions = fetchedCommissions;
        _filterAndSortCommissions(); // Apply initial filter and sort
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      print('Firebase Error fetching commissions: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Erreur lors du chargement des commissions: ${e.message}';
          if (e.code == 'failed-precondition') {
            _errorMessage =
                'Erreur Firestore: L\'index requis est en cours de construction ou n\'est pas configuré. Veuillez vérifier la console Firebase pour l\'état de l\'index.';
          }
        });
      }
    } catch (e) {
      print('General Error fetching commissions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Une erreur inattendue est survenue: $e';
        });
      }
    }
  }

  // Method to update search text and trigger filtering and sorting
  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchText = _searchController.text.toLowerCase();
      _filterAndSortCommissions(); // Re-filter and re-sort when search text changes
    });
  }

  // New method to combine filtering and sorting logic
  void _filterAndSortCommissions() {
    // 1. Apply search filter
    List<Commissions> tempCommissions;
    if (_searchText.isEmpty) {
      tempCommissions = List.from(_allCommissions);
    } else {
      tempCommissions = _allCommissions.where((commission) {
        final query = _searchText;

        // Convert all relevant fields to lowercase for case-insensitive search
        final commissionId = commission.commissions_id.toLowerCase();
        final fromCompteId = commission.from_compte_id.toLowerCase();
        final toCompteId = commission.to_compte_id.toLowerCase();
        final ownerUid = commission.owner_uid.toLowerCase();
        final transactionId = commission.transaction_id.toLowerCase();
        final amount = commission.amount.toString().toLowerCase();
        final percentage =
            commission.commission_percentage.toString().toLowerCase();
        final status = commission.status.toLowerCase();
        final stage = commission.stage.toString().toLowerCase();
        final dateEarned = DateFormat('dd/MM/yyyy HH:mm')
            .format(commission.date_earned)
            .toLowerCase();

        return commissionId.contains(query) ||
            fromCompteId.contains(query) ||
            toCompteId.contains(query) ||
            ownerUid.contains(query) ||
            transactionId.contains(query) ||
            amount.contains(query) ||
            percentage.contains(query) ||
            status.contains(query) ||
            stage.contains(query) ||
            dateEarned.contains(query);
      }).toList();
    }

    // 2. Apply sorting
    if (_currentSortOption != CommissionSortOption.none) {
      tempCommissions.sort((a, b) {
        int comparison = 0;
        switch (_currentSortOption) {
          case CommissionSortOption.dateEarned:
            comparison = a.date_earned.compareTo(b.date_earned);
            break;
          case CommissionSortOption.amount:
            comparison = a.amount.compareTo(b.amount);
            break;
          case CommissionSortOption.commissionPercentage:
            comparison =
                a.commission_percentage.compareTo(b.commission_percentage);
            break;
          case CommissionSortOption.status:
            comparison =
                a.status.toLowerCase().compareTo(b.status.toLowerCase());
            break;
          case CommissionSortOption.stage:
            comparison = a.stage.compareTo(b.stage);
            break;
          case CommissionSortOption.none:
            comparison = 0; // Should not be reached
            break;
        }
        // Apply descending order if needed
        return _isSortDescending ? -comparison : comparison;
      });
    }

    _filteredCommissions = tempCommissions;
  }

  // Helper method to determine the color for commission status
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

  // Helper method to determine the icon for commission status
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final errorColor = Theme.of(context).colorScheme.error;
    final currentUser = _auth.currentUser;

    // Handle not logged in state
    if (currentUser == null) {
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
                  'Veuillez vous connecter pour voir vos commissions.',
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
                  child: Icon(Icons.currency_exchange,
                      color: primaryColor), // Commission icon
                ),
                title: Text(
                  'Mes Commissions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                ),
                subtitle: Text(
                  'Historique complet de vos commissions gagnées.',
                  style: TextStyle(
                    color: onSurfaceColor.withOpacity(0.7),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sort Options Dropdown
                    PopupMenuButton<CommissionSortOption>(
                      onSelected: (CommissionSortOption result) {
                        if (result == _currentSortOption) {
                          // If the same option is selected, toggle descending order
                          setState(() {
                            _isSortDescending = !_isSortDescending;
                            _filterAndSortCommissions();
                          });
                        } else {
                          // If a new option is selected, set it and default to descending
                          setState(() {
                            _currentSortOption = result;
                            _isSortDescending = (_currentSortOption ==
                                    CommissionSortOption.dateEarned ||
                                _currentSortOption ==
                                    CommissionSortOption.amount ||
                                _currentSortOption ==
                                    CommissionSortOption.commissionPercentage ||
                                _currentSortOption ==
                                    CommissionSortOption
                                        .stage); // Default for numeric/date fields
                            _filterAndSortCommissions();
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<CommissionSortOption>>[
                        const PopupMenuItem<CommissionSortOption>(
                          value: CommissionSortOption.dateEarned,
                          child: Text('Date Gagnée'),
                        ),
                        const PopupMenuItem<CommissionSortOption>(
                          value: CommissionSortOption.amount,
                          child: Text('Montant'),
                        ),
                        const PopupMenuItem<CommissionSortOption>(
                          value: CommissionSortOption.commissionPercentage,
                          child: Text('Pourcentage'),
                        ),
                        const PopupMenuItem<CommissionSortOption>(
                          value: CommissionSortOption.status,
                          child: Text('Statut'),
                        ),
                        const PopupMenuItem<CommissionSortOption>(
                          value: CommissionSortOption.stage,
                          child: Text('Niveau'),
                        ),
                        const PopupMenuItem<CommissionSortOption>(
                          value: CommissionSortOption.none,
                          child: Text('Défaut (Date descendante)'),
                        ),
                      ],
                      icon: Icon(Icons.sort,
                          color: Theme.of(context)
                                  .appBarTheme
                                  .actionsIconTheme
                                  ?.color ??
                              onSurfaceColor),
                      tooltip: 'Trier les commissions',
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
                          _filterAndSortCommissions();
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
                hintText: 'Rechercher une commission...',
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
                              // Specific message for Firestore index error
                              if (_errorMessage!.contains('index') ||
                                  _errorMessage!.contains('Firestore'))
                                Text(
                                  'Veuillez vérifier l\'onglet "Index" dans votre console Firebase pour le projet rca-demo-db. Assurez-vous que l\'index composite (owner_uid asc, date_earned desc) est "Activé".',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              TextButton.icon(
                                onPressed: _fetchCommissionsAndSetState,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _allCommissions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.money_off,
                                    size: 80,
                                    color: primaryColor.withOpacity(0.6)),
                                const SizedBox(height: 20),
                                Text(
                                  'Aucune commission trouvée.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: primaryColor),
                                ),
                              ],
                            ),
                          )
                        : _filteredCommissions.isEmpty && _searchText.isNotEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 80,
                                        color: onSurfaceColor.withOpacity(0.6)),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Aucune commission trouvée pour la recherche "$_searchController.text".',
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
                                itemCount: _filteredCommissions.length,
                                itemBuilder: (context, index) {
                                  final commission =
                                      _filteredCommissions[index];

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            _getStatusColor(commission.status)
                                                .withOpacity(0.2),
                                        child: Icon(
                                            _getStatusIcon(commission.status),
                                            color: _getStatusColor(
                                                commission.status)),
                                      ),
                                      title: Text(
                                        '${commission.amount.toStringAsFixed(2)} TND',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                              commission.status),
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID Commission: ${commission.commissions_id}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.8)),
                                          ),
                                          Text(
                                            'Pourcentage: ${commission.commission_percentage.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.8)),
                                          ),
                                          Text(
                                            'Niveau: ${commission.stage}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.8)),
                                          ),
                                          Text(
                                            'De: ${commission.from_compte_id}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.8)),
                                          ),
                                          Text(
                                            'À: ${commission.to_compte_id}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.8)),
                                          ),
                                          Text(
                                            'Transaction ID: ${commission.transaction_id}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.8)),
                                          ),
                                          Text(
                                            'Statut: ${commission.status}',
                                            style: TextStyle(
                                                color: _getStatusColor(
                                                    commission.status),
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Date Gagnée: ${DateFormat('dd/MM/yyyy HH:mm').format(commission.date_earned)}',
                                            style: TextStyle(
                                                color: onSurfaceColor
                                                    .withOpacity(0.7)),
                                          ),
                                        ],
                                      ),
                                      // Removed trailing arrow as there is no detail view specified yet for commissions
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
