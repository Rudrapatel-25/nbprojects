import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/project.dart';
import '../models/site_content.dart';
import '../services/content_repository.dart';
import '../widgets/luxury.dart';
import '../widgets/luxury_image.dart';
import '../widgets/site_chrome.dart';
import '../widgets/paginated_project_list.dart';

class ProjectsListingPage extends StatefulWidget {
  const ProjectsListingPage({super.key, required this.repository});

  final ContentRepository repository;

  @override
  State<ProjectsListingPage> createState() => _ProjectsListingPageState();
}

class _ProjectsListingPageState extends State<ProjectsListingPage> {
  String _status = 'All';
  String _type = 'All';
  String _location = 'All';
  late Stream<List<ProjectMeta>> _publishedProjectsStream;

  @override
  void initState() {
    super.initState();
    _publishedProjectsStream = widget.repository.publishedProjects();
  }

  @override
  void didUpdateWidget(covariant ProjectsListingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _publishedProjectsStream = widget.repository.publishedProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SiteContent.defaults();
    final colors = SiteColors(content.palette);
    return StreamBuilder<List<ProjectMeta>>(
      stream: _publishedProjectsStream,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <ProjectMeta>[];
        final locations = [
          'All',
          ...{
            for (final project in all)
              if (project.location.trim().isNotEmpty) project.location,
          },
        ];
        final filtered = all.where((project) {
          final statusOk = _status == 'All' || project.status == _status;
          final typeOk = _type == 'All' || project.propertyType == _type;
          final locationOk = _location == 'All' || project.location == _location;
          return statusOk && typeOk && locationOk;
        }).toList();

        return SitePage(
          content: content,
          current: 'projects',
          slivers: [
            const SliverToBoxAdapter(
              child: CinematicHero(
                imageUrl:
                    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=2000&q=80',
                kicker: 'Portfolio',
                title: 'Residences across Ahmedabad.',
                subtitle:
                    'Filter by status and typology, then open a project microsite for specifications, pricing, plans and a private enquiry.',
                height: 520,
              ),
            ),
            SliverToBoxAdapter(
              child: ContentWrap(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 840;
                      final countBadge = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: colors.brass.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.apartment, size: 16, color: colors.brass),
                            const SizedBox(width: 8),
                            Text(
                              '${filtered.length} ${filtered.length == 1 ? 'PROJECT AVAILABLE' : 'PROJECTS AVAILABLE'}',
                              style: GoogleFonts.cinzel(
                                color: colors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (isWide) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.muted.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _Filter(
                                        label: 'Status',
                                        value: _status,
                                        options: const ['All', 'Ongoing', 'Completed', 'Upcoming'],
                                        onChanged: (v) => setState(() => _status = v),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _Filter(
                                        label: 'Type',
                                        value: _type,
                                        options: const ['All', 'Residential', 'Commercial'],
                                        onChanged: (v) => setState(() => _type = v),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _Filter(
                                        label: 'Location',
                                        value: _location,
                                        options: locations,
                                        onChanged: (v) => setState(() => _location = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              countBadge,
                            ],
                          ),
                        );
                      }

                      // Mobile / Narrow layout
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.muted.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'FILTER PROJECTS',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: colors.brass,
                                  ),
                                ),
                                countBadge,
                              ],
                            ),
                            const SizedBox(height: 16),
                            _Filter(
                              label: 'Status',
                              value: _status,
                              options: const ['All', 'Ongoing', 'Completed', 'Upcoming'],
                              onChanged: (v) => setState(() => _status = v),
                            ),
                            const SizedBox(height: 12),
                            _Filter(
                              label: 'Type',
                              value: _type,
                              options: const ['All', 'Residential', 'Commercial'],
                              onChanged: (v) => setState(() => _type = v),
                            ),
                            const SizedBox(height: 12),
                            _Filter(
                              label: 'Location',
                              value: _location,
                              options: locations,
                              onChanged: (v) => setState(() => _location = v),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ContentWrap(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: filtered.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Text(
                            'No published projects match these filters yet.',
                            style: GoogleFonts.outfit(
                              color: colors.muted,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : PaginatedProjectList(projects: filtered),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : options.first,
      dropdownColor: colors.surface,
      style: GoogleFonts.outfit(color: colors.text, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: colors.brass, fontSize: 14),
        filled: true,
        fillColor: colors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.muted.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.brass.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.brass, width: 1.5),
        ),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option, style: GoogleFonts.outfit(color: colors.text)),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class ProjectCard extends StatefulWidget {
  const ProjectCard({super.key, required this.project});

  final ProjectMeta project;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final colors = SiteScope.of(context).colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go('/p/${project.slug}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(
              color: colors.brass.withValues(alpha: _hover ? 0.7 : 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (project.coverImageUrl.isEmpty)
                      ColoredBox(color: colors.blue.withValues(alpha: 0.18))
                    else
                      LuxuryImage(url: project.coverImageUrl),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: StatusPill(label: project.status),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: GoogleFonts.playfairDisplay(
                        color: colors.text,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        project.location,
                        if (project.configurations.isNotEmpty) project.configurations,
                      ].join('  ·  '),
                      style: GoogleFonts.outfit(color: colors.muted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'VIEW PROJECT',
                      style: GoogleFonts.cinzel(
                        color: colors.brass,
                        letterSpacing: 1.8,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
