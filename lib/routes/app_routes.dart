import 'package:flutter/material.dart';
import 'package:reseaux_commission_app/views/auth/login/login_page.dart';
import 'package:reseaux_commission_app/views/auth/signup/signup_page.dart';
import 'package:reseaux_commission_app/views/contact/contact_page.dart';
import 'package:reseaux_commission_app/views/faq/faq_page.dart';
import 'package:reseaux_commission_app/views/home/home_page.dart';
import 'package:reseaux_commission_app/views/terms/terms_page.dart';
import 'package:reseaux_commission_app/views/user/user_compte.dart';
import 'package:reseaux_commission_app/views/user/user_transactions_view.dart';

// Remove this map if you are using onGenerateRoute in MaterialApp.
// Keeping both can lead to confusion or unintended behavior.
/*
final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => HomePage(),
  '/faq': (context) => const FaqPage(),
  '/terms': (context) => const TermsConditionsPage(),
  '/contact': (context) => const ContactUsPage(),
  '/signup': (context) => const SignupPage(),
  '/login': (context) => const LoginPage(),
};
*/

class AppRoutes {
  // Define your route names as constants for easy access and to prevent typos.
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String faq = '/faq';
  static const String contact = '/contact';
  static const String terms = '/terms';
  static const String userCompte = '/userCompte';
  static const String userTransactions = '/userTransactions'; // New route

  /// This function generates routes based on the provided [RouteSettings].
  /// It's used with `MaterialApp`'s `onGenerateRoute` property.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());
      case faq:
        return MaterialPageRoute(builder: (_) => const FaqPage());
      case contact:
        return MaterialPageRoute(builder: (_) => const ContactUsPage());
      case terms:
        return MaterialPageRoute(builder: (_) => const TermsConditionsPage());
      case userCompte:
        return MaterialPageRoute(builder: (_) => const UserComptePage());
      case userTransactions: // New route case
        return MaterialPageRoute(builder: (_) => const UserTransactionsView());
      default:
        // Return a 404 page for any undefined routes.
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Error: 404 - Page Not Found')),
          ),
        );
    }
  }
}
