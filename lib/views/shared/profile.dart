// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase user updates
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reseaux_commission_app/models/users.dart';
import 'package:reseaux_commission_app/views/shared/modals/edit_email_modal.dart';
import 'package:reseaux_commission_app/views/shared/modals/edit_password_modal.dart';
import 'package:reseaux_commission_app/views/shared/modals/edit_personal_info_modal.dart'; // For Firestore user data

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<Users?> _userDataFuture;
  User? _firebaseAuthUser; // Renamed to avoid confusion with Users model

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _firebaseAuthUser = FirebaseAuth.instance.currentUser;
    if (_firebaseAuthUser != null) {
      _userDataFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseAuthUser!.uid)
          .get()
          .then((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          Map<String, dynamic> userDataMap = snapshot.data()!;
          userDataMap['id'] = snapshot.id;
          final userData = Users.fromJson(userDataMap);
          // *** IMPORTANT: We now trust the email from Firestore for display ***
          return userData;
        }
        return null;
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erreur de chargement des données utilisateur: $error')),
          );
        }
        return null;
      });
    } else {
      _userDataFuture = Future.value(null);
    }
    if (mounted) {
      setState(() {});
    }
  }

  // --- Modal Launching Functions ---
  void _showEditPersonalInfoModal(Users currentUser, ThemeData appTheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return EditPersonalInfoModal(
          currentUser: currentUser,
          appTheme: appTheme,
          onDataUpdated: _fetchUserData,
        );
      },
    );
  }

  void _showEditEmailModal(Users currentUser, ThemeData appTheme) {
    if (_firebaseAuthUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Aucun utilisateur connecté pour changer l\'e-mail.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return EditEmailModal(
          currentUser:
              currentUser, // This currentUser contains the Firestore email
          appTheme: appTheme,
          onDataUpdated: _fetchUserData,
          auth: FirebaseAuth.instance, // Pass the FirebaseAuth instance
        );
      },
    );
  }

  void _showEditPasswordModal(ThemeData appTheme) {
    if (_firebaseAuthUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Aucun utilisateur connecté pour changer le mot de passe.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return EditPasswordModal(
          appTheme: appTheme,
          onDataUpdated: _fetchUserData,
          auth: FirebaseAuth.instance,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onBackground = Theme.of(context).colorScheme.onSurface;
    final Color background = Theme.of(context).colorScheme.surface;
    final Color error = Theme.of(context).colorScheme.error;
    final Color onError = Theme.of(context).colorScheme.onError;

    return Scaffold(
      backgroundColor: background,
      body: FutureBuilder<Users?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          final theme = Theme.of(context);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erreur de chargement du profil: ${snapshot.error}',
                    style: TextStyle(color: error)));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
                child: Text('Aucune donnée de profil trouvée.',
                    style: TextStyle(color: onBackground)));
          } else {
            final Users user = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          // ignore: duplicate_ignore
                          // ignore: deprecated_member_use
                          backgroundColor: primary.withOpacity(0.2),
                          child: Icon(Icons.person, size: 80, color: primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${user.prenom} ${user.nom}',
                          textAlign: TextAlign.center, // Added this line
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: onBackground,
                          ),
                        ),
                        Text(
                          user.role,
                          textAlign: TextAlign.center, // Added this line
                          style: theme.textTheme.titleMedium?.copyWith(
                            // ignore: duplicate_ignore
                            // ignore: deprecated_member_use
                            color: onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Divider(color: onBackground.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  _buildProfileSection(
                    context,
                    title: 'Informations Personnelles',
                    children: [
                      _buildProfileInfoRow(
                          context, 'Nom', user.nom, Icons.person_outline),
                      _buildProfileInfoRow(
                          context, 'Prénom', user.prenom, Icons.person_outline),
                      _buildProfileInfoRow(
                          context, 'Téléphone', user.tel, Icons.phone),
                    ],
                    onEditPressed: () =>
                        _showEditPersonalInfoModal(user, theme),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    context,
                    title: 'Adresse E-mail',
                    children: [
                      _buildProfileInfoRow(
                          context, 'E-mail', user.email, Icons.email_outlined),
                    ],
                    onEditPressed: () => _showEditEmailModal(
                        user, theme), // Pass the Firestore user object
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    context,
                    title: 'Mot de passe',
                    children: [
                      _buildProfileInfoRow(context, 'Mot de passe', '********',
                          Icons.lock_outline),
                    ],
                    onEditPressed: () => _showEditPasswordModal(theme),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      // Changed from ElevatedButton to ElevatedButton.icon
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: error,
                        foregroundColor: onError,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(Icons.logout,
                          color: onError), // Add your desired icon here
                      label: Text(
                        // Renamed child to label for ElevatedButton.icon
                        'Déconnexion',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onError,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    VoidCallback? onEditPressed,
  }) {
    final currentTheme = Theme.of(context);

    final Color primary = currentTheme.colorScheme.primary;
    final Color secondary = currentTheme.colorScheme.secondary;
    final Color surface = currentTheme.colorScheme.surface;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: currentTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                if (onEditPressed != null)
                  IconButton(
                    icon: Icon(Icons.edit, color: secondary),
                    onPressed: onEditPressed,
                    tooltip: 'Modifier',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color onSurface = colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: onSurface.withOpacity(0.6)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
