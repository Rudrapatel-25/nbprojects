import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/site_content.dart';
import '../widgets/enquiry_form.dart';
import '../widgets/luxury.dart';
import '../widgets/site_chrome.dart';

class EnquirePage extends StatelessWidget {
  const EnquirePage({
    super.key,
    this.title = 'A private conversation about your next address.',
    this.kicker = 'Enquire',
    this.body =
        'Share a few details and our team will arrange a callback, brochure or site visit. Investor and NRI enquiries are routed separately.',
    this.projectId = 'corporate',
    this.source = 'corporate',
    this.current = 'enquire',
  });

  final String title;
  final String kicker;
  final String body;
  final String projectId;
  final String source;
  final String current;

  @override
  Widget build(BuildContext context) {
    final content = SiteContent.defaults().copyWith(
      enquiryEyebrow: kicker,
      enquiryTitle: title,
      enquiryBody: body,
    );
    return SitePage(
      content: content,
      current: current,
      slivers: [
        SliverToBoxAdapter(
          child: CinematicHero(
            imageUrl:
                'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdbc?auto=format&fit=crop&w=2000&q=80',
            kicker: kicker,
            title: title,
            subtitle: body,
            height: 480,
          ),
        ),
        SliverToBoxAdapter(
          child: ContentWrap(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 900;
                  final form = EnquiryForm(
                    content: content,
                    projectId: projectId,
                    source: source,
                  );
                  final aside = PaperCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit',
                          style: GoogleFonts.playfairDisplay(
                            color: SiteScope.of(context).colors.text,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          content.address,
                          style: GoogleFonts.outfit(
                            color: SiteScope.of(context).colors.muted,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(content.phone, style: GoogleFonts.outfit(
                          color: SiteScope.of(context).colors.text,
                        )),
                        const SizedBox(height: 6),
                        Text(content.email, style: GoogleFonts.outfit(
                          color: SiteScope.of(context).colors.text,
                        )),
                      ],
                    ),
                  );
                  if (stacked) {
                    return Column(
                      children: [
                        form,
                        const SizedBox(height: 24),
                        aside,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: form),
                      const SizedBox(width: 28),
                      Expanded(flex: 4, child: aside),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
