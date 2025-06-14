// lib/views/shared/modals/add_edit_compte.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:intl/intl.dart'; // For formatting date for display if needed
import 'dart:math'; // For generating random numbers

class AddEditCompteModal extends StatefulWidget {
  final Compte? compte; // Nullable for adding, non-null for editing

  const AddEditCompteModal({super.key, this.compte});

  @override
  State<AddEditCompteModal> createState() => _AddEditCompteModalState();
}

class _AddEditCompteModalState extends State<AddEditCompteModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _soldeController;
  late TextEditingController _agenceController;

  String? _displayNumCpt; // This will store the num_cpt for display
  DateTime? _displayDateCreation;

  // NEW: Store the owner_uid for the account being added/edited
  String? _ownerUid;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _soldeController = TextEditingController(
        text: widget.compte?.solde.toStringAsFixed(2) ?? '');
    _agenceController =
        TextEditingController(text: widget.compte?.agence ?? '');

    if (widget.compte != null) {
      // If editing an existing account
      _displayNumCpt = widget.compte!.num_cpt; // Use num_cpt for display
      _displayDateCreation = widget.compte!.date_creation;
      _ownerUid = widget.compte!.owner_uid; // Retrieve existing owner_uid
    } else {
      // If adding a new account
      // Automatically get the current user's UID for the owner_uid
      _ownerUid = FirebaseAuth.instance.currentUser?.uid;
    }
  }

  @override
  void dispose() {
    _soldeController.dispose();
    _agenceController.dispose();
    super.dispose();
  }

  String _generateNumCpt() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'CPT-${timestamp % 1000000000}-${random.toString().padLeft(4, '0')}';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _ownerUid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez vous connecter.')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final double solde = double.parse(_soldeController.text);
        final String agence = _agenceController.text;

        String finalNumCpt;
        DateTime finalDateCreation;
        int finalStage;
        String? finalRecruiterId;

        if (widget.compte == null) {
          // Logic for adding a new account
          finalNumCpt = _generateNumCpt(); // This will be the document ID
          finalDateCreation = DateTime.now();
          finalStage = 0; // Default stage for new accounts
          finalRecruiterId = null; // Default recruiter_id for new accounts
        } else {
          // Logic for editing an existing account
          finalNumCpt =
              widget.compte!.num_cpt; // Retain existing num_cpt (document ID)
          finalDateCreation = widget.compte!.date_creation;
          finalStage = widget.compte!.stage; // Retain existing stage
          finalRecruiterId =
              widget.compte!.recruiter_id; // Retain existing recruiter_id
        }

        final Compte newOrUpdatedCompte = Compte(
          num_cpt: finalNumCpt, // Pass num_cpt as the primary identifier
          solde: solde,
          date_creation: finalDateCreation,
          stage: finalStage,
          recruiter_id: finalRecruiterId,
          agence: agence,
          owner_uid: _ownerUid!, // IMPORTANT: Pass the owner_uid here
        );

        if (widget.compte == null) {
          // Use .doc(num_cpt).set() for adding
          await FirebaseFirestore.instance
              .collection('compte')
              .doc(newOrUpdatedCompte.num_cpt) // Use num_cpt as document ID
              .set(newOrUpdatedCompte.toMap()); // Use toMap for document data
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compte ajouté avec succès!')),
            );
          }
        } else {
          // Use .doc(num_cpt).update() for updating
          await FirebaseFirestore.instance
              .collection('compte')
              .doc(widget.compte!.num_cpt) // Use num_cpt as document ID
              .update(
                  newOrUpdatedCompte.toMap()); // Use toMap for document data
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compte modifié avec succès!')),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } on FirebaseException catch (e) {
        String message;
        if (e.code == 'permission-denied') {
          message = 'Vous n\'avez pas la permission d\'effectuer cette action.';
        } else if (e.code == 'unavailable') {
          message =
              'Connexion à la base de données impossible. Veuillez vérifier votre connexion.';
        } else {
          message = 'Erreur Firebase: ${e.message}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur inattendue: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final readOnlyFillColor = colorScheme.primary.withOpacity(0.05);
    final readOnlyBorderColor = colorScheme.outline;
    final readOnlyLabelColor = colorScheme.onSurface.withOpacity(0.7);
    final readOnlyTextColor = colorScheme.onSurface;
    final readOnlyIconColor = colorScheme.onSurface.withOpacity(0.7);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.compte == null
                    ? 'Ajouter un Compte'
                    : 'Modifier le Compte',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),

              // Display Numéro de Compte (read-only)
              if (widget.compte != null) // Only display if editing
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Numéro de Compte',
                      labelStyle: TextStyle(color: readOnlyLabelColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: readOnlyBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: readOnlyBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      prefixIcon:
                          Icon(Icons.credit_card, color: readOnlyIconColor),
                      filled: true,
                      fillColor: readOnlyFillColor,
                    ),
                    child: Text(
                      _displayNumCpt ?? 'N/A', // Display the stored num_cpt
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: readOnlyTextColor,
                      ),
                    ),
                  ),
                ),

              TextFormField(
                controller: _soldeController,
                decoration: InputDecoration(
                  labelText: 'Solde',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le solde';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _agenceController,
                decoration: InputDecoration(
                  labelText: 'Agence',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom de l\'agence';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Display Date de Création (read-only)
              if (widget.compte != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de Création',
                      labelStyle: TextStyle(color: readOnlyLabelColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: readOnlyBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: readOnlyBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      prefixIcon:
                          Icon(Icons.calendar_today, color: readOnlyIconColor),
                      filled: true,
                      fillColor: readOnlyFillColor,
                    ),
                    child: Text(
                      _displayDateCreation != null
                          ? DateFormat('dd/MM/yyyy HH:mm')
                              .format(_displayDateCreation!)
                          : 'N/A',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: readOnlyTextColor,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: Icon(
                            widget.compte == null ? Icons.add : Icons.save),
                        label: Text(
                            widget.compte == null ? 'Ajouter' : 'Modifier'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
