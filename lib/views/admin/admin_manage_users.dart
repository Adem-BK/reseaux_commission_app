// lib/views/admin/admin_manage_users.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Just in case for future date displays

// Import models
import 'package:reseaux_commission_app/models/users.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/views/shared/modals/admin_add_edit_user.dart'; // To delete associated accounts

// Import the new modal

class AdminManageUsers extends StatefulWidget {
  const AdminManageUsers({super.key});

  @override
  State<AdminManageUsers> createState() => _AdminManageUsersState();
}

class _AdminManageUsersState extends State<AdminManageUsers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Users> _allUsers = [];
  List<Users> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();

  // Sorting options
  String _sortColumn = 'nom'; // Default sort
  bool _sortAscending = true; // Default: ascending for names

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final querySnapshot = await _firestore.collection('users').get();
      List<Users> fetchedUsers = [];
      for (var doc in querySnapshot.docs) {
        if (doc.data().isNotEmpty) {
          try {
            // Using Users.fromJson which expects 'id' to be in doc.data()
            fetchedUsers
                .add(Users.fromJson(doc.data() as Map<String, dynamic>));
          } catch (e) {
            print(
                'ERROR: Failed to parse User document ID: ${doc.id}, Error: $e, Data: ${doc.data()}');
            // It's possible that the 'id' field is missing in some old documents,
            // or the data format is unexpected. Log it.
          }
        } else {
          print('WARNING: Skipping empty User document ID: ${doc.id}');
        }
      }

      setState(() {
        _allUsers = fetchedUsers;
        _filterUsers(); // Apply initial filter and sort
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des utilisateurs: ${e.message}';
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

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        // Search by relevant fields
        if (user.nom.toLowerCase().contains(query)) return true;
        if (user.prenom.toLowerCase().contains(query)) return true;
        if (user.email.toLowerCase().contains(query)) return true;
        if (user.tel.toLowerCase().contains(query)) return true;
        if (user.role.toLowerCase().contains(query)) return true;
        if (user.id.toLowerCase().contains(query))
          return true; // Now checking user.id directly
        return false;
      }).toList();
      _sortUsers(); // Re-apply sort after filtering
    });
  }

  void _sortUsers() {
    _filteredUsers.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'nom':
          comparison = a.nom.compareTo(b.nom);
          break;
        case 'prenom':
          comparison = a.prenom.compareTo(b.prenom);
          break;
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'role':
          comparison = a.role.compareTo(b.role);
          break;
        case 'tel':
          comparison = a.tel.compareTo(b.tel);
          break;
        case 'id':
          comparison = a.id.compareTo(b.id); // Sorting by the 'id' field
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
        _sortAscending = true; // Default ascending for most user fields
      }
      _sortUsers();
    });
  }

  Future<void> _addOrEditUser({Users? user}) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AdminAddEditUserModal(user: user),
    );

    if (result == true) {
      _fetchUsers(); // Refresh the list if user was successfully added/modified
    }
  }

  Future<void> _deleteUser(Users userToDelete) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer l\'utilisateur ${userToDelete.prenom} ${userToDelete.nom} (ID: ${userToDelete.id}) ?\n\n'
              'ATTENTION: Tous les comptes associés à cet utilisateur seront également supprimés. Les transactions resteront pour la traçabilité.'),
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
        // Start a batch write operation
        WriteBatch batch = _firestore.batch();

        // 1. Find and delete all accounts associated with this user
        // Assuming 'owner_uid' in 'compte' collection stores the 'id' of the user document.
        final comptesSnapshot = await _firestore
            .collection('compte')
            .where('owner_uid', isEqualTo: userToDelete.id)
            .get();
        if (comptesSnapshot.docs.isNotEmpty) {
          for (var doc in comptesSnapshot.docs) {
            batch.delete(doc.reference);
            print(
                'Batching deletion of account: ${doc.id} for user ID: ${userToDelete.id}');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${comptesSnapshot.docs.length} comptes associés seront supprimés...')),
          );
        }

        // 2. Delete the user document itself.
        // Assuming the document ID in Firestore for the user is the same as userToDelete.id
        batch.delete(_firestore.collection('users').doc(userToDelete.id));
        print('Batching deletion of user document with ID: ${userToDelete.id}');

        // 3. Commit the batch
        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Utilisateur et comptes associés supprimés avec succès!')),
        );
        _fetchUsers(); // Refresh the list
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erreur Firebase lors de la suppression: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur inattendue lors de la suppression: $e')),
        );
      }
    }
  }

  // New function to show full details of a User
  void _viewUserDetails(Users user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Détails de l\'Utilisateur: ${user.prenom} ${user.nom}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('ID:', user.id),
                _buildDetailRow('Nom:', user.nom),
                _buildDetailRow('Prénom:', user.prenom),
                _buildDetailRow('Email:', user.email),
                _buildDetailRow('Téléphone:', user.tel),
                _buildDetailRow('Rôle:', user.role),
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
                          onPressed: _fetchUsers,
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
                                  Icons.group, // Icon for the page (Users)
                                  size: 40,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Gérer les Utilisateurs',
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
                                    'Rechercher par nom, prénom, email, téléphone, rôle ou ID...',
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
                          Text('Total: ${_filteredUsers.length} utilisateurs'),
                          PopupMenuButton<String>(
                            onSelected: _onSort,
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'nom',
                                child: Text('Trier par Nom'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'prenom',
                                child: Text('Trier par Prénom'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'email',
                                child: Text('Trier par Email'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'role',
                                child: Text('Trier par Rôle'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'id',
                                child: Text('Trier par ID'),
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
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            elevation: 1,
                            child: ExpansionTile(
                              leading: const Icon(Icons.person,
                                  color: Colors.blueAccent),
                              title: Text('${user.prenom} ${user.nom}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(
                                  'Email: ${user.email}\nRôle: ${user.role}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility,
                                        color: Colors.green),
                                    onPressed: () => _viewUserDetails(user),
                                    tooltip: 'Voir les détails',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _addOrEditUser(user: user),
                                    tooltip: 'Modifier l\'utilisateur',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteUser(user),
                                    tooltip: 'Supprimer l\'utilisateur',
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
                                      _buildDetailRow('ID Complet:', user.id),
                                      _buildDetailRow('Téléphone:', user.tel),
                                      // You can add more user details here if needed
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
        onPressed: () => _addOrEditUser(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
