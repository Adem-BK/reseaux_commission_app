// lib/views/admin/shared/modals/admin_add_edit_user.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reseaux_commission_app/models/users.dart';

class AdminAddEditUserModal extends StatefulWidget {
  final Users? user; // Null if adding, not null if editing

  const AdminAddEditUserModal({super.key, this.user});

  @override
  State<AdminAddEditUserModal> createState() => _AdminAddEditUserModalState();
}

class _AdminAddEditUserModalState extends State<AdminAddEditUserModal> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _idController; // Controller for the 'id' field
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _telController;
  late TextEditingController _roleController;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(
        text: widget.user?.id ??
            'USR-${DateTime.now().millisecondsSinceEpoch % 100000}'); // Generate a temporary ID for new users, if 'id' is not the doc ID
    _nomController = TextEditingController(text: widget.user?.nom ?? '');
    _prenomController = TextEditingController(text: widget.user?.prenom ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _telController = TextEditingController(text: widget.user?.tel ?? '');
    _roleController = TextEditingController(text: widget.user?.role ?? 'user');
  }

  @override
  void dispose() {
    _idController.dispose(); // Dispose the new ID controller
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newUser = Users(
          id: _idController
              .text, // Use the ID from the controller (which is either existing or generated)
          nom: _nomController.text,
          prenom: _prenomController.text,
          email: _emailController.text,
          tel: _telController.text,
          role: _roleController.text,
        );

        // Determine the Firestore document ID. If 'id' is a field within the document,
        // the actual Firestore document ID might be different or auto-generated.
        // For consistency, let's make the Firestore document ID the same as the 'id' field.
        String firestoreDocId = newUser.id;

        if (_isEditing) {
          // Check if the 'id' field has been changed by mistake (it's readOnly in UI)
          if (firestoreDocId != widget.user!.id) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Erreur: L\'ID utilisateur ne peut pas être modifié.')),
              );
            }
            return;
          }
          await _firestore
              .collection('users')
              .doc(firestoreDocId)
              .update(newUser.toJson()); // Use toJson()
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Utilisateur modifié avec succès!')),
            );
          }
        } else {
          // For new users, ensure the generated ID doesn't conflict with existing document IDs
          // Also check for email existence to prevent duplicate users (good practice)
          final existingEmail = await _firestore
              .collection('users')
              .where('email', isEqualTo: newUser.email)
              .limit(1)
              .get();
          if (existingEmail.docs.isNotEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Erreur: Un utilisateur avec cet email existe déjà.')),
              );
            }
            return;
          }

          final existingIdDoc =
              await _firestore.collection('users').doc(firestoreDocId).get();
          if (existingIdDoc.exists) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Erreur: Un utilisateur avec cet ID existe déjà. Veuillez en générer un nouveau.')),
              );
            }
            // Regenerate ID and allow user to try again
            setState(() {
              _idController.text =
                  'USR-${DateTime.now().millisecondsSinceEpoch % 100000}';
            });
            return;
          }

          await _firestore
              .collection('users')
              .doc(firestoreDocId)
              .set(newUser.toJson()); // Use toJson()
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Utilisateur ajouté avec succès!')),
            );
          }
        }
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur Firebase: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          _isEditing ? 'Modifier Utilisateur' : 'Ajouter Nouvel Utilisateur'),
      content: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                // ID field is always displayed now
                controller: _idController,
                readOnly: _isEditing, // Read-only if editing
                decoration: InputDecoration(
                  labelText: 'ID Utilisateur',
                  hintText: 'Ex: USR-12345',
                  helperText: _isEditing
                      ? 'L\'ID ne peut pas être modifié'
                      : 'Généré automatiquement ou entrez un ID unique',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un ID utilisateur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Ex: Dupont',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  hintText: 'Ex: Jean',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Ex: jean.dupont@example.com',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _telController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  hintText: 'Ex: +216 12 345 678',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le numéro de téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  hintText: 'Ex: user, admin, recruiter',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le rôle';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveUser,
          child: Text(_isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }
}
