import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reseaux_commission_app/models/users.dart';

class EditPersonalInfoModal extends StatefulWidget {
  final Users currentUser;
  final ThemeData appTheme;
  final VoidCallback onDataUpdated;

  const EditPersonalInfoModal({
    super.key,
    required this.currentUser,
    required this.appTheme,
    required this.onDataUpdated,
  });

  @override
  State<EditPersonalInfoModal> createState() => _EditPersonalInfoModalState();
}

class _EditPersonalInfoModalState extends State<EditPersonalInfoModal> {
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  String? _phoneNumber;
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Added FormState for validation

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.currentUser.nom);
    _prenomController = TextEditingController(text: widget.currentUser.prenom);
    _phoneNumber = widget.currentUser.tel;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _updatePersonalInfo() async {
    final modalTheme = Theme.of(context);
    final Color primary = modalTheme.colorScheme.primary;
    final Color error = modalTheme.colorScheme.error;
    final Color onError = modalTheme.colorScheme.onError;
    final Color onPrimary = modalTheme.colorScheme.onPrimary;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez entrer un numéro de téléphone.',
            style: TextStyle(color: onError),
          ),
          backgroundColor: error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.id) // Use .id from your Users model
          .update({
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'tel': _phoneNumber,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Informations personnelles mises à jour avec succès!',
            style: TextStyle(color: onPrimary),
          ),
          backgroundColor: primary,
        ),
      );
      widget.onDataUpdated();
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: ${e.message}',
            style: TextStyle(color: onError),
          ),
          backgroundColor: error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Une erreur inattendue est survenue: $e',
            style: TextStyle(color: onError),
          ),
          backgroundColor: error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    final Color primary = currentTheme.colorScheme.primary;
    final Color onSurface = currentTheme.colorScheme.onSurface;
    final Color background = currentTheme.colorScheme.background;

    return Theme(
      data: widget.appTheme,
      child: Container(
        color: background, // Consistent background color
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
        child: SingleChildScrollView(
          child: Form(
            // Wrap with Form for validation
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Modifier les informations personnelles',
                  style: currentTheme.textTheme.headlineSmall?.copyWith(
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  // Changed to TextFormField for validation
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.person_outline,
                        color: onSurface.withOpacity(0.6)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: currentTheme.colorScheme.error, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: currentTheme.colorScheme.error, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    labelStyle: TextStyle(color: onSurface.withOpacity(0.8)),
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                  ),
                  style: TextStyle(color: onSurface),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  // Changed to TextFormField for validation
                  controller: _prenomController,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline,
                        color: onSurface.withOpacity(0.6)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: currentTheme.colorScheme.error, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: currentTheme.colorScheme.error, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    labelStyle: TextStyle(color: onSurface.withOpacity(0.8)),
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                  ),
                  style: TextStyle(color: onSurface),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le prénom est requis.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Téléphone *',
                    border: OutlineInputBorder(
                      // Keep this as it's the default for IntlPhoneField
                      borderSide: BorderSide(color: onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: currentTheme.colorScheme.error, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: currentTheme.colorScheme.error, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon:
                        Icon(Icons.phone, color: onSurface.withOpacity(0.6)),
                    labelStyle: TextStyle(color: onSurface.withOpacity(0.8)),
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                  ),
                  initialValue: widget.currentUser.tel,
                  initialCountryCode: 'TN',
                  onChanged: (phone) {
                    setState(() {
                      _phoneNumber = phone.completeNumber;
                    });
                  },
                  style: TextStyle(color: onSurface),
                  dropdownTextStyle: TextStyle(color: onSurface),
                  validator: (value) {
                    if (value == null || value.number.isEmpty) {
                      return 'Numéro requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: primary)
                    : ElevatedButton(
                        onPressed: _updatePersonalInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: primary.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(
                          'Enregistrer les modifications',
                          style: currentTheme.textTheme.bodyLarge?.copyWith(
                            color: primary.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: onSurface.withOpacity(0.7),
                    textStyle: currentTheme.textTheme.labelLarge,
                  ),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
