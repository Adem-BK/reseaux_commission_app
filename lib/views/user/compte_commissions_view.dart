// lib/views/user/compte_commisions_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/models/commissions.dart';
import 'package:reseaux_commission_app/models/transactions.dart'; // Import Transactions model
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async'; // Required for StreamSubscription

class CompteCommissionsView extends StatefulWidget {
  final Compte
      compte; // The specific Compte whose commissions we want to display

  const CompteCommissionsView({super.key, required this.compte});

  @override
  State<CompteCommissionsView> createState() => _CompteCommissionsViewState();
}

class _CompteCommissionsViewState extends State<CompteCommissionsView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Add Firestore instance

  late Compte
      _currentCompte; // Mutable copy of the account for real-time updates
  StreamSubscription<DocumentSnapshot>? _compteSubscription;

  // Search and Sort variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortCriteria = 'date_earned'; // Default sort criteria
  bool _sortAscending = false; // Default sort order (latest first)

  @override
  void initState() {
    super.initState();
    _currentCompte = widget.compte; // Initialize with the passed account
    _listenToCompteChanges(); // Listen for real-time updates to _currentCompte

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _compteSubscription
        ?.cancel(); // Cancel subscription to prevent memory leaks
    _searchController.dispose();
    super.dispose();
  }

  void _listenToCompteChanges() {
    _compteSubscription?.cancel(); // Cancel any existing subscription
    _compteSubscription = _firestore
        .collection('compte')
        .doc(_currentCompte.num_cpt)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          _currentCompte = Compte.fromJson(snapshot.id, snapshot.data()!);
        });
      }
    }, onError: (error) {
      print("Error listening to compte changes: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de mise à jour du compte: $error')),
        );
      }
    });
  }

  void _showAcceptReferralModal(BuildContext context) {
    String? recruiterCode;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Accepter une Parrainage'),
          content: TextField(
            onChanged: (value) {
              recruiterCode = value;
            },
            decoration: const InputDecoration(
              hintText: 'Entrez le code de parrainage',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Accepter'),
              onPressed: () async {
                if (recruiterCode != null && recruiterCode!.isNotEmpty) {
                  await _acceptReferral(context, recruiterCode!);
                  if (mounted) Navigator.of(dialogContext).pop();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez entrer un code.')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptReferral(
      BuildContext context, String newRecruiterId) async {
    // Basic validation: Cannot recruit self
    if (newRecruiterId == _currentCompte.num_cpt) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vous ne pouvez pas vous parrainer vous-même.')),
        );
      }
      return;
    }

    if (_currentCompte.recruiter_id != null &&
        _currentCompte.recruiter_id!.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Ce compte est déjà parrainé. Vous ne pouvez pas changer de parrain.')),
        );
      }
      return;
    }

    DocumentSnapshot recruiterDoc;
    try {
      recruiterDoc =
          await _firestore.collection('compte').doc(newRecruiterId).get();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erreur de connexion lors de la recherche du recruteur: $e')),
        );
      }
      return;
    }

    if (!recruiterDoc.exists || recruiterDoc.data() == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Code de parrainage invalide ou compte du recruteur inexistant.')),
        );
      }
      return;
    }

    // Get recruiter's stage
    final recruiterData = recruiterDoc.data() as Map<String, dynamic>;
    final int recruiterStage = (recruiterData['stage'] as num?)?.toInt() ?? 0;

    // Calculate new stage for the recruited account (widget.compte here refers to _currentCompte now)
    // If recruiter is stage N, recruited is N+1. Max stage is 4.
    final int newRecruitedStage = (recruiterStage < 4) ? recruiterStage + 1 : 4;

    try {
      await _firestore.collection('compte').doc(_currentCompte.num_cpt).update({
        'recruiter_id': newRecruiterId,
        'stage': newRecruitedStage,
      });

      // The _listenToCompteChanges stream will automatically update _currentCompte and trigger setState.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Vous avez accepté le parrainage de $newRecruiterId! Votre nouveau niveau est $newRecruitedStage.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de l\'acceptation du parrainage: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
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
    final bool canManageReferral =
        _auth.currentUser?.uid == _currentCompte.owner_uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commissions pour ${_currentCompte.num_cpt}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              if (canManageReferral) ...[
                Card(
                  elevation: 2,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Votre Code de Parrainage:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _currentCompte
                              .num_cpt, // Using num_cpt as referral code
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Share.share(
                                    'Mon code de parrainage est: ${_currentCompte.num_cpt}. Rejoignez-moi sur l\'application!');
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Partager Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            if (_currentCompte.recruiter_id == null ||
                                _currentCompte.recruiter_id!.isEmpty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showAcceptReferralModal(context);
                                },
                                icon: const Icon(Icons.link),
                                label: const Text('Accepter Parrainage'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.tertiary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            else
                              Text(
                                'Parrainé par: ${_currentCompte.recruiter_id} (Niveau ${_currentCompte.stage})', // Displaying recruiter_id and Compte.stage
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(), // Separator below referral section
              ],
            ],
          ),
        ),
        // Search and Sort UI
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher des commissions',
              hintText: 'Rechercher par ID transaction, ID compte, statut...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortCriteria,
                  decoration: InputDecoration(
                    labelText: 'Trier par',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'date_earned', child: Text('Date gagnée')),
                    DropdownMenuItem(value: 'amount', child: Text('Montant')),
                    DropdownMenuItem(value: 'status', child: Text('Statut')),
                    DropdownMenuItem(value: 'stage', child: Text('Niveau')),
                    DropdownMenuItem(
                        value: 'from_compte_id', child: Text('De Compte ID')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortCriteria = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
                ),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('commissions')
                .where('to_compte_id', isEqualTo: _currentCompte.num_cpt)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Aucune commission trouvée pour ce compte.'),
                );
              }

              List<Commissions> commissions = snapshot.data!.docs.map((doc) {
                return Commissions.fromJson(
                    doc.id, doc.data() as Map<String, dynamic>);
              }).toList();

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                commissions = commissions.where((commission) {
                  final query = _searchQuery.toLowerCase();
                  return commission.transaction_id
                          .toLowerCase()
                          .contains(query) ||
                      commission.from_compte_id.toLowerCase().contains(query) ||
                      commission.status.toLowerCase().contains(query) ||
                      commission.amount.toStringAsFixed(2).contains(query);
                }).toList();
              }

              // Apply sort
              commissions.sort((a, b) {
                Comparable aValue;
                Comparable bValue;

                switch (_sortCriteria) {
                  case 'date_earned':
                    aValue = a.date_earned;
                    bValue = b.date_earned;
                    break;
                  case 'amount':
                    aValue = a.amount;
                    bValue = b.amount;
                    break;
                  case 'status':
                    aValue = a.status;
                    bValue = b.status;
                    break;
                  case 'stage':
                    aValue = a.stage;
                    bValue = b.stage;
                    break;
                  case 'from_compte_id':
                    aValue = a.from_compte_id;
                    bValue = b.from_compte_id;
                    break;
                  default:
                    aValue = a.date_earned;
                    bValue = b.date_earned;
                }

                return _sortAscending
                    ? aValue.compareTo(bValue)
                    : bValue.compareTo(aValue);
              });

              if (commissions.isEmpty) {
                return const Center(
                    child: Text(
                        'Aucune commission ne correspond à votre recherche.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: commissions.length,
                itemBuilder: (context, index) {
                  final commission = commissions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(commission.status),
                        child: Icon(_getStatusIcon(commission.status),
                            color: Colors.white),
                      ),
                      title: Text(
                        '${commission.amount.toStringAsFixed(2)} TND',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'De: ${commission.from_compte_id} (Niveau Commission: ${commission.stage})'), // Clarified commission stage
                          Text('ID Transaction: ${commission.transaction_id}'),
                          Text(
                              'Pourcentage: ${commission.commission_percentage.toStringAsFixed(2)}%'),
                          Text(
                            'Date: ${DateFormat('dd/MM/yyyy').format(commission.date_earned)}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          Text(
                            'Statut: ${commission.status}',
                            style: TextStyle(
                                color: _getStatusColor(commission.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
