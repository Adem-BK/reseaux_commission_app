import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPasswordModal extends StatefulWidget {
  final ThemeData appTheme;
  final FirebaseAuth auth;
  final VoidCallback onDataUpdated;

  const EditPasswordModal({
    super.key,
    required this.appTheme,
    required this.auth,
    required this.onDataUpdated,
  });

  @override
  State<EditPasswordModal> createState() => _EditPasswordModalState();
}

class _EditPasswordModalState extends State<EditPasswordModal> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmNewPasswordController;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmNewPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final modalTheme = Theme.of(context);
    final Color primary = modalTheme.colorScheme.primary;
    final Color error = modalTheme.colorScheme.error;
    final Color onError = modalTheme.colorScheme.onError;
    final Color onPrimary = modalTheme.colorScheme.onPrimary;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Les nouveaux mots de passe ne correspondent pas.',
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

    final user = widget.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aucun utilisateur connecté.',
            style: TextStyle(color: onError),
          ),
          backgroundColor: error,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(_newPasswordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mot de passe mis à jour avec succès!',
            style: TextStyle(color: onPrimary),
          ),
          backgroundColor: primary,
        ),
      );
      widget.onDataUpdated();
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'wrong-password') {
        errorMessage = 'Mot de passe actuel incorrect. Veuillez réessayer.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Le nouveau mot de passe est trop faible.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            'Veuillez vous reconnecter pour mettre à jour votre mot de passe.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Erreur réseau. Veuillez vérifier votre connexion.';
      } else {
        errorMessage = 'Erreur de mise à jour du mot de passe: ${e.message}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
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
      data: currentTheme, // Apply the full app theme to the modal
      child: Container(
        color: background, // Set modal background
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
                  'Modifier le mot de passe',
                  style: widget.appTheme.textTheme.headlineSmall?.copyWith(
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                StatefulBuilder(
                  builder:
                      (BuildContext context, StateSetter setStateInsideModal) {
                    return TextFormField(
                      controller: _currentPasswordController,
                      obscureText: !_isCurrentPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        prefixIcon:
                            Icon(Icons.lock, color: onSurface.withOpacity(0.6)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isCurrentPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            setStateInsideModal(() {
                              _isCurrentPasswordVisible =
                                  !_isCurrentPasswordVisible;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: onSurface.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primary, width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: currentTheme.colorScheme.error,
                              width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: currentTheme.colorScheme.error,
                              width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        labelStyle:
                            TextStyle(color: onSurface.withOpacity(0.8)),
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                      ),
                      style: TextStyle(color: onSurface),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe actuel est requis.';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder:
                      (BuildContext context, StateSetter setStateInsideModal) {
                    return TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_isNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        prefixIcon: Icon(Icons.lock_open,
                            color: onSurface.withOpacity(0.6)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isNewPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            setStateInsideModal(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: onSurface.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primary, width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: currentTheme.colorScheme.error,
                              width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: currentTheme.colorScheme.error,
                              width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        labelStyle:
                            TextStyle(color: onSurface.withOpacity(0.8)),
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                      ),
                      style: TextStyle(color: onSurface),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nouveau mot de passe est requis.';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères.';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder:
                      (BuildContext context, StateSetter setStateInsideModal) {
                    return TextFormField(
                      controller: _confirmNewPasswordController,
                      obscureText: !_isConfirmNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        prefixIcon: Icon(Icons.check_circle_outline,
                            color: onSurface.withOpacity(0.6)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmNewPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: onSurface.withOpacity(0.6),
                          ),
                          onPressed: () {
                            setStateInsideModal(() {
                              _isConfirmNewPasswordVisible =
                                  !_isConfirmNewPasswordVisible;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: onSurface.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primary, width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: currentTheme.colorScheme.error,
                              width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: currentTheme.colorScheme.error,
                              width: 2.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        labelStyle:
                            TextStyle(color: onSurface.withOpacity(0.8)),
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
                      ),
                      style: TextStyle(color: onSurface),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La confirmation du mot de passe est requise.';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Les mots de passe ne correspondent pas.';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: primary)
                    : ElevatedButton(
                        onPressed: _updatePassword,
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
                          'Changer le mot de passe',
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
