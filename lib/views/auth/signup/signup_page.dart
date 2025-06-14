import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:reseaux_commission_app/widgets/Logo.dart';
import 'package:reseaux_commission_app/views/auth/services/auth_service.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

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
                    _SignUpFormContent(),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(32.0),
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: const Row(
                    children: [
                      Expanded(child: Logo()),
                      Expanded(
                        child: Center(child: _SignUpFormContent()),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SignUpFormContent extends StatefulWidget {
  const _SignUpFormContent();

  @override
  State<_SignUpFormContent> createState() => __SignUpFormContentState();
}

class __SignUpFormContentState extends State<_SignUpFormContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _phoneNumber;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _verificationId = '';
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Flexible(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                    _nomController, 'Nom *', 'Entrez votre nom', Icons.person),
                _gap(),
                _buildTextField(_prenomController, 'Prénom *',
                    'Entrez votre prénom', Icons.person_outline),
                _gap(),
                _buildTextField(_emailController, 'Email', 'Entrez votre email',
                    Icons.email,
                    isEmail: true),
                _gap(),
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Téléphone *',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                  initialCountryCode: 'TN',
                  onChanged: (phone) {
                    _phoneNumber = phone.completeNumber;
                  },
                  validator: (value) {
                    if (value == null || value.number.isEmpty) {
                      return 'Numéro requis';
                    }
                    return null;
                  },
                ),
                _gap(),
                _buildPasswordField(_passwordController, 'Mot de passe *',
                    'Entrez un mot de passe', true),
                _gap(),
                _buildPasswordField(
                    _confirmPasswordController,
                    'Confirmer le mot de passe *',
                    'Réécrivez le mot de passe',
                    false),
                _gap(),
                SizedBox(
                  // Wrapped with SizedBox for consistent width
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : _signup, // Disable when loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Consistent primary color
                      foregroundColor: primaryColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white, // Text color for contrast
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12), // Consistent padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8), // Consistent border radius
                      ),
                      minimumSize:
                          const Size.fromHeight(50), // Consistent height
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: primaryColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors
                                    .white) // Progress indicator color adapts
                        : Text(
                            'Créer un compte',
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

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon,
      {bool isEmail = false}) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: onSurfaceColor),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      validator: (value) {
        if (label.endsWith('*') && (value == null || value.isEmpty)) {
          return 'Champ requis';
        }
        if (isEmail && value != null && value.isNotEmpty) {
          final emailValid =
              RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value);
          if (!emailValid) return 'Email invalide';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      String hint, bool isPassword) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return TextFormField(
      controller: controller,
      obscureText:
          isPassword ? !_isPasswordVisible : !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock, color: onSurfaceColor),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPassword
                ? (_isPasswordVisible ? Icons.visibility_off : Icons.visibility)
                : (_isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility),
            color: onSurfaceColor,
          ),
          onPressed: () {
            setState(() {
              if (isPassword) {
                _isPasswordVisible = !_isPasswordVisible;
              } else {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              }
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Champ requis';
        if (isPassword && value.length < 6) return 'Minimum 6 caractères';
        if (!isPassword && value != _passwordController.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
    );
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneNumber!,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erreur de vérification')),
        );
        setState(() => _isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _showCodeInputDialog();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        setState(() => _isLoading = false);
      },
    );
  }

  void _showCodeInputDialog() {
    final TextEditingController codeController = TextEditingController();
    final errorColor = Theme.of(context).colorScheme.error;
    final onErrorColor = Theme.of(context).colorScheme.onError;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Code SMS', style: TextStyle(color: primaryColor)),
        content: TextField(
          controller: codeController,
          decoration: InputDecoration(
            hintText: 'Entrez le code reçu par SMS',
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              try {
                PhoneAuthProvider.credential(
                  verificationId: _verificationId,
                  smsCode: code,
                );
                final String pseudoEmail = '$_phoneNumber@app.local';
                final UserCredential userCredential =
                    await _auth.createUserWithEmailAndPassword(
                        email: pseudoEmail, password: _passwordController.text);
                final User? user = userCredential.user;

                if (user != null) {
                  String initialRole = 'user';
                  if (_emailController.text.trim() ==
                      'your_admin_email@example.com') {
                    initialRole = 'admin';
                  }
                  await _authService.saveUserData(
                    user.uid,
                    _nomController.text.trim(),
                    _prenomController.text.trim(),
                    _emailController.text.trim(),
                    _phoneNumber!,
                    role: initialRole, // Pass 'admin' for the specific email
                  );

                  if (mounted) {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Succès',
                            style: TextStyle(color: primaryColor)),
                        content: const Text('Compte créé avec succès !'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _formKey.currentState?.reset();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              } on FirebaseAuthException catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      backgroundColor: errorColor,
                      content: Text(
                          'Erreur lors de la création du compte: ${e.message}',
                          style: TextStyle(color: onErrorColor))),
                );
                setState(() => _isLoading = false);
              }
            },
            child: Text('Valider', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 16);
}
