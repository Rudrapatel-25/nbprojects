import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/site_content.dart';
import 'luxury.dart';
import 'luxury_image.dart';

const blackBullMediaUrl = 'https://www.blackbullmedia.in';

class SitePage extends StatelessWidget {
  const SitePage({
    super.key,
    required this.content,
    required this.slivers,
    this.current = 'home',
    this.preview = false,
    this.projectId = '',
    this.showWhatsApp = true,
    this.onCtaTap,
  });

  final SiteContent content;
  final List<Widget> slivers;
  final String current;
  final bool preview;
  final String projectId;
  final bool showWhatsApp;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    final colors = SiteColors(content.palette);
    final compact = MediaQuery.sizeOf(context).width < 980;

    return SiteScope(
      colors: colors,
      content: content,
      projectId: projectId,
      preview: preview,
      child: Scaffold(
        backgroundColor: colors.background,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            if (content.layout.showHeader)
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: colors.background,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0.4,
                toolbarHeight: 78,
                titleSpacing: 0,
                title: SiteNav(
                  current: current,
                  preview: preview,
                  onCtaTap: onCtaTap,
                ),
              ),
            ...slivers,
            if (content.layout.showFooter)
              SliverToBoxAdapter(child: SiteFooter(preview: preview)),
            if (compact)
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: preview || !showWhatsApp || !content.layout.showWhatsApp
            ? null
            : Padding(
                padding: EdgeInsets.only(bottom: compact ? 8 : 28),
                child: FloatingActionButton.extended(
                  backgroundColor: colors.brass,
                  foregroundColor: colors.black,
                  onPressed: () => openWhatsApp(content),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.cinzel(
                      letterSpacing: 1.4,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
        bottomNavigationBar: !compact || preview
            ? null
            : _MobileActionBar(onCtaTap: onCtaTap),
      ),
    );
  }
}

Future<void> openWhatsApp(SiteContent content, {String? message}) async {
  final text = message ??
      (content.whatsappMessage.isNotEmpty 
          ? content.whatsappMessage 
          : 'Hello, I would like to enquire about ${content.projectName}.');
  final uri = Uri.parse(
    'https://wa.me/${content.whatsapp}?text=${Uri.encodeComponent(text)}',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> openExternal(String url) async {
  if (url.trim().isEmpty) return;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

class SiteNav extends StatelessWidget {
  const SiteNav({
    super.key,
    required this.current,
    this.preview = false,
    this.onCtaTap,
  });

  final String current;
  final bool preview;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    final scope = SiteScope.of(context);
    final colors = scope.colors;
    final content = scope.content;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    void handleCta() {
      if (preview) return;
      if (onCtaTap != null) {
        onCtaTap!();
      } else {
        context.go('/');
      }
    }

    return ContentWrap(
      child: SizedBox(
        height: 78,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => preview ? null : context.go('/'),
                  child: _BrandMark(content: content, colors: colors),
                ),
              ),
            ),
            if (wide)
              Align(
                alignment: Alignment.centerRight,
                child: LuxuryButton(
                  label: content.headerCta,
                  onPressed: handleCta,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileActionBar extends StatelessWidget {
  const _MobileActionBar({this.onCtaTap});

  final VoidCallback? onCtaTap;

  Future<void> _call(SiteContent content) async {
    final digits = content.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    await launchUrl(Uri.parse('tel:$digits'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scope = SiteScope.of(context);
    final colors = scope.colors;
    final content = scope.content;

    return Material(
      color: const Color(0xFF141210),
      elevation: 16,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _call(content),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1B17),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.brass.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: colors.brass, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'CALL',
                          style: GoogleFonts.cinzel(
                            color: colors.onDark,
                            fontSize: 12,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () {
                    if (onCtaTap != null) {
                      onCtaTap!();
                    }
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.brass,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: colors.black,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'PRIVATE VIEWING',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cinzel(
                              color: colors.black,
                              fontSize: 12,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.content,
    required this.colors,
    this.isDark = false,
  });

  final SiteContent content;
  final SiteColors colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? colors.onDark : colors.text;
    final subtitleColor = isDark ? colors.onDark.withValues(alpha: 0.75) : colors.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: colors.brass.withValues(alpha: isDark ? 0.6 : 0.4)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: content.logoImageUrl.startsWith('assets/')
              ? Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    content.logoImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Text(
                      content.logoText,
                      style: GoogleFonts.cinzel(
                        color: colors.brass,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : content.logoImageUrl.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: LuxuryImage(
                        url: content.logoImageUrl,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Text(
                      content.logoText,
                      style: GoogleFonts.cinzel(
                        color: colors.brass,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content.brandName.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                color: titleColor,
                fontSize: 13,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Since 1946',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: subtitleColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, this.preview = false});

  final bool preview;

  @override
  Widget build(BuildContext context) {
    final content = SiteScope.of(context).content;
    final colors = SiteScope.of(context).colors;
    final compact = MediaQuery.sizeOf(context).width < 800;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      color: colors.black,
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 56, 0, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: compact ? 0 : 3,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: compact ? 32 : 0, right: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.brandName.toUpperCase(),
                            style: GoogleFonts.cinzel(
                              color: colors.brass,
                              letterSpacing: 3.2,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            content.footerNote,
                            style: GoogleFonts.outfit(
                              color: colors.onDark.withValues(alpha: 0.78),
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            content.address,
                            style: GoogleFonts.outfit(
                              color: colors.onDark.withValues(alpha: 0.7),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: compact ? 0 : 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTACT',
                          style: GoogleFonts.cinzel(
                            color: colors.brass,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(content.phone, style: GoogleFonts.outfit(color: colors.onDark)),
                        const SizedBox(height: 8),
                        Text(content.email, style: GoogleFonts.outfit(color: colors.onDark)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Divider(color: colors.brass.withValues(alpha: 0.25)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    content.copyright,
                    style: GoogleFonts.outfit(
                      color: colors.onDark.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                  /*
                  if (!preview)
                    TextButton(
                      onPressed: () => context.go('/admin'),
                      child: Text(
                        'Admin login',
                        style: GoogleFonts.outfit(
                          color: colors.onDark.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  */
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CinematicHero extends StatelessWidget {
  const CinematicHero({
    super.key,
    required this.imageUrl,
    required this.kicker,
    required this.title,
    this.subtitle = '',
    this.bottom,
    this.height,
  });

  final String imageUrl;
  final String kicker;
  final String title;
  final String subtitle;
  final Widget? bottom;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    final screen = MediaQuery.sizeOf(context);
    final heroHeight = height ?? (screen.height * 0.78).clamp(520.0, 780.0);
    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            LuxuryImage(url: imageUrl, kenBurns: true)
          else
            ColoredBox(color: colors.black),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.black.withValues(alpha: 0.45),
                  colors.black.withValues(alpha: 0.72),
                  colors.black.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
          ContentWrap(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48, top: 32),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker.toUpperCase(),
                        style: GoogleFonts.cinzel(
                          color: const Color(0xFFF0D59A),
                          letterSpacing: 4,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.9),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const GoldLine(width: 88),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          color: colors.onDark,
                          fontSize: screen.width < 700 ? 36 : 58,
                          height: 1.08,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.95),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Text(
                            subtitle,
                            style: GoogleFonts.outfit(
                              color: colors.onDark,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              height: 1.6,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.95),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (bottom != null) ...[
                        const SizedBox(height: 24),
                        bottom!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.light = false});

  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: colors.brass.withValues(alpha: 0.7)),
        color: light ? Colors.transparent : colors.black.withValues(alpha: 0.35),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.cinzel(
          color: light ? colors.brass : colors.onDark,
          fontSize: 10,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}
