// lib/views/admin/admin_manage_comptes.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

// Import the models
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/models/users.dart';
import 'package:reseaux_commission_app/views/shared/modals/admin_add_edit_compte.dart'; // Import Users model

// Wrapper class to hold Compte and its Owner's User data
class CompteWithOwner {
  final Compte compte;
  final Users?
      ownerUser; // Nullable in case user data is not found or malformed

  CompteWithOwner({required this.compte, this.ownerUser});
}

class AdminManageComptes extends StatefulWidget {
  const AdminManageComptes({super.key});

  @override
  State<AdminManageComptes> createState() => _AdminManageComptesState();
}

class _AdminManageComptesState extends State<AdminManageComptes> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CompteWithOwner> _allComptesWithOwners =
      []; // Now stores wrapper objects
  List<CompteWithOwner> _filteredComptesWithOwners =
      []; // Filtered wrapper objects

  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();

  // Sorting options
  String _sortColumn = 'date_creation'; // Default sort
  bool _sortAscending =
      false; // Default: descending for date, ascending for numbers/strings

  @override
  void initState() {
    super.initState();
    _fetchComptes();
    _searchController.addListener(_filterComptes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterComptes);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchComptes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final compteSnapshot = await _firestore.collection('compte').get();
      List<CompteWithOwner> fetchedComptesWithOwners = [];

      // A map to cache user data to avoid redundant fetches if multiple accounts belong to the same user
      Map<String, Users> usersCache = {};

      for (var doc in compteSnapshot.docs) {
        if (doc.data().isNotEmpty) {
          try {
            final compte =
                Compte.fromJson(doc.id, doc.data() as Map<String, dynamic>);
            Users? ownerUser;

            // Fetch owner's user data, using cache if available
            if (usersCache.containsKey(compte.owner_uid)) {
              ownerUser = usersCache[compte.owner_uid];
            } else {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(compte.owner_uid)
                  .get();
              if (userDoc.exists && userDoc.data() != null) {
                ownerUser = Users.fromJson(userDoc.data()!);
                usersCache[compte.owner_uid] = ownerUser; // Cache it
              } else {
                print(
                    'WARNING: User data not found for owner_uid: ${compte.owner_uid}');
                // ownerUser remains null if not found
              }
            }
            fetchedComptesWithOwners
                .add(CompteWithOwner(compte: compte, ownerUser: ownerUser));
          } catch (e) {
            print(
                'ERROR: Failed to parse Compte document ID: ${doc.id}, Error: $e, Data: ${doc.data()}');
            // Log the error but continue processing other documents
          }
        } else {
          print('WARNING: Skipping empty Compte document ID: ${doc.id}');
        }
      }

      setState(() {
        _allComptesWithOwners = fetchedComptesWithOwners;
        _filterComptes(); // Apply initial filter and sort
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des comptes: ${e.message}';
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

  void _filterComptes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredComptesWithOwners = _allComptesWithOwners.where((data) {
        final compte = data.compte;
        final ownerUser = data.ownerUser;

        // Search by Compte fields
        if (compte.num_cpt.toLowerCase().contains(query)) return true;
        if (compte.solde.toStringAsFixed(2).contains(query)) return true;
        if (DateFormat('dd/MM/yyyy HH:mm')
            .format(compte.date_creation)
            .toLowerCase()
            .contains(query)) return true;
        if (compte.stage.toString().contains(query)) return true;
        if (compte.recruiter_id != null &&
            compte.recruiter_id!.toLowerCase().contains(query)) return true;
        if (compte.agence.toLowerCase().contains(query)) return true;
        if (compte.owner_uid.toLowerCase().contains(query)) return true;

        // Search by Owner User fields (nom, prenom, email)
        if (ownerUser != null) {
          if (ownerUser.nom.toLowerCase().contains(query)) return true;
          if (ownerUser.prenom.toLowerCase().contains(query)) return true;
          if (ownerUser.email.toLowerCase().contains(query)) return true;
        }

        return false;
      }).toList();
      _sortComptes(); // Re-apply sort after filtering
    });
  }

  void _sortComptes() {
    _filteredComptesWithOwners.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'num_cpt':
          comparison = a.compte.num_cpt.compareTo(b.compte.num_cpt);
          break;
        case 'solde':
          comparison = a.compte.solde.compareTo(b.compte.solde);
          break;
        case 'date_creation':
          comparison = a.compte.date_creation.compareTo(b.compte.date_creation);
          break;
        case 'stage':
          comparison = a.compte.stage.compareTo(b.compte.stage);
          break;
        case 'agence':
          comparison = a.compte.agence.compareTo(b.compte.agence);
          break;
        case 'owner_uid': // Sort by owner UID (or by owner name if available)
          final ownerNameA = a.ownerUser != null
              ? '${a.ownerUser!.prenom} ${a.ownerUser!.nom}'
              : a.compte.owner_uid;
          final ownerNameB = b.ownerUser != null
              ? '${b.ownerUser!.prenom} ${b.ownerUser!.nom}'
              : b.compte.owner_uid;
          comparison = ownerNameA.compareTo(ownerNameB);
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
        // Default for date is descending, others ascending
        _sortAscending =
            (column == 'date_creation' || column == 'solde') ? false : true;
      }
      _sortComptes();
    });
  }

  // Modified to call the new modal
  Future<void> _addOrEditCompte({Compte? compte}) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AdminAddEditCompteModal(compte: compte),
    );

    if (result == true) {
      _fetchComptes(); // Refresh the list if an account was successfully added/modified
    }
  }

  // New function to show full details of a Compte
  void _viewCompteDetails(CompteWithOwner data) {
    final Compte compte = data.compte;
    final Users? ownerUser = data.ownerUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Détails du Compte: ${compte.num_cpt}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Numéro de Compte:', compte.num_cpt),
                _buildDetailRow(
                    'Solde:', '${compte.solde.toStringAsFixed(2)} TND'),
                _buildDetailRow(
                    'Date de Création:',
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(compte.date_creation)),
                _buildDetailRow('Niveau (Stage):', compte.stage.toString()),
                _buildDetailRow('ID Recruteur:', compte.recruiter_id ?? 'N/A'),
                _buildDetailRow('Agence:', compte.agence),
                _buildDetailRow('UID Propriétaire:', compte.owner_uid),
                const Divider(),
                Text(
                  'Détails du Propriétaire:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (ownerUser != null) ...[
                  _buildDetailRow(
                      'Nom Complet:', '${ownerUser.prenom} ${ownerUser.nom}'),
                  _buildDetailRow('Email:', ownerUser.email),
                  _buildDetailRow('Téléphone:', ownerUser.tel),
                  _buildDetailRow('Rôle:', ownerUser.role),
                ] else ...[
                  const Text('Informations sur le propriétaire non trouvées.',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
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

  Future<void> _deleteCompte(String numCpt) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content:
              Text('Êtes-vous sûr de vouloir supprimer le compte $numCpt ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestore.collection('compte').doc(numCpt).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé avec succès!')),
        );
        _fetchComptes(); // Refresh the list
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Firebase: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
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
                          onPressed: _fetchComptes,
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
                                  Icons
                                      .account_balance_wallet, // Icon for the page
                                  size: 40,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Gérer les Comptes',
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
                                    'Rechercher par numéro, solde, date, niveau, agence, UID ou nom du propriétaire...',
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
                              'Total: ${_filteredComptesWithOwners.length} comptes'),
                          PopupMenuButton<String>(
                            onSelected: _onSort,
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'num_cpt',
                                child: Text('Trier par Numéro de Compte'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'solde',
                                child: Text('Trier par Solde'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'date_creation',
                                child: Text('Trier par Date de Création'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'stage',
                                child: Text('Trier par Niveau (Stage)'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'agence',
                                child: Text('Trier par Agence'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'owner_uid',
                                child: Text(
                                    'Trier par Propriétaire'), // Changed text to reflect name sorting
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
                        itemCount: _filteredComptesWithOwners.length,
                        itemBuilder: (context, index) {
                          final data = _filteredComptesWithOwners[index];
                          final compte = data.compte;
                          final ownerUser = data.ownerUser;

                          String ownerName = ownerUser != null
                              ? '${ownerUser.prenom} ${ownerUser.nom}'
                              : 'UID: ${compte.owner_uid.length > 6 ? compte.owner_uid.substring(0, 6) + '...' : compte.owner_uid}';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            elevation: 1,
                            child: ExpansionTile(
                              leading: const Icon(Icons.account_balance_wallet,
                                  color: Colors.blueAccent),
                              title: Text('N° Compte: ${compte.num_cpt}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(
                                  'Solde: ${compte.solde.toStringAsFixed(2)} TND\nPropriétaire: $ownerName',
                                  style: Theme.of(context).textTheme.bodySmall),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility,
                                        color: Colors.green),
                                    onPressed: () => _viewCompteDetails(data),
                                    tooltip: 'Voir les détails',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _addOrEditCompte(
                                        compte:
                                            compte), // Call the _addOrEditCompte method
                                    tooltip: 'Modifier le compte',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteCompte(compte.num_cpt),
                                    tooltip: 'Supprimer le compte',
                                  ),
                                ],
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
                                          DateFormat('dd/MM/yyyy HH:mm')
                                              .format(compte.date_creation)),
                                      _buildDetailRow('Niveau (Stage):',
                                          compte.stage.toString()),
                                      _buildDetailRow('ID Recruteur:',
                                          compte.recruiter_id ?? 'N/A'),
                                      _buildDetailRow('Agence:', compte.agence),
                                      _buildDetailRow(
                                          'UID Propriétaire Complet:',
                                          compte.owner_uid),
                                      if (ownerUser != null) ...[
                                        const Divider(),
                                        Text(
                                          'Détails du Propriétaire (Expansion):',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        _buildDetailRow('Nom Complet:',
                                            '${ownerUser.prenom} ${ownerUser.nom}'),
                                        _buildDetailRow(
                                            'Email:', ownerUser.email),
                                        _buildDetailRow(
                                            'Téléphone:', ownerUser.tel),
                                        _buildDetailRow(
                                            'Rôle:', ownerUser.role),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCompte(), // Call the _addOrEditCompte method
        child: const Icon(Icons.add),
      ),
    );
  }
}
