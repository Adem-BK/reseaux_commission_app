// lib/views/user/single_compte_page.dart
import 'package:flutter/material.dart';
import 'package:reseaux_commission_app/models/compte.dart';
import 'package:reseaux_commission_app/views/user/compte_commissions_view.dart';
import 'package:reseaux_commission_app/views/user/compte_dashboard_view.dart'; // We'll create this
import 'package:reseaux_commission_app/views/user/compte_transactions_view.dart'; // We'll create this

class SingleComptePage extends StatefulWidget {
  final Compte compte; // The Compte object to display

  const SingleComptePage({super.key, required this.compte});

  @override
  State<SingleComptePage> createState() => _SingleComptePageState();
}

class _SingleComptePageState extends State<SingleComptePage> {
  int _selectedIndex =
      0; // Index of the selected tab in the BottomNavigationBar

  late List<Widget> _widgetOptions; // List of widgets for each tab

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // 0: Home/Dashboard for this specific account
      CompteDashboardView(compte: widget.compte),
      // 1: Transactions for this specific account
      CompteTransactionsView(compte: widget.compte),
      // 2: Commissions for this specific account
      CompteCommissionsView(compte: widget.compte),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Compte: ${widget.compte.num_cpt}'),
        backgroundColor: primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        centerTitle: true,
      ),
      body: Center(
        child: _widgetOptions
            .elementAt(_selectedIndex), // Display the selected widget
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows), // Icon for transactions
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments), // Icon for commissions
            label: 'Commissions',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
        unselectedItemColor: Colors.grey, // Optional: for unselected icons
      ),
    );
  }
}
