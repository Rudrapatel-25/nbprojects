import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryLead {
  const InquiryLead({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.configuration = '4 BHK Simplex',
    this.purpose = 'Primary Residence',
    this.message = '',
    this.status = 'new',
    this.whatsappStatus = '-',
    this.whatsappMessageId,
    this.whatsappError,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String configuration;
  final String purpose;
  final String message;
  final String status;
  final String whatsappStatus;
  final String? whatsappMessageId;
  final String? whatsappError;
  final DateTime createdAt;

  factory InquiryLead.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime created;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    return InquiryLead(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      configuration: (data['configuration'] ?? data['project'] ?? '4 BHK Simplex').toString(),
      purpose: (data['purpose'] ?? 'Primary Residence').toString(),
      message: (data['message'] ?? '').toString(),
      status: (data['status'] ?? 'new').toString(),
      whatsappStatus: (data['whatsappStatus'] ?? data['wa_status'] ?? '-').toString(),
      whatsappMessageId: data['whatsappMessageId']?.toString(),
      whatsappError: data['whatsappError']?.toString(),
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'configuration': configuration,
        'purpose': purpose,
        'message': message,
        'status': status,
        'whatsappStatus': whatsappStatus,
        'whatsappMessageId': ?whatsappMessageId,
        'whatsappError': ?whatsappError,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
