// lib/views/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import all necessary models
import 'package:reseaux_commission_app/models/users.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/models/commissions.dart';
import 'package:reseaux_commission_app/models/transactions.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Users?
      _appUser; // Declared to hold custom user data like 'role' from Firestore

  // Global Metrics
  int _totalUsers = 0;
  int _totalAccounts = 0;
  double _totalAccountsBalance = 0.0;
  double _totalCommissionsEarned = 0.0;
  double _totalCommissionsPending = 0.0;
  double _totalCommissionsPaid = 0.0;
  int _totalTransactions = 0;
  double _totalCreditTransactions = 0.0;
  double _totalDebitTransactions = 0.0;

  // Recent Activities
  List<Users> _recentUsers = [];
  List<Compte> _recentAccounts = [];
  List<Transactions> _recentTransactions = [];
  List<Commissions> _recentCommissions = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAdminDashboardData();
  }

  Future<void> _fetchAdminDashboardData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _errorMessage =
            'Veuillez vous connecter pour voir votre tableau de bord.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous errors
    });

    try {
      // Fetch custom user data (like 'role') from Firestore using the FirebaseAuth UID
      print(
          'DEBUG: Attempting to fetch current user data for UID: ${currentUser.uid}');
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        print(
            'DEBUG: userDoc for ${currentUser.uid} exists. Data: ${userDoc.data()}');
        _appUser = Users.fromJson(
            userDoc.data()!); // Populate _appUser for custom fields
      } else {
        _errorMessage =
            'Informations administrateur introuvables dans Firestore.';
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 1. Fetch Users Data
      print('DEBUG: Fetching all users data...');
      final usersSnapshot = await _firestore.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;
      _recentUsers = []; // Clear previous data
      for (var doc in usersSnapshot.docs) {
        if (doc.data().isNotEmpty) {
          // Ensure document is not empty
          try {
            print(
                'DEBUG: Processing user document ID: ${doc.id}, Data: ${doc.data()}');
            _recentUsers.add(Users.fromJson(doc.data()!));
          } catch (e) {
            print(
                'ERROR: Failed to parse User document ID: ${doc.id}, Error: $e, Data: ${doc.data()}');
            // Log the error but continue processing other documents
          }
        } else {
          print('WARNING: Skipping empty User document ID: ${doc.id}');
        }
      }
      _recentUsers.sort((a, b) => b.id.compareTo(a.id));
      if (_recentUsers.length > 5) _recentUsers = _recentUsers.sublist(0, 5);

      // 2. Fetch Accounts Data
      print('DEBUG: Fetching all accounts data...');
      final accountsSnapshot = await _firestore.collection('compte').get();
      _totalAccounts = accountsSnapshot.docs.length;
      double tempTotalBalance = 0.0;
      _recentAccounts = []; // Clear previous data
      for (var doc in accountsSnapshot.docs) {
        if (doc.data().isNotEmpty) {
          // Ensure document is not empty
          try {
            print(
                'DEBUG: Processing account document ID: ${doc.id}, Data: ${doc.data()}');
            final compte =
                Compte.fromJson(doc.id, doc.data() as Map<String, dynamic>);
            tempTotalBalance += compte.solde;
            _recentAccounts.add(compte);
          } catch (e) {
            print(
                'ERROR: Failed to parse Compte document ID: ${doc.id}, Error: $e, Data: ${doc.data()}');
            // Log the error but continue processing other documents
          }
        } else {
          print('WARNING: Skipping empty Compte document ID: ${doc.id}');
        }
      }
      _totalAccountsBalance = tempTotalBalance;
      _recentAccounts
          .sort((a, b) => b.date_creation.compareTo(a.date_creation));
      if (_recentAccounts.length > 5)
        _recentAccounts = _recentAccounts.sublist(0, 5);

      // 3. Fetch Commissions Data
      print('DEBUG: Fetching all commissions data...');
      final commissionsSnapshot =
          await _firestore.collection('commissions').get();
      double tempTotalCommissionsEarned = 0.0;
      double tempTotalCommissionsPending = 0.0;
      double tempTotalCommissionsPaid = 0.0;
      _recentCommissions = []; // Clear previous data
      for (var doc in commissionsSnapshot.docs) {
        if (doc.data().isNotEmpty) {
          // Ensure document is not empty
          try {
            print(
                'DEBUG: Processing commission document ID: ${doc.id}, Data: ${doc.data()}');
            final commission = Commissions.fromJson(
                doc.id, doc.data() as Map<String, dynamic>);
            tempTotalCommissionsEarned += commission.amount;
            if (commission.status == 'payé') {
              tempTotalCommissionsPaid += commission.amount;
            } else if (commission.status == 'en attente') {
              tempTotalCommissionsPending += commission.amount;
            }
            _recentCommissions.add(commission);
          } catch (e) {
            print(
                'ERROR: Failed to parse Commission document ID: ${doc.id}, Error: $e, Data: ${doc.data()}');
            // Log the error but continue processing other documents
          }
        } else {
          print('WARNING: Skipping empty Commission document ID: ${doc.id}');
        }
      }
      _totalCommissionsEarned = tempTotalCommissionsEarned;
      _totalCommissionsPaid = tempTotalCommissionsPaid;
      _totalCommissionsPending = tempTotalCommissionsPending;
      _recentCommissions.sort((a, b) => b.date_earned.compareTo(a.date_earned));
      if (_recentCommissions.length > 5)
        _recentCommissions = _recentCommissions.sublist(0, 5);

      // 4. Fetch Transactions Data
      print('DEBUG: Fetching all transactions data...');
      final transactionsSnapshot =
          await _firestore.collection('transactions').get();
      _totalTransactions = transactionsSnapshot.docs.length;
      double tempTotalCreditTransactions = 0.0;
      double tempTotalDebitTransactions = 0.0;

      _recentTransactions = []; // Clear previous data
      for (var doc in transactionsSnapshot.docs) {
        if (doc.data().isNotEmpty) {
          // Ensure document is not empty
          try {
            print(
                'DEBUG: Processing transaction document ID: ${doc.id}, Data: ${doc.data()}');
            final transaction = Transactions.fromJson(
                doc.id, doc.data() as Map<String, dynamic>);
            if (transaction.type == 'Crédit') {
              tempTotalCreditTransactions += transaction.amount;
            } else if (transaction.type == 'Débit') {
              tempTotalDebitTransactions += transaction.amount;
            }
            _recentTransactions.add(transaction);
          } catch (e) {
            print(
                'ERROR: Failed to parse Transaction document ID: ${doc.id}, Error: $e, Data: ${doc.data()}');
            // Log the error but continue processing other documents
          }
        } else {
          print('WARNING: Skipping empty Transaction document ID: ${doc.id}');
        }
      }
      _totalCreditTransactions = tempTotalCreditTransactions;
      _totalDebitTransactions = tempTotalDebitTransactions;
      _recentTransactions
          .sort((a, b) => b.date_creation.compareTo(a.date_creation));
      if (_recentTransactions.length > 5)
        _recentTransactions = _recentTransactions.sublist(0, 5);
    } on FirebaseException catch (e) {
      _errorMessage = 'Erreur de chargement des données Firebase: ${e.message}';
      print('Firebase Error: ${e.code} - ${e.message}');
    } catch (e) {
      // This is the General Error catch block for any unhandled exceptions
      _errorMessage = 'Une erreur inattendue est survenue: $e';
      print('General Error from Dashboard (Unhandled): $e');
      if (e is TypeError) {
        print('Type Error Details: ${e.runtimeType} - ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 80, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchAdminDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Use FirebaseAuth.currentUser for basic info, and _appUser for custom roles
    final currentAdminUser = _auth.currentUser;
    // Fallback for display name and email if _appUser is null or fields are empty
    final adminDisplayName = _appUser?.prenom?.isNotEmpty == true
        ? _appUser!.prenom
        : (currentAdminUser?.displayName ?? 'Administrateur');
    final adminEmail = _appUser?.email?.isNotEmpty == true
        ? _appUser!.email
        : (currentAdminUser?.email ?? 'Email inconnu');
    // The 'role' is a custom field, so it comes from the _appUser model fetched from Firestore.
    final adminRole =
        _appUser?.role?.isNotEmpty == true ? _appUser!.role : 'Role inconnu';

    return RefreshIndicator(
      onRefresh: _fetchAdminDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau de Bord Administrateur',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
            Text(
              'Bienvenue, $adminDisplayName! ($adminRole)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Text(
              adminEmail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 25),

            // Global Metrics Grid
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900
                  ? 4
                  : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                    context,
                    'Total Utilisateurs',
                    _totalUsers.toString(),
                    Icons.people_alt,
                    Colors.deepOrange),
                _buildMetricCard(
                    context,
                    'Total Comptes',
                    _totalAccounts.toString(),
                    Icons.account_balance_wallet,
                    primaryColor),
                _buildMetricCard(
                    context,
                    'Solde Global',
                    '${_totalAccountsBalance.toStringAsFixed(2)} TND',
                    Icons.monetization_on,
                    Colors.blueAccent),
                _buildMetricCard(
                    context,
                    'Commissions Gagnées',
                    '${_totalCommissionsEarned.toStringAsFixed(2)} TND',
                    Icons.currency_exchange,
                    Colors.green),
                _buildMetricCard(
                    context,
                    'Commissions en Attente',
                    '${_totalCommissionsPending.toStringAsFixed(2)} TND',
                    Icons.hourglass_empty,
                    Colors.orange),
                _buildMetricCard(
                    context,
                    'Commissions Payées',
                    '${_totalCommissionsPaid.toStringAsFixed(2)} TND',
                    Icons.check_circle_outline,
                    Colors.teal),
                _buildMetricCard(
                    context,
                    'Total Transactions',
                    _totalTransactions.toString(),
                    Icons.receipt_long,
                    Colors.purple),
                _buildMetricCard(
                    context,
                    'Total Crédits',
                    '${_totalCreditTransactions.toStringAsFixed(2)} TND',
                    Icons.arrow_circle_up,
                    Colors.lightGreen),
                _buildMetricCard(
                    context,
                    'Total Débits',
                    '${_totalDebitTransactions.toStringAsFixed(2)} TND',
                    Icons.arrow_circle_down,
                    Colors.redAccent),
              ],
            ),
            const SizedBox(height: 30),

            // Recent Activities Sections
            _buildRecentActivitySection(
              context,
              'Utilisateurs Récents',
              _recentUsers
                  .map((user) => ListTile(
                        leading: const Icon(Icons.person, size: 20),
                        title: Text('${user.prenom} ${user.nom}',
                            style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text('${user.email} - ${user.role}',
                            style: Theme.of(context).textTheme.bodySmall),
                        // FIX APPLIED HERE: Safely get substring of ID
                        trailing: Text(
                            'ID: ${user.id.length > 6 ? user.id.substring(0, 6) + '...' : user.id}',
                            style: Theme.of(context).textTheme.bodySmall),
                        onTap: () {/* Navigate to user detail */},
                      ))
                  .toList(),
              onSurfaceColor,
            ),
            _buildRecentActivitySection(
              context,
              'Comptes Récents',
              _recentAccounts
                  .map((compte) => ListTile(
                        leading:
                            const Icon(Icons.account_balance_wallet, size: 20),
                        title: Text(compte.num_cpt,
                            style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text(
                            'Solde: ${compte.solde.toStringAsFixed(2)} TND - Agence: ${compte.agence}',
                            style: Theme.of(context).textTheme.bodySmall),
                        trailing: Text(
                            'Crée le: ${DateFormat('dd/MM/yy').format(compte.date_creation)}',
                            style: Theme.of(context).textTheme.bodySmall),
                        onTap: () {/* Navigate to compte detail */},
                      ))
                  .toList(),
              onSurfaceColor,
            ),
            _buildRecentActivitySection(
              context,
              'Transactions Récentes',
              _recentTransactions
                  .map((transaction) => ListTile(
                        leading: Icon(
                            transaction.type == 'Crédit'
                                ? Icons.arrow_circle_up
                                : Icons.arrow_circle_down,
                            color: transaction.type == 'Crédit'
                                ? Colors.green
                                : Colors.red,
                            size: 20),
                        title: Text(
                            '${transaction.type}: ${transaction.amount.toStringAsFixed(2)} TND',
                            style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text(
                            'Compte: ${transaction.compte_id} - Statut: ${transaction.status}',
                            style: Theme.of(context).textTheme.bodySmall),
                        trailing: Text(
                            DateFormat('dd/MM/yy')
                                .format(transaction.date_creation),
                            style: Theme.of(context).textTheme.bodySmall),
                        onTap: () {/* Navigate to transaction detail */},
                      ))
                  .toList(),
              onSurfaceColor,
            ),
            _buildRecentActivitySection(
              context,
              'Commissions Récentes',
              _recentCommissions
                  .map((commission) => ListTile(
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              _getCommissionStatusColor(commission.status),
                          child: Icon(
                              _getCommissionStatusIcon(commission.status),
                              color: Colors.white,
                              size: 14),
                        ),
                        title: Text(
                            '${commission.amount.toStringAsFixed(2)} TND (Niveau: ${commission.stage})',
                            style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text(
                            'Pour: ${commission.to_compte_id} - De: ${commission.from_compte_id}',
                            style: Theme.of(context).textTheme.bodySmall),
                        trailing: Text(
                            DateFormat('dd/MM/yy')
                                .format(commission.date_earned),
                            style: Theme.of(context).textTheme.bodySmall),
                        onTap: () {/* Navigate to commission detail */},
                      ))
                  .toList(),
              onSurfaceColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper widget for metric cards (reused and adjusted for compactness)
  Widget _buildMetricCard(BuildContext context, String title, String value,
      IconData icon, Color cardColor) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper for displaying recent activity sections
  Widget _buildRecentActivitySection(BuildContext context, String title,
      List<Widget> listTiles, Color onSurfaceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 10),
        listTiles.isEmpty
            ? Text(
                'Aucune donnée récente.',
                style: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
              )
            : Card(
                elevation: 1,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: listTiles,
                ),
              ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Helper for transaction status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approuvé':
        return Colors.green;
      case 'En Attente':
        return Colors.orange;
      case 'Refusé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper for commission status color
  Color _getCommissionStatusColor(String status) {
    switch (status) {
      case 'payé':
        return Colors.green;
      case 'en attente':
        return Colors.orange;
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper for commission status icon
  IconData _getCommissionStatusIcon(String status) {
    switch (status) {
      case 'payé':
        return Icons.check_circle;
      case 'en attente':
        return Icons.hourglass_empty;
      case 'annulé':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}
