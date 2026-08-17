import '../models/site_content.dart';

class ProjectMeta {
  const ProjectMeta({
    required this.id,
    required this.slug,
    required this.name,
    required this.location,
    required this.coverImageUrl,
    this.published = false,
    this.featured = false,
    this.status = 'Ongoing',
    this.propertyType = 'Residential',
    this.configurations = '',
  });

  final String id;
  final String slug;
  final String name;
  final String location;
  final String coverImageUrl;
  final bool published;
  final bool featured;
  final String status;
  final String propertyType;
  final String configurations;

  factory ProjectMeta.fromMap(String id, Map<String, dynamic> map) {
    final rawLoc = map['location']?.toString() ?? '';
    final rawStatus = map['status']?.toString() ?? '';
    final rawType = map['propertyType']?.toString() ?? '';
    return ProjectMeta(
      id: id,
      slug: (map['slug'] ?? id).toString(),
      name: (map['name'] ?? 'NB Legacy Tower').toString(),
      location: rawLoc.trim().isNotEmpty ? rawLoc : 'Science Park, Ahmedabad',
      coverImageUrl: (map['coverImageUrl'] ?? '').toString(),
      published: map['published'] != false,
      featured: map['featured'] != false,
      status: rawStatus.trim().isNotEmpty ? rawStatus : 'Ongoing',
      propertyType: rawType.trim().isNotEmpty ? rawType : 'Residential',
      configurations: (map['configurations'] ?? '4 BHK, 5 BHK').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'slug': slug,
        'name': name,
        'location': location,
        'coverImageUrl': coverImageUrl,
        'published': published,
        'featured': featured,
        'status': status,
        'propertyType': propertyType,
        'configurations': configurations,
      };

  factory ProjectMeta.fromContent(
    String slug,
    SiteContent content, {
    bool published = true,
    bool featured = true,
  }) {
    return ProjectMeta(
      id: slug,
      slug: slug,
      name: content.projectName,
      location: content.heroLocation,
      coverImageUrl: content.coverImageUrl.isNotEmpty
          ? content.coverImageUrl
          : content.heroImageUrl,
      published: published,
      featured: featured,
      status: content.status,
      propertyType: content.propertyType,
      configurations: content.configurations,
    );
  }
}

String slugify(String value) {
  final cleaned = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return cleaned.isEmpty ? 'project' : cleaned;
}
