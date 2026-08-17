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
import 'projects_page.dart';

class ProjectsHomePage extends StatefulWidget {
  const ProjectsHomePage({super.key, required this.repository});

  final ContentRepository repository;

  @override
  State<ProjectsHomePage> createState() => _ProjectsHomePageState();
}

class _ProjectsHomePageState extends State<ProjectsHomePage> {
  late Stream<List<ProjectMeta>> _publishedProjectsStream;

  @override
  void initState() {
    super.initState();
    _publishedProjectsStream = widget.repository.publishedProjects();
  }

  @override
  void didUpdateWidget(covariant ProjectsHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _publishedProjectsStream = widget.repository.publishedProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SiteContent.defaults();
    return StreamBuilder<List<ProjectMeta>>(
      stream: _publishedProjectsStream,
      builder: (context, snapshot) {
        final projects = [...(snapshot.data ?? const <ProjectMeta>[])]
          ..sort((a, b) {
            if (a.featured == b.featured) return a.name.compareTo(b.name);
            return a.featured ? -1 : 1;
          });
        return SitePage(
          content: content,
          current: 'home',
          slivers: [
            const SliverToBoxAdapter(
              child: CinematicHero(
                imageUrl:
                    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=2200&q=80',
                kicker: 'Since 1946',
                title: 'Landmark residences, crafted for Ahmedabad.',
                subtitle:
                    'NB Developer builds homes of scale, silence and lasting address — from Science City Road to the city’s most considered neighbourhoods.',
              ),
            ),
            SliverToBoxAdapter(child: _IntroStrip()),
            SliverToBoxAdapter(child: _FeaturedProjects(projects: projects)),
            const SliverToBoxAdapter(child: _LegacyTeaser()),
            const SliverToBoxAdapter(child: _Pillars()),
            SliverToBoxAdapter(child: _HomeEnquire(content: content)),
          ],
        );
      },
    );
  }
}

class _IntroStrip extends StatelessWidget {
  const _IntroStrip();

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    final items = [
      ('1946', 'Year the family enterprise began'),
      ('Ahmedabad', 'Science City Road, Sola'),
      ('Legacy', 'Homes built to be inherited'),
    ];
    return ContentWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Reveal(
          child: Wrap(
            spacing: 28,
            runSpacing: 24,
            children: [
              for (final item in items)
                SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: GoogleFonts.playfairDisplay(
                          color: colors.text,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: GoogleFonts.outfit(color: colors.muted, height: 1.6),
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

class _FeaturedProjects extends StatelessWidget {
  const _FeaturedProjects({required this.projects});

  final List<ProjectMeta> projects;

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return ColoredBox(
      color: SiteScope.of(context).colors.surface,
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                eyebrow: 'Residences',
                title: 'Projects shaped around light, privacy and address.',
              ),
              const SizedBox(height: 36),
              if (projects.isEmpty)
                Text(
                  'Project pages will appear here once published from Admin.',
                  style: GoogleFonts.outfit(color: colors.muted),
                )
              else
                PaginatedProjectList(projects: projects),
              const SizedBox(height: 32),
              LuxuryButton(
                label: 'View all projects',
                filled: false,
                onPressed: () => context.go('/projects'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyTeaser extends StatelessWidget {
  const _LegacyTeaser();

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Reveal(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 880;
              final image = SizedBox(
                height: stacked ? 320 : 460,
                child: const LuxuryImage(
                  url:
                      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1600&q=80',
                ),
              );
              final copy = Padding(
                padding: EdgeInsets.only(
                  left: stacked ? 0 : 56,
                  top: stacked ? 28 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      eyebrow: 'The House of NB',
                      title: 'Eighty years of building with patience.',
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'From a family enterprise that began in 1946 to a contemporary developer of landmark residences, NB Developer continues to work in Ahmedabad with the same regard for land, craft and community.',
                      style: GoogleFonts.outfit(
                        color: colors.muted,
                        fontSize: 17,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 28),
                    LuxuryButton(
                      label: 'Read our legacy',
                      filled: false,
                      onPressed: () => context.go('/legacy'),
                    ),
                  ],
                ),
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [image, copy],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: image),
                  Expanded(child: copy),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Pillars extends StatelessWidget {
  const _Pillars();

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    const items = [
      ('Land', 'Addresses chosen for connectivity, calm and long-term value.'),
      ('Craft', 'Architecture that favours proportion, light and lasting materials.'),
      ('Privacy', 'Low-density living and amenities designed as a private world.'),
      ('Trust', 'RERA-led transparency and a relationship that continues after handover.'),
    ];
    return ColoredBox(
      color: colors.black,
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW WE BUILD'.toUpperCase(),
                style: GoogleFonts.cinzel(
                  color: colors.brass,
                  letterSpacing: 3.2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'A quieter kind of luxury.',
                style: GoogleFonts.playfairDisplay(
                  color: colors.onDark,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 900
                      ? (constraints.maxWidth - 72) / 4
                      : constraints.maxWidth >= 640
                          ? (constraints.maxWidth - 24) / 2
                          : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 36, height: 1.5, color: colors.brass),
                              const SizedBox(height: 16),
                              Text(
                                item.$1,
                                style: GoogleFonts.playfairDisplay(
                                  color: colors.onDark,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.$2,
                                style: GoogleFonts.outfit(
                                  color: colors.onDark.withValues(alpha: 0.72),
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeEnquire extends StatelessWidget {
  const _HomeEnquire({required this.content});

  final SiteContent content;

  @override
  Widget build(BuildContext context) {
    return ContentWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Reveal(
          child: PaperCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 720;
                return Flex(
                  direction: stacked ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: stacked ? 0 : 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            eyebrow: 'Private viewing',
                            title: 'Begin a conversation about your next home.',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            content.address,
                            style: GoogleFonts.outfit(
                              color: SiteScope.of(context).colors.muted,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: stacked ? 0 : 32, height: stacked ? 24 : 0),
                    LuxuryButton(
                      label: 'Enquire now',
                      onPressed: () => context.go('/enquire'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
