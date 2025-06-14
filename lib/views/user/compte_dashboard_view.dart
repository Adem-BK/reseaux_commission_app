// lib/views/user/compte_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/models/commissions.dart';
import 'package:reseaux_commission_app/models/transactions.dart';

class CompteDashboardView extends StatefulWidget {
  final Compte compte; // Receive the specific account

  const CompteDashboardView({super.key, required this.compte});

  @override
  State<CompteDashboardView> createState() => _CompteDashboardViewState();
}

class _CompteDashboardViewState extends State<CompteDashboardView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;

  double _totalCommissionsEarnedByCompte = 0.0;
  double _totalCommissionsGeneratedByCompte = 0.0;
  double _totalCreditTransactions = 0.0;
  double _totalDebitTransactions = 0.0;
  List<Transactions> _recentTransactions = [];
  List<Commissions> _recentCommissionsEarned = [];

  @override
  void initState() {
    super.initState();
    _fetchCompteDashboardData();
  }

  Future<void> _fetchCompteDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String currentCompteId = widget.compte.num_cpt;

      double tempTotalCommissionsEarned = 0.0;
      final commissionsEarnedSnapshot = await _firestore
          .collection('commissions')
          .where('to_compte_id', isEqualTo: currentCompteId)
          .orderBy('date_earned', descending: true)
          .limit(5)
          .get();

      _recentCommissionsEarned = [];
      for (var doc in commissionsEarnedSnapshot.docs) {
        final commission =
            Commissions.fromJson(doc.id, doc.data() as Map<String, dynamic>);
        if (commission.status == 'payé' || commission.status == 'en attente') {
          tempTotalCommissionsEarned += commission.amount;
        }
        _recentCommissionsEarned.add(commission);
      }
      _totalCommissionsEarnedByCompte = tempTotalCommissionsEarned;

      double tempTotalCommissionsGenerated = 0.0;
      final commissionsGeneratedSnapshot = await _firestore
          .collection('commissions')
          .where('from_compte_id', isEqualTo: currentCompteId)
          .get();
      for (var doc in commissionsGeneratedSnapshot.docs) {
        final commission =
            Commissions.fromJson(doc.id, doc.data() as Map<String, dynamic>);
        tempTotalCommissionsGenerated += commission.amount;
      }
      _totalCommissionsGeneratedByCompte = tempTotalCommissionsGenerated;

      double tempTotalCredit = 0.0;
      double tempTotalDebit = 0.0;
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('compte_id', isEqualTo: currentCompteId)
          .orderBy('date_creation', descending: true)
          .limit(5)
          .get();

      _recentTransactions = [];
      for (var doc in transactionsSnapshot.docs) {
        final transaction =
            Transactions.fromJson(doc.id, doc.data() as Map<String, dynamic>);
        if (transaction.type == 'Crédit') {
          tempTotalCredit += transaction.amount;
        } else if (transaction.type == 'Débit') {
          tempTotalDebit += transaction.amount;
        }
        _recentTransactions.add(transaction);
      }
      _totalCreditTransactions = tempTotalCredit;
      _totalDebitTransactions = tempTotalDebit;
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
                onPressed: _fetchCompteDashboardData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCompteDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(15.0), // Slightly reduced overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu du Compte: ${widget.compte.num_cpt}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    // Smaller headline
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
            Text(
              'Solde actuel: ${widget.compte.solde.toStringAsFixed(2)} TND',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20), // Reduced spacing

            // Metrics Grid for this account
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
                  'Commissions Gagnées',
                  '${_totalCommissionsEarnedByCompte.toStringAsFixed(2)} TND',
                  Icons.paid,
                  Colors.green,
                ),
                _buildMetricCard(
                  context,
                  'Commissions Générées',
                  '${_totalCommissionsGeneratedByCompte.toStringAsFixed(2)} TND',
                  Icons.show_chart,
                  Colors.purple,
                ),
                _buildMetricCard(
                  context,
                  'Total Crédits',
                  '${_totalCreditTransactions.toStringAsFixed(2)} TND',
                  Icons.add_circle,
                  Colors.blueAccent,
                ),
                _buildMetricCard(
                  context,
                  'Total Débits',
                  '${_totalDebitTransactions.toStringAsFixed(2)} TND',
                  Icons.remove_circle,
                  Colors.redAccent,
                ),
                _buildMetricCard(
                  context,
                  'Niveau de Parrainage',
                  '${widget.compte.stage}',
                  Icons.leaderboard,
                  Colors.orange,
                ),
                _buildMetricCard(
                  context,
                  'Agence',
                  widget.compte.agence,
                  Icons.business,
                  Colors.brown,
                ),
              ],
            ),
            const SizedBox(height: 30), // Reduced spacing

            // Recent Transactions Section
            Text(
              'Transactions Récentes pour ce Compte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    // Smaller headline
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
            const SizedBox(height: 10), // Reduced spacing
            _recentTransactions.isEmpty
                ? Text(
                    'Aucune transaction récente pour ce compte.',
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
                            'Status: ${transaction.status} - ${DateFormat('dd/MM/yyyy').format(transaction.date_creation)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall, // Smaller font
                          ),
                          trailing: Text(
                            transaction.status,
                            style: TextStyle(
                                color: _getStatusColor(transaction.status),
                                fontSize: 12), // Smaller font
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20), // Reduced spacing

            // Recent Commissions Earned by this Account Section
            Text(
              'Commissions Récentes Gagnées par ce Compte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    // Smaller headline
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
            const SizedBox(height: 10), // Reduced spacing
            _recentCommissionsEarned.isEmpty
                ? Text(
                    'Aucune commission récente gagnée par ce compte.',
                    style: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentCommissionsEarned.length,
                    itemBuilder: (context, index) {
                      final commission = _recentCommissionsEarned[index];
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
                            'De: ${commission.from_compte_id} - ${DateFormat('dd/MM/yyyy').format(commission.date_earned)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall, // Smaller font
                          ),
                          trailing: Text(
                            commission.status,
                            style: TextStyle(
                                color: _getCommissionStatusColor(
                                    commission.status),
                                fontSize: 12), // Smaller font
                          ),
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
