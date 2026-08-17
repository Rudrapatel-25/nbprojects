import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/project.dart';
import '../screens/projects_page.dart' show ProjectCard;
import 'luxury.dart';

class PaginatedProjectList extends StatefulWidget {
  const PaginatedProjectList({super.key, required this.projects});

  final List<ProjectMeta> projects;

  @override
  State<PaginatedProjectList> createState() => _PaginatedProjectListState();
}

class _PaginatedProjectListState extends State<PaginatedProjectList> {
  int _page = 0;

  @override
  void didUpdateWidget(PaginatedProjectList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projects != oldWidget.projects) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    final projects = widget.projects;
    if (projects.isEmpty) {
      return Text(
        'No published projects match these filters yet.',
        style: GoogleFonts.outfit(color: colors.muted),
      );
    }

    final pages = (projects.length / 3).ceil();
    if (_page >= pages) _page = pages - 1;
    if (_page < 0) _page = 0;

    final currentProjects = projects.skip(_page * 3).take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Desktop is typically >= 900 or 980
        final isDesktop = width >= 980;
        final cardWidth = isDesktop ? (width - 48) / 3 : width;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                for (final project in currentProjects)
                  SizedBox(
                    width: cardWidth,
                    child: ProjectCard(project: project),
                  ),
              ],
            ),
            if (pages > 1) ...[
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: _page > 0 ? colors.brass : colors.muted),
                    onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Page ${_page + 1} of $pages',
                    style: GoogleFonts.outfit(color: colors.onDark, fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: _page < pages - 1 ? colors.brass : colors.muted),
                    onPressed: _page < pages - 1 ? () => setState(() => _page++) : null,
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
