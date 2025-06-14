// lib/views/admin/admin_manage_commissions.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import your Commissions model only
import 'package:reseaux_commission_app/models/commissions.dart';

// Import the detail page
import 'package:reseaux_commission_app/views/admin/admin_commission_detail_page.dart'; // Will create this next

class AdminManageCommissions extends StatefulWidget {
  const AdminManageCommissions({super.key});

  @override
  State<AdminManageCommissions> createState() => _AdminManageCommissionsState();
}

class _AdminManageCommissionsState extends State<AdminManageCommissions> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Commissions> _allCommissions = [];
  List<Commissions> _filteredCommissions = [];

  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();

  // Sorting options
  String _sortColumn = 'date_earned'; // Default sort
  bool _sortAscending = false; // Default: descending for date

  @override
  void initState() {
    super.initState();
    _fetchCommissions();
    _searchController.addListener(_filterCommissions);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCommissions);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final commissionSnapshot =
          await _firestore.collection('commissions').get();
      List<Commissions> fetchedCommissions = [];

      for (var doc in commissionSnapshot.docs) {
        if (doc.data().isNotEmpty) {
          try {
            final commission = Commissions.fromJson(
                doc.id, doc.data() as Map<String, dynamic>);
            fetchedCommissions.add(commission);
          } catch (e) {
            print(
                'ERROR: Failed to parse Commission document ID: ${doc.id}, Error: $e, Data: ${doc.data()}');
            // Log the error but continue processing other documents
          }
        } else {
          print('WARNING: Skipping empty Commission document ID: ${doc.id}');
        }
      }

      setState(() {
        _allCommissions = fetchedCommissions;
        _filterCommissions(); // Apply initial filter and sort
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des commissions: ${e.message}';
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

  void _filterCommissions() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCommissions = _allCommissions.where((commission) {
        // Search by Commission fields only
        if (commission.commissions_id.toLowerCase().contains(query))
          return true;
        if (commission.from_compte_id.toLowerCase().contains(query))
          return true;
        if (commission.to_compte_id.toLowerCase().contains(query)) return true;
        if (commission.owner_uid.toLowerCase().contains(query)) return true;
        if (commission.amount.toStringAsFixed(2).contains(query)) return true;
        if (commission.transaction_id.toLowerCase().contains(query))
          return true;
        if (commission.status.toLowerCase().contains(query)) return true;
        if (DateFormat('dd/MM/yyyy HH:mm')
            .format(commission.date_earned)
            .toLowerCase()
            .contains(query)) return true;
        if (commission.stage.toString().contains(query)) return true;

        return false;
      }).toList();
      _sortCommissions(); // Re-apply sort after filtering
    });
  }

  void _sortCommissions() {
    _filteredCommissions.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'date_earned':
          comparison = a.date_earned.compareTo(b.date_earned);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'stage':
          comparison = a.stage.compareTo(b.stage);
          break;
        case 'to_compte_id':
          comparison = a.to_compte_id.compareTo(b.to_compte_id);
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
            (column == 'date_earned' || column == 'amount') ? false : true;
      }
      _sortCommissions();
    });
  }

  Future<void> _viewCommissionDetails(Commissions commission) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCommissionDetailPage(commission: commission),
      ),
    );

    if (result == true) {
      _fetchCommissions(); // Refresh the list if commission status was updated
    }
  }

  // Helper for status icon
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

  // Helper for status color
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

  // Helper for building detail rows (can be shared utility if needed elsewhere)
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
                          onPressed: _fetchCommissions,
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
                                  Icons.trending_up, // Icon for commissions
                                  size: 40,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Gérer les Commissions',
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
                                    'Rechercher par ID, compte ID, montant, statut, etc...',
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
                              'Total: ${_filteredCommissions.length} commissions'),
                          PopupMenuButton<String>(
                            onSelected: _onSort,
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'date_earned',
                                child: Text('Trier par Date Gagnée'),
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
                                value: 'stage',
                                child: Text('Trier par Niveau'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'to_compte_id',
                                child: Text('Trier par Compte Bénéficiaire'),
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
                      child: _filteredCommissions.isEmpty
                          ? Center(
                              child: Text(
                                'Aucune commission trouvée.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredCommissions.length,
                              itemBuilder: (context, index) {
                                final commission = _filteredCommissions[index];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  elevation: 1,
                                  child: ExpansionTile(
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          _getStatusColor(commission.status),
                                      child: Icon(
                                          _getStatusIcon(commission.status),
                                          color: Colors.white,
                                          size: 20),
                                    ),
                                    title: Text(
                                      'Commission ID: ${commission.commissions_id}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    subtitle: Text(
                                        'Montant: ${commission.amount.toStringAsFixed(2)} TND | Statut: ${commission.status}\nVers Compte: ${commission.to_compte_id} (Niveau ${commission.stage})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.visibility,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _viewCommissionDetails(commission),
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
                                                'Date Gagnée:',
                                                DateFormat('dd/MM/yyyy HH:mm')
                                                    .format(commission
                                                        .date_earned)),
                                            _buildDetailRow(
                                                'Transaction Source ID:',
                                                commission.transaction_id),
                                            _buildDetailRow('Pourcentage:',
                                                '${commission.commission_percentage.toStringAsFixed(2)}%'),
                                            _buildDetailRow(
                                                'Propriétaire (UID):',
                                                commission.owner_uid),
                                            _buildDetailRow('From Compte ID:',
                                                commission.from_compte_id),
                                            _buildDetailRow('To Compte ID:',
                                                commission.to_compte_id),
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
}
