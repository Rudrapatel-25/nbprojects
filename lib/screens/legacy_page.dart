import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/project.dart';
import '../models/site_content.dart';
import '../services/content_repository.dart';
import '../widgets/luxury.dart';
import '../widgets/site_chrome.dart';
import 'projects_page.dart';

class LegacyPage extends StatelessWidget {
  const LegacyPage({super.key, required this.repository});

  final ContentRepository repository;

  static const timeline = [
    ('1946', 'The family enterprise takes root in Ahmedabad.'),
    ('Growth', 'Decades of building with land, craft and community in mind.'),
    ('Today', 'NB Developer continues the house with landmark residences such as NB Legacy Tower at Science Park.'),
  ];

  static const leadership = [
    ('Promoters', 'A family-led developer, guided by continuity rather than fashion.'),
    ('Studio', 'Architecture, planning and hospitality brought together around each address.'),
    ('Aftercare', 'A relationship that continues through construction, handover and living.'),
  ];

  @override
  Widget build(BuildContext context) {
    final content = SiteContent.defaults();
    return StreamBuilder<List<ProjectMeta>>(
      stream: repository.publishedProjects(),
      builder: (context, snapshot) {
        final completed = (snapshot.data ?? const <ProjectMeta>[])
            .where((p) => p.status.toLowerCase() == 'completed')
            .toList();
        return SitePage(
          content: content,
          current: 'legacy',
          slivers: [
            const SliverToBoxAdapter(
              child: CinematicHero(
                imageUrl:
                    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=2000&q=80',
                kicker: 'Since 1946',
                title: 'A house built in patience.',
                subtitle:
                    'NB Developer is an Ahmedabad house of residences — still working from Science City Road, still measuring success in how a building is lived in, not only how it is launched.',
                height: 560,
              ),
            ),
            SliverToBoxAdapter(
              child: ContentWrap(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 72),
                  child: Reveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'Timeline',
                          title: 'From a family enterprise to a contemporary developer.',
                        ),
                        const SizedBox(height: 40),
                        for (final item in timeline)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    item.$1,
                                    style: GoogleFonts.cinzel(
                                      color: SiteScope.of(context).colors.brass,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.$2,
                                    style: GoogleFonts.outfit(
                                      color: SiteScope.of(context).colors.muted,
                                      fontSize: 17,
                                      height: 1.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ColoredBox(
                color: SiteScope.of(context).colors.surface,
                child: ContentWrap(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 72),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'Leadership',
                          title: 'Stewardship across generations.',
                        ),
                        const SizedBox(height: 32),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth >= 900
                                ? (constraints.maxWidth - 48) / 3
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                for (final item in leadership)
                                  SizedBox(
                                    width: width,
                                    child: PaperCard(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.$1,
                                            style: GoogleFonts.playfairDisplay(
                                              color: SiteScope.of(context).colors.text,
                                              fontSize: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            item.$2,
                                            style: GoogleFonts.outfit(
                                              color: SiteScope.of(context).colors.muted,
                                              height: 1.7,
                                            ),
                                          ),
                                        ],
                                      ),
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
              ),
            ),
            SliverToBoxAdapter(
              child: ContentWrap(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        eyebrow: 'Recognition',
                        title: 'Awards, press and completed work.',
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Awards, media features and completed portfolio entries can be published from Admin as project pages marked Completed. Names and citations are shown as supplied by NB Developer.',
                        style: GoogleFonts.outfit(
                          color: SiteScope.of(context).colors.muted,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (completed.isEmpty)
                        PaperCard(
                          child: Text(
                            'Completed residences will be listed here once published.',
                            style: GoogleFonts.outfit(
                              color: SiteScope.of(context).colors.muted,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            for (final project in completed)
                              SizedBox(
                                width: 340,
                                child: ProjectCard(project: project),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
