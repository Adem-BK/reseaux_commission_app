// lib/models/transactions.dart
// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Transactions {
  final String transaction_id; // This will be the document ID in Firestore
  final String compte_id;
  final double amount;
  final String status;
  final String type;
  final DateTime date_creation;
  final String? receipt_image_url; // Made nullable
  final String? admin_approver_id; // Made nullable
  final DateTime? approval_date; // Made nullable
  final String? qr_code_data; // Made nullable
  final String? notes; // Made nullable
  final bool is_commission_calculated;
  Transactions({
    required this.transaction_id, // 'id' is required as it's the identifier
    required this.compte_id,
    required this.amount,
    this.status = 'En Attente', // Defaulted to 'En Attente'
    required this.type,
    required this.date_creation,
    this.receipt_image_url,
    this.admin_approver_id,
    this.approval_date,
    this.qr_code_data,
    this.notes,
    this.is_commission_calculated = false,
  });

  // fromJson explicitly takes the document ID as its first argument
  factory Transactions.fromJson(String docId, Map<String, dynamic> json) {
    return Transactions(
      transaction_id: docId, // Assign the document ID to the 'id' field
      compte_id: json['compte_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ??
          'En Attente', // Handle default in fromJson too
      type: json['type'] as String,
      date_creation: (json['date_creation'] as Timestamp).toDate(),
      receipt_image_url: json.containsKey('receipt_image_url') &&
              json['receipt_image_url'] != null &&
              json['receipt_image_url'] is String
          ? json['receipt_image_url'] as String
          : null,
      admin_approver_id: json.containsKey('admin_approver_id') &&
              json['admin_approver_id'] != null &&
              json['admin_approver_id'] is String
          ? json['admin_approver_id'] as String
          : null,
      approval_date: json.containsKey('approval_date') &&
              json['approval_date'] != null &&
              json['approval_date'] is Timestamp
          ? (json['approval_date'] as Timestamp).toDate()
          : null,
      qr_code_data: json.containsKey('qr_code_data') &&
              json['qr_code_data'] != null &&
              json['qr_code_data'] is String
          ? json['qr_code_data'] as String
          : null,
      notes: json.containsKey('notes') &&
              json['notes'] != null &&
              json['notes'] is String
          ? json['notes'] as String
          : null,
      is_commission_calculated: json.containsKey('is_commission_calculated') &&
              json['is_commission_calculated'] != null &&
              json['is_commission_calculated'] is bool
          ? json['is_commission_calculated'] as bool
          : false,
    );
  }

  // toMap represents the data to be stored within the document,
  // excluding the document ID itself.
  Map<String, dynamic> toMap() {
    return {
      'compte_id': compte_id,
      'amount': amount,
      'status': status,
      'type': type,
      'date_creation': Timestamp.fromDate(date_creation),
      'receipt_image_url': receipt_image_url,
      'admin_approver_id': admin_approver_id,
      'approval_date':
          approval_date != null ? Timestamp.fromDate(approval_date!) : null,
      'qr_code_data': qr_code_data,
      'notes': notes,
      'is_commission_calculated': is_commission_calculated,
    };
  }

  Transactions copyWith({
    String? transaction_id,
    String? compte_id,
    double? amount,
    String? status,
    String? type,
    DateTime? date_creation,
    String? receipt_image_url,
    String? admin_approver_id,
    DateTime? approval_date,
    String? qr_code_data,
    String? notes,
    bool? is_commission_calculated,
  }) {
    return Transactions(
      transaction_id: transaction_id ?? this.transaction_id,
      compte_id: compte_id ?? this.compte_id,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      type: type ?? this.type,
      date_creation: date_creation ?? this.date_creation,
      receipt_image_url: receipt_image_url ?? this.receipt_image_url,
      admin_approver_id: admin_approver_id ?? this.admin_approver_id,
      approval_date: approval_date ?? this.approval_date,
      qr_code_data: qr_code_data ?? this.qr_code_data,
      notes: notes ?? this.notes,
      is_commission_calculated:
          is_commission_calculated ?? this.is_commission_calculated,
    );
  }
}
