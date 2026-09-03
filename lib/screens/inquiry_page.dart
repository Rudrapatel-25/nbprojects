import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/site_content.dart';
import '../services/content_repository.dart';
import '../widgets/enquiry_form.dart';
import '../widgets/luxury.dart';
import '../widgets/luxury_image.dart';
import '../widgets/site_chrome.dart';
import '../widgets/staggered_gallery.dart';

typedef NbLegacyPage = InquiryPage;

class InquiryPage extends StatefulWidget {
  const InquiryPage({
    super.key,
    required this.content,
    this.preview = false,
    this.projectId = '',
    this.scrollToId,
  });

  final SiteContent content;
  final bool preview;
  final String projectId;
  final String? scrollToId;

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final Map<String, GlobalKey> _keys = {};

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      _precacheImages();
    }
  }

  void _precacheImages() {
    final content = widget.content;
    final toCache = <String>[
      if (content.heroImageUrl.isNotEmpty) content.heroImageUrl,
      if (content.aboutImageUrl.isNotEmpty) content.aboutImageUrl,
      if (content.logoImageUrl.isNotEmpty) content.logoImageUrl,
      ...content.gallery.take(4),
    ];
    for (final img in toCache) {
      if (img.startsWith('assets/')) {
        precacheImage(AssetImage(img), context).catchError((_) {});
      }
    }
  }

  @override
  void didUpdateWidget(InquiryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollToId != null && widget.scrollToId != oldWidget.scrollToId) {
      final sectionId = widget.scrollToId == 'plans' ? 'floorPlans' : widget.scrollToId!;
      final key = _keys[sectionId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _scrollToEnquiry() {
    final key = _keys['enquiry'];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SitePage(
      content: widget.content,
      current: 'projects',
      preview: widget.preview,
      projectId: widget.projectId,
      onCtaTap: _scrollToEnquiry,
      slivers: [
        for (final section in widget.content.layout.sections)
          if (section.visible)
            SliverToBoxAdapter(
              key: _keys.putIfAbsent(section.id, () => GlobalKey()),
              child: RepaintBoundary(
                child: Padding(
                  padding: {
                    'hero',
                    'highlights',
                    'living',
                    'connectivity',
                  }.contains(section.id)
                      ? EdgeInsets.zero
                      : EdgeInsets.symmetric(
                          vertical: widget.content.layout.sectionSpacing / 2,
                        ),
                  child: _section(section.id),
                ),
              ),
            ),
      ],
    );
  }

  Widget _section(String id) {
    return switch (id) {
      'hero' => const _HeroSection(),
      'about' => const _AboutSection(),
      'highlights' => const _HighlightsSection(),
      'specs' => const _SpecsSection(),
      'pricing' => const _PricingSection(),
      'amenities' => const _AmenitiesSection(),
      'living' => const _LivingSection(),
      'gallery' => const _GallerySection(),
      'floorPlans' => const _FloorPlansSection(),
      'video' => const _VideoSection(),
      'connectivity' => const _ConnectivitySection(),
      'credibility' => const _CredibilitySection(),
      'brochure' => const _BrochureCtaSection(),
      'updates' => const _UpdatesSection(),
      'faqs' => const _FaqsSection(),
      'enquiry' => const _EnquirySection(),
      'tools' => const _ToolsSection(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    final colors = SiteScope.of(context).colors;
    return CinematicHero(
      imageUrl: content.heroImageUrl,
      kicker: content.heroKicker,
      title: content.heroTitle,
      subtitle: [
        content.heroLocation,
        content.configurations,
        content.heroPossession,
      ].where((e) => e.trim().isNotEmpty).join(' | '),
      height: MediaQuery.sizeOf(context).height * content.layout.heroHeight,
      bottom: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          StatusPill(label: content.status),
          StatusPill(label: content.propertyType),
          for (final offer in content.heroOffers)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF141210),
                border: Border.all(color: colors.brass.withValues(alpha: 0.6), width: 1.2),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    style: GoogleFonts.outfit(
                      color: colors.onDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    offer.subtitle,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFF0D59A),
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 880;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  eyebrow: content.aboutEyebrow,
                  title: content.aboutTitle,
                ),
                const SizedBox(height: 22),
                Text(
                  content.aboutBody,
                  style: GoogleFonts.outfit(
                    color: colors.muted,
                    fontSize: 17,
                    height: 1.85,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final stat in content.stats)
                      SizedBox(
                        width: stacked ? (constraints.maxWidth - 16) / 2 : 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.title,
                              style: GoogleFonts.playfairDisplay(
                                color: colors.text,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stat.subtitle,
                              style: GoogleFonts.outfit(
                                color: colors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (content.heroRera.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'RERA  ${content.heroRera}',
                    style: GoogleFonts.outfit(
                      color: colors.muted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            );
            final image = content.aboutImageUrl.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    height: stacked ? 280 : 460,
                    child: LuxuryImage(url: content.aboutImageUrl),
                  );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, const SizedBox(height: 28), image],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: copy),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: image),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HighlightsSection extends StatelessWidget {
  const _HighlightsSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    final colors = SiteScope.of(context).colors;
    return ColoredBox(
      color: colors.surface,
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 72),
          child: Reveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  eyebrow: content.highlightsEyebrow,
                  title: content.highlightsTitle,
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 980
                        ? (constraints.maxWidth - 48) / 3
                        : constraints.maxWidth >= 640
                            ? (constraints.maxWidth - 24) / 2
                            : constraints.maxWidth;
                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        for (final item in content.highlights)
                          SizedBox(
                            width: width,
                            child: PaperCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(amenityIcon(item.icon), color: colors.brass),
                                  const SizedBox(height: 16),
                                  Text(
                                    item.title,
                                    style: GoogleFonts.playfairDisplay(
                                      color: colors.text,
                                      fontSize: 22,
                                    ),
                                  ),
                                  if (item.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      item.subtitle,
                                      style: GoogleFonts.outfit(
                                        color: colors.muted,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
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
    );
  }
}

class _SpecsSection extends StatelessWidget {
  const _SpecsSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    if (content.specs.isEmpty) return const SizedBox.shrink();
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'Specifications',
              title: 'The essentials, plainly stated.',
            ),
            const SizedBox(height: 28),
            for (final item in content.specs)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.brass.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.cinzel(
                          color: colors.brass,
                          fontSize: 12,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.subtitle,
                        style: GoogleFonts.outfit(
                          color: colors.text,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    if (content.pricing.isEmpty) return const SizedBox.shrink();
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'Pricing',
              title: 'Configurations and starting values.',
            ),
            const SizedBox(height: 28),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.brass.withValues(alpha: 0.35)),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'RESIDENCE',
                        style: GoogleFonts.cinzel(
                          color: colors.brass,
                          fontSize: 11,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'FROM',
                        style: GoogleFonts.cinzel(
                          color: colors.brass,
                          fontSize: 11,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ],
                ),
                for (final item in content.pricing)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          item.title,
                          style: GoogleFonts.playfairDisplay(
                            color: colors.text,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          item.subtitle,
                          style: GoogleFonts.outfit(
                            color: colors.text,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content.reraDisclaimer,
              style: GoogleFonts.outfit(
                color: colors.muted,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmenitiesSection extends StatelessWidget {
  const _AmenitiesSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              eyebrow: content.amenitiesEyebrow,
              title: content.amenitiesTitle,
            ),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine columns based on screen width
                final columns = constraints.maxWidth > 980
                    ? 4
                    : constraints.maxWidth > 600
                        ? 3
                        : 2;
                const spacing = 16.0;
                final width = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final item in content.amenities)
                      Container(
                        width: width,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.brass.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (item.imageUrl.isNotEmpty)
                              SizedBox(
                                height: 160,
                                child: LuxuryImage(url: item.imageUrl),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(amenityIcon(item.icon), color: colors.brass, size: 24),
                                  const SizedBox(height: 12),
                                   Tooltip(
                                    message: item.title,
                                    textStyle: GoogleFonts.outfit(color: colors.onDark, fontSize: 13),
                                    decoration: BoxDecoration(
                                      color: colors.black.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: colors.brass.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      item.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        color: colors.text,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }
}

class _LivingSection extends StatelessWidget {
  const _LivingSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    final colors = SiteScope.of(context).colors;
    return ColoredBox(
      color: colors.surface,
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 72),
          child: Reveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  eyebrow: content.livingEyebrow,
                  title: content.livingTitle,
                ),
              const SizedBox(height: 32),
              for (final item in content.livingItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 800;
                      final image = item.imageUrl.isEmpty
                          ? const SizedBox.shrink()
                          : SizedBox(
                              height: stacked ? 240 : 320,
                              child: LuxuryImage(url: item.imageUrl),
                            );
                      final copy = Padding(
                        padding: EdgeInsets.only(
                          left: stacked ? 0 : 36,
                          top: stacked ? 16 : 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.playfairDisplay(
                                color: colors.text,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.outfit(
                                color: colors.muted,
                                height: 1.8,
                                fontSize: 16,
                              ),
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
                        children: [
                          Expanded(child: image),
                          Expanded(child: copy),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    return ContentWrap(
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'Gallery',
              title: 'Spaces, light and arrival.',
            ),
            const SizedBox(height: 28),
            StaggeredGallery(items: content.galleryItems),
          ],
        ),
      ),
    );
  }
}

class _FloorPlansSection extends StatelessWidget {
  const _FloorPlansSection();

  static const _residences = <_ResidenceOffer>[
    _ResidenceOffer(
      title: '4 BHK Simplex Residence',
      meta: '₹4.5 Cr Onwards • 5,420 Sq. Ft. Approx.',
      imageUrl: 'assets/images/nblegacy/Final_4BHK_Livingroom_View_01.jpg',
      configLabel: '4 BHK Simplex (5,420 Sq. Ft.)',
      features: [
        '4 Bedrooms with En-Suite Bathrooms',
        'Expansive Living & Dining Balconies',
        'Dedicated Househelp Quarter',
        '100% Vastu Compliant Layout',
      ],
    ),
    _ResidenceOffer(
      title: '5 BHK Vertical Bungalow',
      meta: '₹8.1 Cr Onwards • 9,400 Sq. Ft. Approx. (Duplex)',
      imageUrl: 'assets/images/nblegacy/Final_5BHK_Living room_View.jpg',
      configLabel: '5 BHK Vertical Bungalow (9,400 Sq. Ft.)',
      features: [
        'Double-Height Grand Living Room',
        'Private Elevator Access',
        'Master Suite with Sky Terrace',
        'Bungalow Scale with Tower Security',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return ColoredBox(
      color: colors.background,
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 72),
          child: Reveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'EXCLUSIVELY DESIGNED RESIDENCES',
                  title: 'Masterpieces of Scale & Spatial Luxury',
                ),
                const SizedBox(height: 40),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 880;
                    final gap = 28.0;
                    final cardWidth = stacked
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final offer in _residences)
                          SizedBox(
                            width: cardWidth,
                            child: _ResidenceCard(
                              offer: offer,
                              onRequestFloorPlan: () =>
                                  _showFloorPlanRequest(context, offer),
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
    );
  }

  Future<void> _showFloorPlanRequest(
    BuildContext context,
    _ResidenceOffer offer,
  ) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => _FloorPlanRequestDialog(
        initialConfig: offer.configLabel,
      ),
    );
  }
}

class _ResidenceOffer {
  const _ResidenceOffer({
    required this.title,
    required this.meta,
    required this.imageUrl,
    required this.configLabel,
    required this.features,
  });

  final String title;
  final String meta;
  final String imageUrl;
  final String configLabel;
  final List<String> features;
}

class _ResidenceCard extends StatelessWidget {
  const _ResidenceCard({
    required this.offer,
    required this.onRequestFloorPlan,
  });

  final _ResidenceOffer offer;
  final VoidCallback onRequestFloorPlan;

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.brass.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 11,
            child: LuxuryImage(url: offer.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: GoogleFonts.playfairDisplay(
                    color: colors.text,
                    fontSize: 26,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.meta,
                  style: GoogleFonts.outfit(
                    color: colors.brass,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Divider(color: colors.brass.withValues(alpha: 0.35), height: 1),
                const SizedBox(height: 18),
                for (final feature in offer.features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: colors.brass,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.outfit(
                              color: colors.text,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: LuxuryButton(
                    label: 'GET DETAILED FLOOR PLAN',
                    onPressed: onRequestFloorPlan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorPlanRequestDialog extends StatefulWidget {
  const _FloorPlanRequestDialog({required this.initialConfig});

  final String initialConfig;

  @override
  State<_FloorPlanRequestDialog> createState() =>
      _FloorPlanRequestDialogState();
}

class _FloorPlanRequestDialogState extends State<_FloorPlanRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  late String _config;
  bool _sending = false;

  static const _configs = [
    '4 BHK Simplex (5,420 Sq. Ft.)',
    '5 BHK Vertical Bungalow (9,400 Sq. Ft.)',
    'Both Configurations',
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final content = SiteScope.of(context).content;
    final message = StringBuffer()
      ..writeln('📋 *Floor Plan Request* — *${content.projectName}*:')
      ..writeln('')
      ..writeln('👤 *Name:* ${_name.text.trim()}')
      ..writeln('📞 *Mobile:* ${_phone.text.trim()}')
      ..writeln('🏠 *Configuration:* $_config');

    try {
      await ContentRepository().submitInquiry(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        project: _config,
        purpose: 'Floor Plan Request',
        projectId: 'nb-legacy-tower',
        message: message.toString().trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF141210),
            content: Text(
              'Thank you, ${_name.text.trim()}! Your floor plan request for $_config has been received. Our sales desk will call you shortly.',
              style: GoogleFonts.outfit(color: const Color(0xFFF3EEE4)),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send request: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Material(
          color: const Color(0xFF1A1714),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.brass.withValues(alpha: 0.55)),
            ),
            padding: const EdgeInsets.fromLTRB(28, 22, 20, 28),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'FLOOR PLAN REQUEST',
                        style: GoogleFonts.cinzel(
                          color: colors.brass,
                          fontSize: 11,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: colors.onDark.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get the Detailed Floor Plan',
                    style: GoogleFonts.playfairDisplay(
                      color: colors.onDark,
                      fontSize: 28,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _darkField(
                    controller: _name,
                    label: 'Full Name',
                    requiredField: true,
                  ),
                  const SizedBox(height: 18),
                  _darkField(
                    controller: _phone,
                    label: 'Mobile Number',
                    requiredField: true,
                    phone: true,
                  ),
                  const SizedBox(height: 18),
                  _darkDropdown(
                    label: 'Preferred Configuration',
                    value: _config,
                    items: _configs,
                    onChanged: (v) => setState(() => _config = v ?? _config),
                  ),
                  const SizedBox(height: 28),
                  LuxuryButton(
                    label: _sending ? 'SENDING...' : 'GET DETAILED FLOOR PLAN',
                    onPressed: _sending ? () {} : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    bool requiredField = false,
    bool phone = false,
  }) {
    final colors = SiteScope.of(context).colors;
    return TextFormField(
      controller: controller,
      keyboardType: phone ? TextInputType.phone : TextInputType.text,
      style: GoogleFonts.outfit(color: colors.onDark, fontSize: 15),
      validator: requiredField
          ? (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
          color: colors.onDark.withValues(alpha: 0.55),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colors.onDark.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.brass),
        ),
      ),
    );
  }

  Widget _darkDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colors = SiteScope.of(context).colors;
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF241F1B),
      style: GoogleFonts.outfit(color: colors.onDark, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down, color: colors.brass),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
          color: colors.onDark.withValues(alpha: 0.55),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colors.onDark.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.brass),
        ),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: onChanged,
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    if (content.videoUrl.trim().isEmpty) return const SizedBox.shrink();
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: PaperCard(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, color: colors.brass, size: 36),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'Watch the project walkthrough',
                  style: GoogleFonts.playfairDisplay(
                    color: colors.text,
                    fontSize: 24,
                  ),
                ),
              ),
              LuxuryButton(
                label: 'Open video',
                filled: false,
                onPressed: () => launchUrl(
                  Uri.parse(content.videoUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectivitySection extends StatelessWidget {
  const _ConnectivitySection();

  static const _highlightCount = 4;

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    final colors = SiteScope.of(context).colors;
    const projectLocation = LatLng(23.069477029461932, 72.49467098115846);
    final highlights = content.locations.take(_highlightCount).toList();
    final more = content.locations.skip(_highlightCount).toList();

    return ColoredBox(
      color: colors.black,
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 72),
          child: Reveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.connectivityEyebrow.toUpperCase(),
                  style: GoogleFonts.cinzel(
                    color: colors.brass,
                    fontSize: 12,
                    letterSpacing: 3.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  content.connectivityTitle,
                  style: GoogleFonts.playfairDisplay(
                    color: colors.onDark,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 440,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colors.brass.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: projectLocation,
                            initialZoom: 15.8,
                            minZoom: 14.5,
                            maxZoom: 17.0,
                            cameraConstraint: CameraConstraint.contain(
                              bounds: LatLngBounds(
                                const LatLng(23.03, 72.45),
                                const LatLng(23.11, 72.54),
                              ),
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.nbdeveloper.nbprojects',
                              maxZoom: 19,
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: projectLocation,
                                  width: 250,
                                  height: 100,
                                  alignment: Alignment.topCenter,
                                  child: _CustomMapPin(
                                    content: content,
                                    colors: colors,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=23.069477029461932,72.49467098115846',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.brass.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions,
                                    color: colors.brass,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'GET DIRECTIONS',
                                    style: GoogleFonts.cinzel(
                                      color: colors.onDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (highlights.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141210),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.brass.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Wrap(
                      spacing: 28,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        for (final item in highlights)
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${item.subtitle}  ',
                                  style: GoogleFonts.cinzel(
                                    color: colors.brass,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                TextSpan(
                                  text: item.title,
                                  style: GoogleFonts.outfit(
                                    color: colors.onDark.withValues(alpha: 0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (more.isNotEmpty) ...[
                  const SizedBox(height: 36),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 980
                          ? 3
                          : constraints.maxWidth >= 640
                              ? 2
                              : 1;
                      final gap = 24.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final item in more)
                            SizedBox(
                              width: width,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.subtitle,
                                    style: GoogleFonts.cinzel(
                                      color: colors.brass,
                                      fontSize: 13,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.title,
                                    style: GoogleFonts.outfit(
                                      color: colors.onDark,
                                      fontSize: 16,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomMapPin extends StatelessWidget {
  const _CustomMapPin({required this.content, required this.colors});

  final SiteContent content;
  final SiteColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141210),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.brass, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (content.logoImageUrl.isNotEmpty)
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.brass.withValues(alpha: 0.6)),
                    color: Colors.black,
                  ),
                  child: LuxuryImage(url: content.logoImageUrl, fit: BoxFit.contain),
                ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.projectName.toUpperCase(),
                    style: GoogleFonts.cinzel(
                      color: colors.brass,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Science Park, Ahmedabad',
                    style: GoogleFonts.outfit(
                      color: colors.onDark.withValues(alpha: 0.85),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_drop_down,
          color: colors.brass,
          size: 24,
        ),
      ],
    );
  }
}

class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    if (content.updates.isEmpty) return const SizedBox.shrink();
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'Construction updates',
              title: 'Progress, as published.',
            ),
            const SizedBox(height: 24),
            for (final item in content.updates)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.playfairDisplay(
                          color: colors.text,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.outfit(
                          color: colors.muted,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqsSection extends StatelessWidget {
  const _FaqsSection();

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    if (content.faqs.isEmpty) return const SizedBox.shrink();
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              eyebrow: 'Frequently Asked Questions',
              title: 'Everything You Need to Know',
            ),
            const SizedBox(height: 36),
            for (var i = 0; i < content.faqs.length; i++)
              _FaqTile(
                index: i,
                title: content.faqs[i].title,
                subtitle: content.faqs[i].subtitle,
                colors: colors,
              ),
            if (content.brochureUrl.isNotEmpty) ...[
              const SizedBox(height: 24),
              Center(
                child: LuxuryButton(
                  label: 'Download E-Brochure',
                  filled: false,
                  onPressed: () => launchUrl(
                    Uri.parse(content.brochureUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final int index;
  final String title;
  final String subtitle;
  final SiteColors colors;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final indexStr = (widget.index + 1).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _expanded
                  ? colors.brass
                  : _hovered
                      ? colors.brass.withValues(alpha: 0.6)
                      : colors.brass.withValues(alpha: 0.2),
              width: _expanded ? 1.5 : 1.0,
            ),
            boxShadow: _hovered || _expanded
                ? [
                    BoxShadow(
                      color: colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                onExpansionChanged: (val) => setState(() => _expanded = val),
                iconColor: colors.brass,
                collapsedIconColor: colors.text.withValues(alpha: 0.6),
                title: Row(
                  children: [
                    Text(
                      indexStr,
                      style: GoogleFonts.cinzel(
                        color: colors.brass,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.playfairDisplay(
                          color: colors.text,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 18),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: colors.brass.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      widget.subtitle,
                      style: GoogleFonts.outfit(
                        color: colors.muted,
                        fontSize: 16,
                        height: 1.75,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnquirySection extends StatelessWidget {
  const _EnquirySection();

  @override
  Widget build(BuildContext context) {
    final scope = SiteScope.of(context);
    return ContentWrap(
      child: Reveal(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: EnquiryForm(
              content: scope.content,
              projectId: scope.projectId,
              preview: scope.preview,
              source: 'project',
            ),
          ),
        ),
      ),
    );
  }
}

class _CredibilitySection extends StatelessWidget {
  const _CredibilitySection();

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEVELOPER CREDIBILITY',
              style: GoogleFonts.cinzel(
                color: colors.brass,
                fontSize: 12,
                letterSpacing: 3.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NB Developer — Since 1946. A legacy spanning eight decades.',
              style: GoogleFonts.playfairDisplay(
                color: colors.text,
                fontSize: 34,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'With a family enterprise heritage since 1946, NB Developer is committed to quality engineering, Vastu alignment, and structural longevity. Built to be inherited across generations.',
                style: GoogleFonts.outfit(
                  color: colors.muted,
                  fontSize: 16,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 780;
                final gap = 28.0;
                final width = stacked
                    ? constraints.maxWidth
                    : (constraints.maxWidth - gap * 2) / 3;
                const pillars = [
                  ('Since 1946', 'A Legacy Spanning Eight Decades'),
                  ('100% Vastu', 'Compliant Structural Planning'),
                  ('Science Park', 'Ahmedabad Signature Address'),
                ];
                return Wrap(
                  spacing: gap,
                  runSpacing: 28,
                  children: [
                    for (final item in pillars)
                      SizedBox(
                        width: width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: GoogleFonts.playfairDisplay(
                                color: colors.brass,
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.$2,
                              style: GoogleFonts.outfit(
                                color: colors.text,
                                fontSize: 15,
                                height: 1.4,
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
    );
  }
}

class _BrochureCtaSection extends StatelessWidget {
  const _BrochureCtaSection();

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    final content = SiteScope.of(context).content;
    return ContentWrap(
      child: Reveal(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 56),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1714),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.brass.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text(
                'GET THE DETAILED BROCHURE & FLOOR PLANS',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  color: colors.brass,
                  fontSize: 12,
                  letterSpacing: 2.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'Unlock complete architectural specs, unit dimensions, amenity breakdowns, and location analysis.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: colors.onDark,
                    fontSize: 28,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              LuxuryButton(
                label: 'GET DETAILED BROCHURE',
                onPressed: () {
                  if (content.brochureUrl.trim().isNotEmpty) {
                    launchUrl(
                      Uri.parse(content.brochureUrl),
                      mode: LaunchMode.externalApplication,
                    );
                    return;
                  }
                  showDialog<void>(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.72),
                    builder: (_) => const _BrochureRequestDialog(),
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

class _BrochureRequestDialog extends StatefulWidget {
  const _BrochureRequestDialog();

  @override
  State<_BrochureRequestDialog> createState() => _BrochureRequestDialogState();
}

class _BrochureRequestDialogState extends State<_BrochureRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _config = 'Both Configurations';
  bool _sending = false;

  static const _configs = [
    '4 BHK Simplex (5,420 Sq. Ft.)',
    '5 BHK Vertical Bungalow (9,400 Sq. Ft.)',
    'Both Configurations',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final content = SiteScope.of(context).content;
    final message = StringBuffer()
      ..writeln('📋 *Brochure Request* — *${content.projectName}*:')
      ..writeln('')
      ..writeln('👤 *Name:* ${_name.text.trim()}')
      ..writeln('📞 *Mobile:* ${_phone.text.trim()}')
      ..writeln('🏠 *Configuration:* $_config');

    try {
      await ContentRepository().submitInquiry(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        project: _config,
        projectId: 'nb-legacy-tower',
        message: message.toString().trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF141210),
            content: Text(
              'Thank you, ${_name.text.trim()}! Your brochure request for $_config has been received. Our sales desk will call you shortly.',
              style: GoogleFonts.outfit(color: const Color(0xFFF3EEE4)),
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send request: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Material(
          color: const Color(0xFF1A1714),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.brass.withValues(alpha: 0.55)),
            ),
            padding: const EdgeInsets.fromLTRB(28, 22, 20, 28),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'BROCHURE REQUEST',
                        style: GoogleFonts.cinzel(
                          color: colors.brass,
                          fontSize: 11,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: colors.onDark.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get the Detailed Project Brochure',
                    style: GoogleFonts.playfairDisplay(
                      color: colors.onDark,
                      fontSize: 28,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _name,
                    style: GoogleFonts.outfit(color: colors.onDark),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    decoration: _darkDecoration('Full Name'),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.outfit(color: colors.onDark),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    decoration: _darkDecoration('Mobile Number'),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _config,
                    dropdownColor: const Color(0xFF241F1B),
                    style: GoogleFonts.outfit(color: colors.onDark),
                    icon: Icon(Icons.keyboard_arrow_down, color: colors.brass),
                    decoration: _darkDecoration('Preferred Configuration'),
                    items: [
                      for (final item in _configs)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (v) => setState(() => _config = v ?? _config),
                  ),
                  const SizedBox(height: 28),
                  LuxuryButton(
                    label: _sending ? 'SENDING...' : 'GET DETAILED BROCHURE',
                    onPressed: _sending ? () {} : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _darkDecoration(String label) {
    final colors = SiteScope.of(context).colors;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(
        color: colors.onDark.withValues(alpha: 0.55),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.onDark.withValues(alpha: 0.35)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.brass),
      ),
    );
  }
}

class _ToolsSection extends StatefulWidget {
  const _ToolsSection();

  @override
  State<_ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<_ToolsSection> {
  final _loan = TextEditingController(text: '10000000');
  final _rate = TextEditingController(text: '8.5');
  final _years = TextEditingController(text: '20');
  final _area = TextEditingController(text: '1000');
  String _fromUnit = 'sqft';
  String _toUnit = 'sqm';
  String _emi = '';
  String _converted = '';

  static const units = {
    'sqft': 1.0,
    'sqm': 10.7639,
    'sqyd': 9.0,
    'acre': 43560.0,
  };

  @override
  void dispose() {
    _loan.dispose();
    _rate.dispose();
    _years.dispose();
    _area.dispose();
    super.dispose();
  }

  void _calculateEmi() {
    final principal = double.tryParse(_loan.text) ?? 0;
    final annual = double.tryParse(_rate.text) ?? 0;
    final years = double.tryParse(_years.text) ?? 0;
    final n = years * 12;
    final r = annual / 12 / 100;
    if (principal <= 0 || n <= 0) return;
    final emi = r == 0
        ? principal / n
        : principal * r * math.pow(1 + r, n) / (math.pow(1 + r, n) - 1);
    final total = emi * n;
    final interest = total - principal;
    final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    setState(() {
      _emi =
          'Monthly EMI ${inr.format(emi)}\nPrincipal ${inr.format(principal)}\nTotal Interest ${inr.format(interest)}\nTotal Amount ${inr.format(total)}';
    });
  }

  void _convertArea() {
    final value = double.tryParse(_area.text) ?? 0;
    final sqft = value * (units[_fromUnit] ?? 1);
    final result = sqft / (units[_toUnit] ?? 1);
    setState(() => _converted = result.toStringAsFixed(4));
  }

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return ContentWrap(
      child: Reveal(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 840
                ? constraints.maxWidth
                : (constraints.maxWidth - 24) / 2;
            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: width,
                  child: PaperCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home loan EMI',
                          style: GoogleFonts.playfairDisplay(
                            color: colors.text,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _mini(_loan, 'Loan amount'),
                        _mini(_rate, 'Interest rate (p.a.)'),
                        _mini(_years, 'Tenure (years)'),
                        LuxuryButton(label: 'Calculate', onPressed: _calculateEmi),
                        if (_emi.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _emi,
                              style: GoogleFonts.outfit(
                                color: colors.text,
                                height: 1.7,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: PaperCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Area converter',
                          style: GoogleFonts.playfairDisplay(
                            color: colors.text,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _mini(_area, 'Value'),
                        DropdownButtonFormField(
                          initialValue: _fromUnit,
                          dropdownColor: colors.surface,
                          items: [
                            for (final unit in units.keys)
                              DropdownMenuItem(value: unit, child: Text(unit)),
                          ],
                          onChanged: (value) => setState(() => _fromUnit = value!),
                          decoration: const InputDecoration(labelText: 'From'),
                        ),
                        DropdownButtonFormField(
                          initialValue: _toUnit,
                          dropdownColor: colors.surface,
                          items: [
                            for (final unit in units.keys)
                              DropdownMenuItem(value: unit, child: Text(unit)),
                          ],
                          onChanged: (value) => setState(() => _toUnit = value!),
                          decoration: const InputDecoration(labelText: 'To'),
                        ),
                        const SizedBox(height: 12),
                        LuxuryButton(label: 'Convert', onPressed: _convertArea),
                        if (_converted.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _converted,
                              style: GoogleFonts.playfairDisplay(
                                color: colors.brass,
                                fontSize: 28,
                              ),
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
      ),
    );
  }

  Widget _mini(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
