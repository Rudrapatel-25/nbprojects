import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/site_content.dart';
import '../theme/hex_color.dart';

class SiteColors {
  SiteColors(this.palette)
      : brass = hexColor(palette.brass, const Color(0xFFA4844A)),
        blue = hexColor(palette.blue, const Color(0xFF1E3A5F)),
        black = _remap(
          hexColor(palette.black, const Color(0xFF141210)),
          hexColor(palette.background, const Color(0xFFF3EEE4)),
          const Color(0xFF141210),
        ),
        background = _paper(
          hexColor(palette.background, const Color(0xFFF3EEE4)),
          const Color(0xFFF3EEE4),
        ),
        surface = _remap(
          hexColor(palette.surface, const Color(0xFFFFFBF6)),
          hexColor(palette.background, const Color(0xFFF3EEE4)),
          const Color(0xFFFFFBF6),
        ),
        text = _remap(
          hexColor(palette.text, const Color(0xFF1A1714)),
          hexColor(palette.background, const Color(0xFFF3EEE4)),
          const Color(0xFF1A1714),
        ),
        muted = _remap(
          hexColor(palette.muted, const Color(0xFF6D675F)),
          hexColor(palette.background, const Color(0xFFF3EEE4)),
          const Color(0xFF6D675F),
        ),
        onDark = const Color(0xFFF4EFE6);

  final Palette palette;
  final Color black;
  final Color brass;
  final Color blue;
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color onDark;

  static bool _legacyDark(Color background) => background.computeLuminance() < 0.25;

  static Color _paper(Color value, Color ivory) =>
      _legacyDark(value) ? ivory : value;

  static Color _remap(Color value, Color background, Color ivoryToken) =>
      _legacyDark(background) ? ivoryToken : value;
}

class SiteScope extends InheritedWidget {
  const SiteScope({
    super.key,
    required this.colors,
    required this.content,
    this.projectId = '',
    this.preview = false,
    required super.child,
  });

  final SiteColors colors;
  final SiteContent content;
  final String projectId;
  final bool preview;

  static SiteScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SiteScope>();
    if (scope != null) return scope;
    final defaults = SiteContent.defaults();
    return SiteScope(
      content: defaults,
      colors: SiteColors(defaults.palette),
      projectId: 'nblegacy',
      child: const SizedBox.shrink(),
    );
  }

  @override
  bool updateShouldNotify(SiteScope oldWidget) =>
      content != oldWidget.content ||
      colors != oldWidget.colors ||
      projectId != oldWidget.projectId ||
      preview != oldWidget.preview;
}

TextTheme siteTextTheme(SiteColors colors) {
  return TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      color: colors.text,
      fontWeight: FontWeight.w600,
      height: 1.05,
    ),
    headlineMedium: GoogleFonts.cinzel(
      color: colors.text,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
    titleMedium: GoogleFonts.outfit(
      color: colors.text,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.outfit(
      color: colors.muted,
      height: 1.7,
    ),
    bodyMedium: GoogleFonts.outfit(
      color: colors.muted,
      height: 1.6,
    ),
    labelLarge: GoogleFonts.cinzel(
      color: colors.brass,
      letterSpacing: 2.4,
      fontWeight: FontWeight.w600,
    ),
  );
}

class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _played = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    if (_played) return;
    _played = true;
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return VisibilityDetector(
      key: Key('reveal-${identityHashCode(widget)}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.12) _show();
      },
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: RepaintBoundary(child: widget.child),
        ),
      ),
    );
  }
}

class GoldLine extends StatelessWidget {
  const GoldLine({super.key, this.width = 72});

  final double width;

  @override
  Widget build(BuildContext context) {
    final brass = SiteScope.of(context).colors.brass;
    return Container(
      width: width,
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brass.withValues(alpha: 0),
            brass,
            brass.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.center = false,
  });

  final String eyebrow;
  final String title;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.cinzel(
            color: colors.brass,
            fontSize: 12,
            letterSpacing: 3.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        const GoldLine(),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.playfairDisplay(
            color: colors.text,
            fontSize: 36,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class LuxuryButton extends StatefulWidget {
  const LuxuryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  State<LuxuryButton> createState() => _LuxuryButtonState();
}

class _LuxuryButtonState extends State<LuxuryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        child: Material(
          color: widget.filled
              ? (_hover ? colors.brass : colors.blue)
              : Colors.transparent,
          shape: Border.all(color: colors.brass, width: 1),
          child: InkWell(
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              child: Text(
                widget.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  color: widget.filled ? colors.onDark : colors.brass,
                  fontSize: 12,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData amenityIcon(String name) {
  switch (name) {
    case 'apartment':
      return Icons.apartment_outlined;
    case 'villa':
      return Icons.villa_outlined;
    case 'layers':
      return Icons.layers_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'spa':
      return Icons.spa_outlined;
    case 'place':
      return Icons.place_outlined;
    case 'domain':
      return Icons.domain_outlined;
    case 'deck':
      return Icons.deck_outlined;
    case 'meeting_room':
      return Icons.meeting_room_outlined;
    case 'people':
      return Icons.people_outline;
    case 'explore':
      return Icons.explore_outlined;
    case 'tag':
      return Icons.tag;
    case 'celebration':
      return Icons.celebration_outlined;
    case 'work':
      return Icons.work_outline;
    case 'self_improvement':
      return Icons.self_improvement;
    case 'menu_book':
      return Icons.menu_book_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'weekend':
      return Icons.weekend_outlined;
    case 'sports_esports':
      return Icons.sports_esports_outlined;
    case 'sports_tennis':
      return Icons.sports_tennis;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'sports_cricket':
      return Icons.sports_cricket;
    case 'child_care':
      return Icons.child_care_outlined;
    case 'pool':
      return Icons.pool;
    case 'theaters':
      return Icons.theaters_outlined;
    case 'park':
      return Icons.park_outlined;
    case 'golf_course':
      return Icons.golf_course;
    case 'king_bed':
      return Icons.king_bed_outlined;
    case 'auto_awesome':
      return Icons.auto_awesome;
    case 'school':
      return Icons.school_outlined;
    case 'local_hospital':
      return Icons.local_hospital_outlined;
    case 'alt_route':
      return Icons.alt_route;
    case 'science':
      return Icons.science_outlined;
    case 'temple_hindu':
      return Icons.temple_hindu_outlined;
    case 'account_balance':
      return Icons.account_balance_outlined;
    case 'directions_car':
      return Icons.directions_car_outlined;
    default:
      return Icons.star_outline;
  }
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.onDark = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: onDark ? colors.black.withValues(alpha: 0.45) : colors.surface,
        border: Border.all(
          color: colors.brass.withValues(alpha: onDark ? 0.45 : 0.22),
        ),
      ),
      child: child,
    );
  }
}

class ContentWrap extends StatelessWidget {
  const ContentWrap({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final maxWidth = SiteScope.of(context).content.layout.contentMaxWidth;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: child,
        ),
      ),
    );
  }
}
