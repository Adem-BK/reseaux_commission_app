import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reseaux_commission_app/models/users.dart'; // Import your Users model

class EditEmailModal extends StatefulWidget {
  final Users currentUser; // This holds the email from Firestore
  final ThemeData appTheme;
  final VoidCallback onDataUpdated;
  final FirebaseAuth
      auth; // FirebaseAuth is still provided but less central for this specific update

  const EditEmailModal({
    super.key,
    required this.currentUser,
    required this.appTheme,
    required this.onDataUpdated,
    required this.auth,
  });

  @override
  State<EditEmailModal> createState() => _EditEmailModalState();
}

class _EditEmailModalState extends State<EditEmailModal> {
  late TextEditingController _emailController;

  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize with the email from your Firestore model (Users.email)
    _emailController = TextEditingController(text: widget.currentUser.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateEmailInFirestore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseAuthUser = widget.auth.currentUser;
      if (firebaseAuthUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aucun utilisateur connecté pour la mise à jour.',
              style: TextStyle(color: widget.appTheme.colorScheme.onError),
            ),
            backgroundColor: widget.appTheme.colorScheme.error,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseAuthUser
              .uid) // Use the Firebase Auth UID as the Firestore document ID
          .update({'email': _emailController.text.trim()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Adresse e-mail mise à jour avec succès !',
            style: TextStyle(color: widget.appTheme.colorScheme.onPrimary),
          ),
          backgroundColor: widget.appTheme.colorScheme.primary,
        ),
      );
      widget.onDataUpdated();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la mise à jour de l\'e-mail dans la base de données: $e',
            style: TextStyle(color: widget.appTheme.colorScheme.onError),
          ),
          backgroundColor: widget.appTheme.colorScheme.error,
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
    final modalTheme = Theme.of(context);
    final Color primary = modalTheme.colorScheme.primary;
    final Color background = modalTheme.colorScheme.background;
    final Color onSurface = modalTheme.colorScheme.onSurface;

    return Theme(
      data: modalTheme,
      child: Container(
        color: background,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Modifier l\'adresse e-mail',
                  style: widget.appTheme.textTheme.headlineSmall?.copyWith(
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Nouvelle adresse e-mail',
                    prefixIcon:
                        Icon(Icons.email, color: onSurface.withOpacity(0.6)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(
                          8.0), // Consistent border radius
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: primary,
                          width: 2.0), // Thicker border on focus
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      // Error border style
                      borderSide: BorderSide(
                          color: modalTheme.colorScheme.error, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      // Focused error border style
                      borderSide: BorderSide(
                          color: modalTheme.colorScheme.error, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    labelStyle: TextStyle(color: onSurface.withOpacity(0.8)),
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                  ),
                  style: TextStyle(color: onSurface),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'adresse e-mail est requise.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Veuillez entrer une adresse e-mail valide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: primary)
                    : ElevatedButton(
                        onPressed: _updateEmailInFirestore,
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
                          minimumSize: const Size.fromHeight(
                              50), // Make button full width and taller
                        ),
                        child: Text(
                          'Enregistrer l\'e-mail',
                          style: modalTheme.textTheme.bodyLarge?.copyWith(
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
                    textStyle: modalTheme.textTheme.labelLarge,
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
