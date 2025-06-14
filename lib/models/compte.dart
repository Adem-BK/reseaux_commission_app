// lib/models/compte.dart
// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Compte {
  final String num_cpt;
  final double solde;
  final DateTime date_creation;
  final int stage;
  final String? recruiter_id;
  final String agence;
  final String owner_uid; // NEW FIELD: Link to the Firebase Auth user UID

  Compte({
    required this.num_cpt,
    required this.solde,
    required this.date_creation,
    this.stage = 0,
    this.recruiter_id,
    required this.agence,
    required this.owner_uid, // NEW FIELD
  });

  factory Compte.fromJson(String docId, Map<String, dynamic> json) {
    return Compte(
      num_cpt: docId,
      solde: (json['solde'] as num).toDouble(),
      date_creation: (json['date_creation'] as Timestamp).toDate(),
      stage: json['stage'] as int? ?? 0,
      recruiter_id: json.containsKey('recruiter_id') &&
              json['recruiter_id'] != null &&
              json['recruiter_id'] is String
          ? json['recruiter_id'] as String
          : null,
      agence: json['agence'] as String,
      owner_uid: json['owner_uid'] as String, // NEW FIELD
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'solde': solde,
      'date_creation': Timestamp.fromDate(date_creation),
      'stage': stage,
      'recruiter_id': recruiter_id,
      'agence': agence,
      'owner_uid': owner_uid, // NEW FIELD
    };
  }

  Compte copyWith({
    String? num_cpt,
    double? solde,
    DateTime? date_creation,
    int? stage,
    String? recruiter_id,
    String? agence,
    String? owner_uid, // NEW FIELD
  }) {
    return Compte(
      num_cpt: num_cpt ?? this.num_cpt,
      solde: solde ?? this.solde,
      date_creation: date_creation ?? this.date_creation,
      stage: stage ?? this.stage,
      recruiter_id: recruiter_id ?? this.recruiter_id,
      agence: agence ?? this.agence,
      owner_uid: owner_uid ?? this.owner_uid, // NEW FIELD
    );
  }
}
