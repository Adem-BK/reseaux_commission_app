// lib/views/user/user_compte.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/views/shared/modals/add_edit_compte.dart';
import 'package:reseaux_commission_app/views/user/single_comte_page.dart';
import 'package:reseaux_commission_app/widgets/compte_card.dart';
import 'package:reseaux_commission_app/widgets/add_compte_card.dart';

class UserComptePage extends StatefulWidget {
  const UserComptePage({super.key});

  @override
  State<UserComptePage> createState() => _UserComptePageState();
}

class _UserComptePageState extends State<UserComptePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1200) {
      crossAxisCount = 3;
      childAspectRatio = 1.9;
    } else if (screenWidth > 800) {
      crossAxisCount = 2;
      childAspectRatio = 1.6;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 1.5;
    }

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
                  'Veuillez vous connecter pour voir vos comptes.', // Corrected "compte" to "comptes"
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement navigation to your login page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please navigate to login page manually if not set up.')),
                    );
                  },
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // --- MODIFICATION HERE: Filter by owner_uid ---
                stream: FirebaseFirestore.instance
                    .collection('compte')
                    .where('owner_uid',
                        isEqualTo:
                            user!.uid) // Filter accounts by current user's UID
                    .snapshots(),
                // --- END MODIFICATION ---
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card_off,
                                size: 80, color: primaryColor.withOpacity(0.6)),
                            const SizedBox(height: 20),
                            Text(
                              'Vous n\'avez pas encore de compte. Créez-en un nouveau!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: primaryColor),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              height: 180, // Maintain the size for the add card
                              width: 180, // Maintain the size for the add card
                              child: AddCompteCard(
                                onTap: () {
                                  _showAddEditCompteModal(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final compte = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Compte.fromJson(doc.id, data);
                  }).toList();

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                    ),
                    itemCount: compte.length + 1,
                    itemBuilder: (context, index) {
                      if (index == compte.length) {
                        return AddCompteCard(
                          onTap: () {
                            _showAddEditCompteModal(context);
                          },
                        );
                      }
                      final currentCompte = compte[index];
                      return CompteCard(
                        compte: currentCompte,
                        onEdit: () {
                          _showAddEditCompteModal(context, currentCompte);
                        },
                        onDelete: () {
                          _confirmDelete(context, currentCompte);
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SingleComptePage(compte: currentCompte),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditCompteModal(BuildContext context, [Compte? compte]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddEditCompteModal(compte: compte);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Compte compte) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le compte?'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer le compte ${compte.num_cpt}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('compte')
                      .doc(compte.num_cpt)
                      .delete();
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Compte supprimé avec succès!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Erreur lors de la suppression: $e')),
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
}
