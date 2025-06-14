// lib/views/admin/shared/modals/admin_add_edit_compte.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reseaux_commission_app/models/compte.dart';

class AdminAddEditCompteModal extends StatefulWidget {
  final Compte? compte; // Null if adding, not null if editing

  const AdminAddEditCompteModal({super.key, this.compte});

  @override
  State<AdminAddEditCompteModal> createState() =>
      _AdminAddEditCompteModalState();
}

class _AdminAddEditCompteModalState extends State<AdminAddEditCompteModal> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _numCptController;
  late TextEditingController _soldeController;
  late TextEditingController _stageController;
  late TextEditingController _recruiterIdController;
  late TextEditingController _agenceController;
  late TextEditingController _ownerUidController;

  bool get _isEditing => widget.compte != null;

  @override
  void initState() {
    super.initState();
    _numCptController =
        TextEditingController(text: widget.compte?.num_cpt ?? '');
    _soldeController = TextEditingController(
        text: widget.compte?.solde.toStringAsFixed(2) ?? '');
    _stageController =
        TextEditingController(text: widget.compte?.stage.toString() ?? '0');
    _recruiterIdController =
        TextEditingController(text: widget.compte?.recruiter_id ?? '');
    _agenceController =
        TextEditingController(text: widget.compte?.agence ?? '');
    _ownerUidController =
        TextEditingController(text: widget.compte?.owner_uid ?? '');

    if (!_isEditing) {
      _numCptController.text =
          'CPT-${DateTime.now().millisecondsSinceEpoch % 100000}';
    }
  }

  @override
  void dispose() {
    _numCptController.dispose();
    _soldeController.dispose();
    _stageController.dispose();
    _recruiterIdController.dispose();
    _agenceController.dispose();
    _ownerUidController.dispose();
    super.dispose();
  }

  Future<void> _saveCompte() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newSolde = double.parse(_soldeController.text);
        final newStage = int.parse(_stageController.text);

        final newCompte = Compte(
          num_cpt: _isEditing ? widget.compte!.num_cpt : _numCptController.text,
          solde: newSolde,
          date_creation:
              _isEditing ? widget.compte!.date_creation : DateTime.now(),
          stage: newStage,
          recruiter_id: _recruiterIdController.text.isEmpty
              ? null
              : _recruiterIdController.text,
          agence: _agenceController.text,
          owner_uid: _ownerUidController.text,
        );

        if (_isEditing) {
          await _firestore
              .collection('compte')
              .doc(newCompte.num_cpt)
              .update(newCompte.toMap());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compte modifié avec succès!')),
            );
          }
        } else {
          await _firestore
              .collection('compte')
              .doc(newCompte.num_cpt)
              .set(newCompte.toMap());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compte ajouté avec succès!')),
            );
          }
        }
        if (mounted) {
          Navigator.of(context).pop(true); // Pop with true to indicate success
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
      title: Text(_isEditing ? 'Modifier Compte' : 'Ajouter Nouveau Compte'),
      content: SingleChildScrollView(
        // Make it more spacious
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch fields horizontally
            children: [
              TextFormField(
                controller: _numCptController,
                readOnly: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Numéro de Compte',
                  hintText: 'Ex: CPT-12345',
                  helperText: _isEditing
                      ? 'Ne peut pas être modifié'
                      : 'Sera l\'ID du document Firestore',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro de compte';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _soldeController,
                decoration: const InputDecoration(
                  labelText: 'Solde',
                  hintText: 'Ex: 1500.00',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Veuillez entrer un solde valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _stageController,
                decoration: const InputDecoration(
                  labelText: 'Niveau (Stage)',
                  hintText: 'Ex: 1',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Veuillez entrer un niveau valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _recruiterIdController,
                decoration: const InputDecoration(
                  labelText: 'ID Recruteur (Optionnel)',
                  hintText: 'Ex: REC-98765',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _agenceController,
                decoration: const InputDecoration(
                  labelText: 'Agence',
                  hintText: 'Ex: Tunis',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'agence';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _ownerUidController,
                decoration: const InputDecoration(
                  labelText: 'UID Propriétaire',
                  hintText: 'Ex: aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'UID du propriétaire';
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
          onPressed: () =>
              Navigator.of(context).pop(false), // Pop with false on cancel
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveCompte,
          child: Text(_isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }
}
