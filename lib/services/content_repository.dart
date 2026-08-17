import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project.dart';
import '../models/site_content.dart';

class InquiryLead {
  const InquiryLead({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.project,
    required this.projectId,
    required this.message,
    required this.createdAt,
    this.status = 'new',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String project;
  final String projectId;
  final String message;
  final DateTime createdAt;
  final String status;
}

class ContentRepository {
  ContentRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const defaultSlug = 'nb-legacy-tower';

  static final Map<String, SiteContent> _memoryDrafts = {
    defaultSlug: SiteContent.defaults(),
  };
  static final Map<String, SiteContent> _memoryPublished = {
    defaultSlug: SiteContent.defaults(),
  };
  static final Map<String, ProjectMeta> _memoryProjects = {
    defaultSlug: ProjectMeta.fromContent(
      defaultSlug,
      SiteContent.defaults(),
      published: true,
      featured: true,
    ),
  };

  User? get user => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  CollectionReference<Map<String, dynamic>> get _projects =>
      _db.collection('projects');

  DocumentReference<Map<String, dynamic>> _project(String id) =>
      _projects.doc(id);

  DocumentReference<Map<String, dynamic>> _draft(String id) =>
      _project(id).collection('cms').doc('draft');

  DocumentReference<Map<String, dynamic>> _published(String id) =>
      _project(id).collection('cms').doc('published');

  Future<void> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> ensureSeeded() async {
    try {
      final existing = await _projects.limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final content = SiteContent.defaults();
      await createProject(
        slug: defaultSlug,
        content: content,
        published: true,
        featured: true,
      );
    } catch (e) {
      print('Seeding error or timeout: $e');
    }
  }

  Future<String> createProject({
    required String slug,
    SiteContent? content,
    bool published = false,
    bool featured = false,
  }) async {
    final data = content ?? SiteContent.defaults().copyWith(projectName: slug);
    final meta = ProjectMeta.fromContent(
      slug,
      data,
      published: published,
      featured: featured,
    );
    _memoryProjects[slug] = meta;
    _memoryDrafts[slug] = data;
    if (published) {
      _memoryPublished[slug] = data;
    }

    try {
      final metaData = meta.toMap()
        ..['published'] = published
        ..['featured'] = featured
        ..['createdAt'] = FieldValue.serverTimestamp();
      await _project(slug).set(metaData);
      await _draft(slug).set(data.toMap());
      if (published) {
        await _published(slug).set(data.toMap());
      }
    } catch (e) {
      print('createProject Firestore error: $e');
    }
    return slug;
  }

  Stream<List<ProjectMeta>> publishedProjects() async* {
    yield _memoryProjects.values.where((p) => p.published).toList();
    try {
      await for (final snapshot in _projects.snapshots()) {
        for (final doc in snapshot.docs) {
          _memoryProjects[doc.id] = ProjectMeta.fromMap(doc.id, doc.data());
        }
        final published = _memoryProjects.values.where((p) => p.published).toList();
        yield published.isNotEmpty ? published : _memoryProjects.values.toList();
      }
    } catch (e) {
      print('publishedProjects stream error: $e');
      yield _memoryProjects.values.where((p) => p.published).toList();
    }
  }

  Stream<List<ProjectMeta>> allProjects() async* {
    yield _memoryProjects.values.toList();
    try {
      await for (final snapshot in _projects.snapshots()) {
        for (final doc in snapshot.docs) {
          _memoryProjects[doc.id] = ProjectMeta.fromMap(doc.id, doc.data());
        }
        yield _memoryProjects.values.toList();
      }
    } catch (e) {
      print('allProjects stream error: $e');
      yield _memoryProjects.values.toList();
    }
  }

  Stream<SiteContent> publishedContent(String slug) async* {
    yield _memoryPublished[slug] ?? SiteContent.defaults();
    try {
      await for (final snapshot in _published(slug).snapshots()) {
        if (snapshot.exists && snapshot.data() != null) {
          final content = SiteContent.fromMap(snapshot.data());
          _memoryPublished[slug] = content;
          yield content;
        } else {
          yield _memoryPublished[slug] ?? SiteContent.defaults();
        }
      }
    } catch (e) {
      print('publishedContent stream error: $e');
      yield _memoryPublished[slug] ?? SiteContent.defaults();
    }
  }

  Future<SiteContent> loadDraft(String slug) async {
    if (_memoryDrafts.containsKey(slug)) {
      return _memoryDrafts[slug]!;
    }
    await ensureSeeded();
    try {
      final snapshot = await _draft(slug).get();
      if (!snapshot.exists || snapshot.data() == null) {
        final published = await _published(slug).get();
        if (!published.exists || published.data() == null) {
          return _memoryDrafts[slug] ?? SiteContent.defaults();
        }
        final content = SiteContent.fromMap(published.data());
        _memoryDrafts[slug] = content;
        return content;
      }
      final content = SiteContent.fromMap(snapshot.data());
      _memoryDrafts[slug] = content;
      return content;
    } catch (e) {
      print('loadDraft error: $e');
      return _memoryDrafts[slug] ?? SiteContent.defaults();
    }
  }

  Map<String, dynamic> _sanitizePayload(Map<String, dynamic> input) {
    dynamic sanitizeValue(dynamic val) {
      if (val is String && val.startsWith('data:image/') && val.length > 250000) {
        return 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80';
      } else if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), sanitizeValue(v)));
      } else if (val is List) {
        return val.map((v) => sanitizeValue(v)).toList();
      }
      return val;
    }
    return sanitizeValue(input) as Map<String, dynamic>;
  }

  Future<void> saveDraft(String slug, SiteContent content) async {
    _memoryDrafts[slug] = content;
    _memoryProjects[slug] = ProjectMeta.fromContent(
      slug,
      content,
      published: true,
      featured: true,
    );

    try {
      final data = _sanitizePayload(content.toMap());
      await _draft(slug).set(data);
      await _project(slug).set({
        'name': content.projectName.isNotEmpty ? content.projectName : 'NB Legacy Tower',
        'location': content.heroLocation.isNotEmpty ? content.heroLocation : 'Science Park, Ahmedabad',
        'coverImageUrl': content.coverImageUrl.isNotEmpty
            ? content.coverImageUrl
            : content.heroImageUrl,
        'slug': slug,
        'published': true,
        'featured': true,
        'status': content.status.isNotEmpty ? content.status : 'Ongoing',
        'propertyType': content.propertyType.isNotEmpty ? content.propertyType : 'Residential',
        'configurations': content.configurations,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('saveDraft Firestore error: $e');
    }
  }

  Future<void> publish(String slug, SiteContent content) async {
    _memoryDrafts[slug] = content;
    _memoryPublished[slug] = content;
    _memoryProjects[slug] = ProjectMeta.fromContent(
      slug,
      content,
      published: true,
      featured: true,
    );

    try {
      final data = _sanitizePayload(content.toMap());
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _draft(slug).set(data);
      await _published(slug).set(data);
      await _project(slug).set({
        'name': content.projectName.isNotEmpty ? content.projectName : 'NB Legacy Tower',
        'location': content.heroLocation.isNotEmpty ? content.heroLocation : 'Science Park, Ahmedabad',
        'coverImageUrl': content.coverImageUrl.isNotEmpty
            ? content.coverImageUrl
            : content.heroImageUrl,
        'published': true,
        'featured': true,
        'slug': slug,
        'status': content.status.isNotEmpty ? content.status : 'Ongoing',
        'propertyType': content.propertyType.isNotEmpty ? content.propertyType : 'Residential',
        'configurations': content.configurations,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('publish Firestore error: $e');
    }
  }

  Future<void> publishProject(String slug, SiteContent content) => publish(slug, content);

  Future<void> setPublished(String slug, bool published) async {
    if (_memoryProjects.containsKey(slug)) {
      final current = _memoryProjects[slug]!;
      _memoryProjects[slug] = ProjectMeta(
        id: current.id,
        slug: current.slug,
        name: current.name,
        location: current.location,
        coverImageUrl: current.coverImageUrl,
        published: published,
        featured: current.featured,
        status: current.status,
        propertyType: current.propertyType,
        configurations: current.configurations,
      );
    }
    try {
      await _project(slug).set({
        'published': published,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('setPublished error: $e');
    }
  }

  Future<void> submitInquiry({
    required String name,
    required String email,
    required String phone,
    required String project,
    required String projectId,
    required String message,
  }) {
    return _db.collection('inquiries').add({
      'name': name,
      'email': email,
      'phone': phone,
      'project': project,
      'projectId': projectId,
      'message': message,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveInquiry({
    required String name,
    required String email,
    required String phone,
    required String project,
    required String projectId,
    required String message,
  }) => submitInquiry(
    name: name,
    email: email,
    phone: phone,
    project: project,
    projectId: projectId,
    message: message,
  );

  Stream<List<InquiryLead>> inquiriesStream({String? projectId}) async* {
    yield <InquiryLead>[];
    try {
      await for (final snapshot in _db
          .collection('inquiries')
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        final leads = snapshot.docs.map((doc) {
          final data = doc.data();
          return InquiryLead(
            id: doc.id,
            name: data['name']?.toString() ?? '',
            email: data['email']?.toString() ?? '',
            phone: data['phone']?.toString() ?? '',
            project: data['project']?.toString() ?? '',
            projectId: data['projectId']?.toString() ?? '',
            message: data['message']?.toString() ?? '',
            status: data['status']?.toString() ?? 'new',
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();
        if (projectId == null || projectId.isEmpty) {
          yield leads;
        } else {
          yield leads
              .where((lead) => lead.projectId == projectId || lead.project == projectId)
              .toList();
        }
      }
    } catch (e) {
      print('inquiriesStream error: $e');
      yield <InquiryLead>[];
    }
  }

  Future<void> updateInquiryStatus(String id, String status) {
    return _db.collection('inquiries').doc(id).update({'status': status});
  }
}
