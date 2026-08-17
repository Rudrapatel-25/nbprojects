import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/project.dart';
import '../../models/site_content.dart';
import '../../services/content_repository.dart';
import '../../widgets/luxury.dart';
import '../../widgets/luxury_image.dart';

class AdminProjectsPage extends StatefulWidget {
  const AdminProjectsPage({super.key, required this.repository});

  final ContentRepository repository;

  @override
  State<AdminProjectsPage> createState() => _AdminProjectsPageState();
}

class _AdminProjectsPageState extends State<AdminProjectsPage> {
  final _name = TextEditingController();
  bool _creating = false;
  String _errorMsg = '';
  late Stream<List<ProjectMeta>> _allProjectsStream;

  @override
  void initState() {
    super.initState();
    widget.repository.ensureSeeded();
    _allProjectsStream = widget.repository.allProjects();
  }

  @override
  void didUpdateWidget(covariant AdminProjectsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _allProjectsStream = widget.repository.allProjects();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _creating = true;
      _errorMsg = '';
    });
    try {
      final slug = slugify(name);
      await widget.repository.createProject(
        slug: slug,
        content: SiteContent.defaults().copyWith(projectName: name),
      );
      _name.clear();
      if (mounted) context.go('/admin/p/$slug');
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = e.toString());
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SiteColors(SiteContent.defaults().palette);
    return SiteScope(
      colors: colors,
      content: SiteContent.defaults(),
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.black,
          title: Text('Projects', style: GoogleFonts.cinzel(letterSpacing: 1.4)),
          actions: [
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('View site'),
            ),
            IconButton(
              onPressed: () async {
                await widget.repository.signOut();
                if (context.mounted) context.go('/admin');
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: StreamBuilder<List<ProjectMeta>>(
          stream: _allProjectsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Stream Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
            }
            final projects = snapshot.data ?? const <ProjectMeta>[];
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Enquiry pages',
                  style: GoogleFonts.playfairDisplay(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  'Each project has its own enquiry page, images, colors and layout.',
                  style: GoogleFonts.outfit(color: colors.muted),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'New project name',
                        ),
                        onSubmitted: (_) => _create(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _creating ? null : _create,
                      child: Text(_creating ? 'Creating...' : 'Create page'),
                    ),
                  ],
                ),
                if (_errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Error: $_errorMsg', style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 28),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final project in projects)
                      _AdminProjectCard(project: project, repository: widget.repository),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminProjectCard extends StatefulWidget {
  const _AdminProjectCard({required this.project, required this.repository});

  final ProjectMeta project;
  final ContentRepository repository;

  @override
  State<_AdminProjectCard> createState() => _AdminProjectCardState();
}

class _AdminProjectCardState extends State<_AdminProjectCard> {
  late Stream<List<InquiryLead>> _inquiriesStream;

  @override
  void initState() {
    super.initState();
    _inquiriesStream = widget.repository.inquiriesStream(projectId: widget.project.id);
  }

  @override
  void didUpdateWidget(covariant _AdminProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id || oldWidget.repository != widget.repository) {
      _inquiriesStream = widget.repository.inquiriesStream(projectId: widget.project.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: widget.project.coverImageUrl.isEmpty
                  ? const ColoredBox(color: Colors.black26)
                  : LuxuryImage(url: widget.project.coverImageUrl),
            ),
            StreamBuilder<List<InquiryLead>>(
              stream: _inquiriesStream,
              builder: (context, snapshot) {
                final count = (snapshot.data ?? []).where((i) => i.status == 'new').length;
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(widget.project.name)),
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count New',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${widget.project.location}\n/${widget.project.slug}  ·  ${widget.project.published ? 'Published' : 'Draft'}',
                  ),
                  isThreeLine: true,
                );
              },
            ),
            OverflowBar(
              children: [
                TextButton(
                  onPressed: () => context.go('/p/${widget.project.slug}'),
                  child: const Text('Open page'),
                ),
                TextButton(
                  onPressed: () => context.go('/admin/p/${widget.project.id}'),
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () => widget.repository.setPublished(widget.project.id, !widget.project.published),
                  child: Text(widget.project.published ? 'Unpublish' : 'Publish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
