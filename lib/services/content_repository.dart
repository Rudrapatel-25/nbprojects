import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/inquiry_lead.dart';

class ContentRepository {
  ContentRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _db => _customFirestore ?? FirebaseFirestore.instance;

  Future<void> submitInquiry({
    required String name,
    required String phone,
    String email = '',
    String project = '4 BHK Simplex',
    String purpose = 'Primary Residence',
    String projectId = 'nb-legacy-tower',
    String message = '',
  }) {
    return _db.collection('inquiries').add({
      'name': name,
      'phone': phone,
      'email': email,
      'project': project,
      'configuration': project,
      'purpose': purpose,
      'projectId': projectId,
      'message': message,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveInquiry({
    required String name,
    required String phone,
    String email = '',
    String project = '4 BHK Simplex',
    String purpose = 'Primary Residence',
    String projectId = 'nb-legacy-tower',
    String message = '',
  }) =>
      submitInquiry(
        name: name,
        phone: phone,
        email: email,
        project: project,
        purpose: purpose,
        projectId: projectId,
        message: message,
      );

  Stream<List<InquiryLead>> inquiriesStream() {
    return _db
        .collection('inquiries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => InquiryLead.fromDoc(doc)).toList();
    });
  }

  Future<void> updateInquiryStatus(String id, String status) {
    return _db.collection('inquiries').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteInquiry(String id) {
    return _db.collection('inquiries').doc(id).delete();
  }

  Future<Map<String, dynamic>?> verifyAdminCredentials(
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return null;
    }

    // Attempt signing in with Firebase Auth in case security rules require an authenticated user
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (_) {}

    // Query Firestore admin collection dynamically
    try {
      final snapshot = await _db.collection('admin').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final docEmail = (data['email'] ?? data['emial'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final docPass = (data['password'] ?? '').toString().trim();
        if (docEmail == cleanEmail && docPass == cleanPassword) {
          final fallbackName = docEmail.contains('@')
              ? docEmail.split('@').first
              : 'Admin';
          return {
            'id': doc.id,
            'displayName': (data['displayName'] ?? fallbackName).toString(),
            'email': docEmail,
          };
        }
      }
    } catch (e) {
      debugPrint('Firestore admin check notice: $e');
      rethrow;
    }

    return null;
  }
}
