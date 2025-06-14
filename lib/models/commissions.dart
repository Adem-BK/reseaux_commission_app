// lib/models/commissions.dart
// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Commissions {
  final String commissions_id; // Firestore Document ID
  final String
      from_compte_id; // The compte_id of the account whose transaction generated commission
  final String
      to_compte_id; // The compte_id of the account receiving the commission
  final String owner_uid; // UID of the user who owns to_compte_id
  final int
      stage; // The referral level (1, 2, 3, or 4) from to_compte_id to from_compte_id
  final double amount;
  final String transaction_id;
  final double commission_percentage;
  final DateTime date_earned;
  final String
      status; // Status of the commission (e.g., 'en attente', 'payé', 'annulé')

  Commissions({
    required this.commissions_id,
    required this.from_compte_id,
    required this.to_compte_id,
    required this.owner_uid,
    required this.stage,
    required this.amount,
    required this.transaction_id,
    required this.commission_percentage,
    required this.date_earned,
    this.status = 'en attente', // Default status in French
  });

  factory Commissions.fromJson(String docId, Map<String, dynamic> json) {
    return Commissions(
      commissions_id: docId,
      // For required String fields, use as String? ?? '' to provide an empty string default
      from_compte_id: json['from_compte_id'] as String? ?? '',
      to_compte_id: json['to_compte_id'] as String? ?? '',
      owner_uid: json['owner_uid'] as String? ?? '',
      // For required int/double fields, use as num? and provide a 0.0 or 0 default
      stage:
          (json['stage'] as num?)?.toInt() ?? 0, // Default to 0 if null/missing
      amount: (json['amount'] as num?)?.toDouble() ??
          0.0, // Default to 0.0 if null/missing
      transaction_id: json['transaction_id'] as String? ?? '',
      commission_percentage:
          (json['commission_percentage'] as num?)?.toDouble() ?? 0.0,
      // For DateTime, use as Timestamp? and provide DateTime.now() as default
      date_earned:
          (json['date_earned'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: json['status'] as String? ??
          'en attente', // Use French default for existing data
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from_compte_id': from_compte_id,
      'to_compte_id': to_compte_id,
      'owner_uid': owner_uid,
      'stage': stage,
      'amount': amount,
      'transaction_id': transaction_id,
      'commission_percentage': commission_percentage,
      'date_earned': Timestamp.fromDate(date_earned),
      'status': status,
    };
  }

  Commissions copyWith({
    String? commissions_id,
    String? from_compte_id,
    String? to_compte_id,
    String? owner_uid,
    int? stage,
    double? amount,
    String? transaction_id,
    double? commission_percentage,
    DateTime? date_earned,
    String? status,
  }) {
    return Commissions(
      commissions_id: commissions_id ?? this.commissions_id,
      from_compte_id: from_compte_id ?? this.from_compte_id,
      to_compte_id: to_compte_id ?? this.to_compte_id,
      owner_uid: owner_uid ?? this.owner_uid,
      stage: stage ?? this.stage,
      amount: amount ?? this.amount,
      transaction_id: transaction_id ?? this.transaction_id,
      commission_percentage:
          commission_percentage ?? this.commission_percentage,
      date_earned: date_earned ?? this.date_earned,
      status: status ?? this.status,
    );
  }
}
