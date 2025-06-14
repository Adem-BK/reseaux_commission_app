import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:reseaux_commission_app/views/admin/admin_navbar.dart';
import 'package:reseaux_commission_app/views/auth/services/auth_service.dart';
import 'package:reseaux_commission_app/views/user/user_navbar.dart';
import 'package:reseaux_commission_app/widgets/Logo.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: isSmallScreen
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Logo(),
                    _FormContent(),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(32.0),
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: const Row(
                    children: [
                      Expanded(child: Logo()),
                      Expanded(child: Center(child: _FormContent())),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _FormContent extends StatefulWidget {
  const _FormContent();

  @override
  State<_FormContent> createState() => __FormContentState();
}

class __FormContentState extends State<_FormContent> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String _fullPhoneNumber = '';
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        final success = await _authService.loginWithPhoneAndPassword(
          _fullPhoneNumber,
          _passwordController.text,
        );

        if (success) {
          final userData = await _authService.getStoredUserData();
          final String role = userData?.role ??
              'user'; // Default to 'user' if role is missing or userData is null
          if (!mounted) return;

          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminNavBarPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserNavBarPage()),
            );
          }
        } else {
          _showErrorMessage('Numéro de téléphone ou mot de passe incorrect');
        }
      } catch (e) {
        _showErrorMessage(
            'Une erreur s\'est produite lors de la connexion. Veuillez réessayer.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              Theme.of(context).colorScheme.error, // Using error color
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    return Flexible(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: primaryColor), // Focused border color
                    ),
                  ),
                  initialCountryCode:
                      'TN', // Set Tunisia as the default country
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                  },
                  validator: (phone) {
                    if (_fullPhoneNumber.isEmpty) {
                      return 'Veuillez entrer un numéro de téléphone valide';
                    }
                    return null;
                  },
                ),
                _gap(),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outline,
                        color: onSurfaceColor), // Icon color
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: primaryColor), // Focused border color
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: onSurfaceColor, // Icon color
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                _gap(),
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  title: const Text('Se souvenir de moi'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: primaryColor, // Checkbox active color
                ),
                _gap(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: primaryColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(
                          50), // Ensures consistent height
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: primaryColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white)
                        : Text(
                            'Se Connecter',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: primaryColor.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 16);
}
