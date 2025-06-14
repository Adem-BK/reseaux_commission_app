// lib/views/user_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reseaux_commission_app/models/users.dart'; // Your Users model
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/models/commissions.dart';
import 'package:reseaux_commission_app/models/transactions.dart';
import 'package:intl/intl.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Users? _appUser;
  double _totalCommissionsEarned = 0.0;
  double _totalCommissionsPending = 0.0;
  double _totalCommissionsPaid = 0.0;
  double _totalBalanceAcrossAccounts = 0.0;
  int _totalAccounts = 0;
  List<Transactions> _recentTransactions = [];
  List<Commissions> _recentCommissions = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
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
      _errorMessage = null;
    });

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        _appUser = Users.fromJson(userDoc.data()!);
      } else {
        _errorMessage =
            'Informations utilisateur introuvables. Assurez-vous que votre profil est créé et contient un champ "id" correspondant à votre UID.';
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final comptesSnapshot = await _firestore
          .collection('compte')
          .where('owner_uid', isEqualTo: currentUser.uid)
          .get();
      _totalAccounts = comptesSnapshot.docs.length;

      List<String> userCompteIds = [];
      double tempTotalBalance = 0.0;
      for (var doc in comptesSnapshot.docs) {
        final compte =
            Compte.fromJson(doc.id, doc.data() as Map<String, dynamic>);
        userCompteIds.add(compte.num_cpt);
        tempTotalBalance += compte.solde;
      }
      _totalBalanceAcrossAccounts = tempTotalBalance;

      double tempTotalCommissionsEarned = 0.0;
      double tempTotalCommissionsPending = 0.0;
      double tempTotalCommissionsPaid = 0.0;

      final commissionsSnapshot = await _firestore
          .collection('commissions')
          .where('owner_uid', isEqualTo: currentUser.uid)
          .orderBy('date_earned', descending: true)
          .limit(5)
          .get();

      _recentCommissions = [];
      for (var doc in commissionsSnapshot.docs) {
        final commission =
            Commissions.fromJson(doc.id, doc.data() as Map<String, dynamic>);
        tempTotalCommissionsEarned += commission.amount;
        if (commission.status == 'payé') {
          tempTotalCommissionsPaid += commission.amount;
        } else if (commission.status == 'en attente') {
          tempTotalCommissionsPending += commission.amount;
        }
        _recentCommissions.add(commission);
      }
      _totalCommissionsEarned = tempTotalCommissionsEarned;
      _totalCommissionsPaid = tempTotalCommissionsPaid;
      _totalCommissionsPending = tempTotalCommissionsPending;

      _recentTransactions = [];
      if (userCompteIds.isNotEmpty) {
        final transactionsSnapshot = await _firestore
            .collection('transactions')
            .where('compte_id', whereIn: userCompteIds)
            .orderBy('date_creation', descending: true)
            .limit(5)
            .get();

        for (var doc in transactionsSnapshot.docs) {
          final transaction =
              Transactions.fromJson(doc.id, doc.data() as Map<String, dynamic>);
          _recentTransactions.add(transaction);
        }
      }
    } on FirebaseException catch (e) {
      _errorMessage = 'Erreur de chargement des données: ${e.message}';
      print('Firebase Error: ${e.code} - ${e.message}');
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue: $e';
      print('General Error: $e');
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
                onPressed: _fetchDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(15.0), // Slightly reduced overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue, ${_appUser?.prenom ?? 'Utilisateur'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    // Smaller headline
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
            Text(
              '${_appUser?.role ?? 'Membre'} - ${_appUser?.email ?? FirebaseAuth.instance.currentUser?.email ?? 'Email inconnu'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    // Smaller body text
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 20), // Reduced spacing

            // Metrics Grid
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600
                  ? 3
                  : 2, // More columns for larger screens
              crossAxisSpacing: 10, // Reduced spacing
              mainAxisSpacing: 10, // Reduced spacing
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  context,
                  'Comptes',
                  _totalAccounts.toString(),
                  Icons.account_balance_wallet,
                  primaryColor,
                ),
                _buildMetricCard(
                  context,
                  'Solde Total',
                  '${_totalBalanceAcrossAccounts.toStringAsFixed(2)} TND',
                  Icons.monetization_on,
                  Colors.blueAccent,
                ),
                _buildMetricCard(
                  context,
                  'Commissions Gagnées',
                  '${_totalCommissionsEarned.toStringAsFixed(2)} TND',
                  Icons.currency_exchange,
                  Colors.green,
                ),
                _buildMetricCard(
                  context,
                  'Commissions en Attente',
                  '${_totalCommissionsPending.toStringAsFixed(2)} TND',
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
                _buildMetricCard(
                  context,
                  'Commissions Payées',
                  '${_totalCommissionsPaid.toStringAsFixed(2)} TND',
                  Icons.check_circle_outline,
                  Colors.teal,
                ),
                // You can add one more if it fits consistently
                _buildMetricCard(
                  context, 'Contact', '${_appUser?.tel ?? 'N/A'}',
                  Icons.phone,
                  Colors
                      .grey[700]!, // Example of displaying user info on a card
                ),
              ],
            ),
            const SizedBox(height: 30), // Reduced spacing

            // Recent Transactions Section
            Text(
              'Transactions Récentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    // Smaller headline
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
            const SizedBox(height: 10), // Reduced spacing
            _recentTransactions.isEmpty
                ? Text(
                    'Aucune transaction récente.',
                    style: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _recentTransactions[index];
                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 8), // Smaller margin
                        elevation: 1,
                        child: ListTile(
                          dense: true, // Make ListTile dense
                          leading: Icon(
                            transaction.type == 'Crédit'
                                ? Icons.arrow_circle_up
                                : Icons.arrow_circle_down,
                            color: transaction.type == 'Crédit'
                                ? Colors.green
                                : Colors.red,
                            size: 24, // Smaller icon
                          ),
                          title: Text(
                            '${transaction.type}: ${transaction.amount.toStringAsFixed(2)} TND',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    fontWeight:
                                        FontWeight.bold), // Smaller font
                          ),
                          subtitle: Text(
                            'Compte: ${transaction.compte_id} - ${DateFormat('dd/MM/yyyy').format(transaction.date_creation)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall, // Smaller font
                          ),
                          trailing: Text(transaction.status,
                              style: TextStyle(
                                  color: _getStatusColor(transaction.status),
                                  fontSize: 12)), // Smaller font
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20), // Reduced spacing

            // Recent Commissions Section
            Text(
              'Commissions Récentes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    // Smaller headline
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
            const SizedBox(height: 10), // Reduced spacing
            _recentCommissions.isEmpty
                ? Text(
                    'Aucune commission récente.',
                    style: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentCommissions.length,
                    itemBuilder: (context, index) {
                      final commission = _recentCommissions[index];
                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 8), // Smaller margin
                        elevation: 1,
                        child: ListTile(
                          dense: true, // Make ListTile dense
                          leading: CircleAvatar(
                            radius: 14, // Smaller avatar
                            backgroundColor:
                                _getCommissionStatusColor(commission.status),
                            child: Icon(
                                _getCommissionStatusIcon(commission.status),
                                color: Colors.white,
                                size: 16), // Smaller icon
                          ),
                          title: Text(
                            '${commission.amount.toStringAsFixed(2)} TND (Niveau: ${commission.stage})',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    fontWeight:
                                        FontWeight.bold), // Smaller font
                          ),
                          subtitle: Text(
                            'Pour compte: ${commission.to_compte_id} - De: ${commission.from_compte_id} - ${DateFormat('dd/MM/yyyy').format(commission.date_earned)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall, // Smaller font
                          ),
                          trailing: Text(commission.status,
                              style: TextStyle(
                                  color: _getCommissionStatusColor(
                                      commission.status),
                                  fontSize: 12)), // Smaller font
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 10), // Reduced spacing
          ],
        ),
      ),
    );
  }

  // Helper widget for metric cards - Adjusted for smaller size
  Widget _buildMetricCard(BuildContext context, String title, String value,
      IconData icon, Color cardColor) {
    return Card(
      elevation: 3, // Slightly reduced elevation
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12)), // Slightly smaller border radius
      color: cardColor.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Reduced padding inside card
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.white), // Reduced icon size
            const SizedBox(height: 8), // Reduced spacing
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    // Smaller font
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4), // Reduced spacing
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    // Smaller font
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
