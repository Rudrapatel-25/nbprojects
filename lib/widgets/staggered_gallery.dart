import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/site_content.dart';
import 'luxury.dart';
import 'luxury_image.dart';

class StaggeredGallery extends StatelessWidget {
  const StaggeredGallery({
    super.key,
    this.items = const [],
    this.images = const [],
    this.captions = const [
      'Residence',
      'Arrival',
      'Living',
      'Suite',
      'Facade',
      'Amenity',
    ],
  });

  final List<NamedItem> items;
  final List<String> images;
  final List<String> captions;

  static const _heights = [320.0, 460.0, 280.0, 380.0, 240.0, 420.0];

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;

    final List<({String url, String caption})> list = items.isNotEmpty
        ? items
            .where((i) => i.imageUrl.trim().isNotEmpty)
            .map((i) => (
                  url: i.imageUrl,
                  caption: i.title.trim().isNotEmpty ? i.title : 'Gallery',
                ))
            .toList()
        : [
            for (var index = 0; index < images.length; index++)
              if (images[index].trim().isNotEmpty)
                (
                  url: images[index],
                  caption: captions[index % (captions.isEmpty ? 1 : captions.length)],
                )
          ];

    if (list.isEmpty) return const SizedBox.shrink();
    final photos = list.map((e) => e.url).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
                ? 2
                : 1;
        return MasonryGridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return _GalleryTile(
              url: list[index].url,
              index: index,
              height: _heights[index % _heights.length],
              caption: list[index].caption,
              colors: colors,
              onOpen: () => _openLightbox(context, photos, index, colors),
            );
          },
        );
      },
    );
  }

  void _openLightbox(
    BuildContext context,
    List<String> photos,
    int index,
    SiteColors colors,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close gallery',
      barrierColor: colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondary) {
        return _Lightbox(
          photos: photos,
          initialIndex: index,
          colors: colors,
        );
      },
    );
  }
}

class _GalleryTile extends StatefulWidget {
  const _GalleryTile({
    required this.url,
    required this.index,
    required this.height,
    required this.caption,
    required this.colors,
    required this.onOpen,
  });

  final String url;
  final int index;
  final double height;
  final String caption;
  final SiteColors colors;
  final VoidCallback onOpen;

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          height: widget.height,
          transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.brass.withValues(alpha: _hover ? 0.95 : 0.22),
              width: _hover ? 1.4 : 0.8,
            ),
          ),
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _hover ? 1.06 : 1,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  child: LuxuryImage(url: widget.url),
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 240),
                    opacity: _hover ? 1 : 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            colors.black.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    children: [
                      Text(
                        (widget.index + 1).toString().padLeft(2, '0'),
                        style: GoogleFonts.cinzel(
                          color: colors.brass,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.caption.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: colors.onDark,
                            letterSpacing: 1.6,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.open_in_full,
                        size: 14,
                        color: colors.brass.withValues(alpha: _hover ? 1 : 0.6),
                      ),
                    ],
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

class _Lightbox extends StatefulWidget {
  const _Lightbox({
    required this.photos,
    required this.initialIndex,
    required this.colors,
  });

  final List<String> photos;
  final int initialIndex;
  final SiteColors colors;

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late int _index = widget.initialIndex;

  void _step(int delta) {
    setState(() {
      _index = (_index + delta) % widget.photos.length;
      if (_index < 0) _index += widget.photos.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 3,
                child: LuxuryImage(url: widget.photos[_index], fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: colors.onDark),
            ),
          ),
          if (widget.photos.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => _step(-1),
                  icon: Icon(Icons.chevron_left, color: colors.brass, size: 36),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => _step(1),
                  icon: Icon(Icons.chevron_right, color: colors.brass, size: 36),
                ),
              ),
            ),
          ],
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Text(
              '${_index + 1}  /  ${widget.photos.length}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                color: colors.brass,
                letterSpacing: 3,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
