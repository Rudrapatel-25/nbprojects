import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/site_content.dart';
import '../../services/content_repository.dart';
import '../../theme/hex_color.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/luxury.dart';
import '../inquiry_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.projectId});

  final String projectId;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _repo = ContentRepository();
  SiteContent _draft = SiteContent.defaults();
  String _tab = 'preview';
  bool _loading = true;
  bool _saving = false;
  String? _message;

  static const tabs = [
    ('preview', 'Live Preview'),
    ('brand', 'Brand & Colors'),
    ('listing', 'Listing'),
    ('layout', 'Layout'),
    ('hero', 'Hero'),
    ('about', 'About'),
    ('highlights', 'Highlights'),
    ('specs', 'Specifications'),
    ('pricing', 'Pricing'),
    ('amenities', 'Amenities'),
    ('living', 'Living'),
    ('connectivity', 'Connectivity'),
    ('plans', 'Floor Plans'),
    ('faqs', 'FAQs'),
    ('updates', 'Updates'),
    ('enquiry', 'Enquiry Form'),
    ('images', 'Images'),
    ('gallery', 'Gallery'),
    ('leads', 'Inquiries'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final draft = await _repo.loadDraft(widget.projectId);
    if (!mounted) return;
    setState(() {
      _draft = draft;
      _loading = false;
    });
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await _repo.saveDraft(widget.projectId, _draft);
      _toast('Draft saved. Website is unchanged until you press Update.');
    } catch (error) {
      _toast('Could not save draft: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadDemoData() async {
    setState(() => _saving = true);
    try {
      final demo = SiteContent.defaults();
      await _repo.saveDraft(widget.projectId, demo);
      if (!mounted) return;
      setState(() {
        _draft = demo;
      });
      _toast('Demo data loaded from reference site.');
    } catch (error) {
      _toast('Could not load demo data: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      await _repo.publish(widget.projectId, _draft);
      _toast('Website updated. Visitors now see this version.');
    } catch (error) {
      _toast('Could not publish: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    setState(() => _message = message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = SiteColors(_draft.palette);
    if (_loading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 1180;
    return SiteScope(
      colors: colors,
      content: _draft,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.black,
          foregroundColor: colors.onDark,
          title: Text(
            'NB Admin  ·  ${_draft.projectName}',
            style: GoogleFonts.cinzel(fontSize: 16, letterSpacing: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => context.go('/admin'),
              child: Text('All projects', style: TextStyle(color: colors.onDark.withValues(alpha: 0.7))),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _saving ? null : _loadDemoData,
              child: Text('Load Demo Data', style: TextStyle(color: colors.onDark.withValues(alpha: 0.7))),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _saving ? null : _saveDraft,
              child: Text('Save draft', style: TextStyle(color: colors.onDark)),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brass,
                  foregroundColor: colors.black,
                ),
                onPressed: _saving ? null : _publish,
                child: Text(_saving ? 'Updating...' : 'Update website'),
              ),
            ),
            IconButton(
              onPressed: () async {
                await _repo.signOut();
                if (context.mounted) context.go('/admin');
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        drawer: wide
            ? null
            : Drawer(
                child: _AdminNav(
                  colors: colors,
                  current: _tab,
                  repo: _repo,
                  projectId: widget.projectId,
                  onSelect: (id) => setState(() => _tab = id),
                ),
              ),
        body: Row(
          children: [
            if (wide)
              _AdminNav(
                colors: colors,
                current: _tab,
                repo: _repo,
                projectId: widget.projectId,
                onSelect: (id) => setState(() => _tab = id),
              ),
            Expanded(
              flex: wide && _tab != 'preview' && _tab != 'leads' ? 5 : 8,
              child: Material(
                color: colors.surface,
                child: _editor(),
              ),
            ),
            if (wide && _tab != 'preview' && _tab != 'leads')
              Expanded(
                flex: 7,
                child: Material(
                  color: colors.background,
                  child: InquiryPage(
                    content: _draft,
                    preview: true,
                    projectId: widget.projectId,
                    scrollToId: _tab,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _message == null
            ? null
            : Material(
                color: colors.blue,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_message!, textAlign: TextAlign.center),
                ),
              ),
      ),
    );
  }

  Widget _editor() {
    if (_tab == 'preview') {
      return InquiryPage(
        content: _draft,
        preview: true,
        projectId: widget.projectId,
      );
    }
    if (_tab == 'leads') {
      return _LeadsPane(repo: _repo, projectId: widget.projectId);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          key: ValueKey(_tab),
          padding: const EdgeInsets.all(24),
          children: [
        Text(
          tabs.firstWhere((tab) => tab.$1 == _tab).$2,
          style: GoogleFonts.playfairDisplay(fontSize: 28),
        ),
        const SizedBox(height: 18),
        if (_tab == 'brand') _brandEditor(),
        if (_tab == 'listing') _listingEditor(),
        if (_tab == 'layout') _layoutEditor(),
        if (_tab == 'hero') _heroEditor(),
        if (_tab == 'about') _aboutEditor(),
        if (_tab == 'highlights') _listEditor(
          items: _draft.highlights,
          eyebrow: _draft.highlightsEyebrow,
          title: _draft.highlightsTitle,
          onMeta: (eyebrow, title) => setState(() {
            _draft = _draft.copyWith(highlightsEyebrow: eyebrow, highlightsTitle: title);
          }),
          onChanged: (items) => setState(() => _draft = _draft.copyWith(highlights: items)),
        ),
        if (_tab == 'specs') _listEditor(
          items: _draft.specs,
          eyebrow: 'Specifications',
          title: 'Project specifications',
          onMeta: (_, _) {},
          onChanged: (items) => setState(() => _draft = _draft.copyWith(specs: items)),
        ),
        if (_tab == 'pricing') _listEditor(
          items: _draft.pricing,
          eyebrow: 'Pricing',
          title: 'Configurations and prices',
          onMeta: (_, _) {},
          onChanged: (items) => setState(() => _draft = _draft.copyWith(pricing: items)),
        ),
        if (_tab == 'amenities') _listEditor(
          items: _draft.amenities,
          eyebrow: _draft.amenitiesEyebrow,
          title: _draft.amenitiesTitle,
          onMeta: (eyebrow, title) => setState(() {
            _draft = _draft.copyWith(amenitiesEyebrow: eyebrow, amenitiesTitle: title);
          }),
          onChanged: (items) => setState(() => _draft = _draft.copyWith(amenities: items)),
        ),
        if (_tab == 'living') _listEditor(
          items: _draft.livingItems,
          eyebrow: _draft.livingEyebrow,
          title: _draft.livingTitle,
          onMeta: (eyebrow, title) => setState(() {
            _draft = _draft.copyWith(livingEyebrow: eyebrow, livingTitle: title);
          }),
          onChanged: (items) => setState(() => _draft = _draft.copyWith(livingItems: items)),
        ),
        if (_tab == 'connectivity') _listEditor(
          items: _draft.locations,
          eyebrow: _draft.connectivityEyebrow,
          title: _draft.connectivityTitle,
          onMeta: (eyebrow, title) => setState(() {
            _draft = _draft.copyWith(
              connectivityEyebrow: eyebrow,
              connectivityTitle: title,
            );
          }),
          onChanged: (items) => setState(() => _draft = _draft.copyWith(locations: items)),
        ),
        if (_tab == 'plans') _listEditor(
          items: _draft.floorPlans,
          eyebrow: 'Floor plans',
          title: 'Plan titles and images',
          onMeta: (_, _) {},
          onChanged: (items) => setState(() => _draft = _draft.copyWith(floorPlans: items)),
        ),
        if (_tab == 'faqs') _listEditor(
          items: _draft.faqs,
          eyebrow: 'FAQs',
          title: 'Questions and answers',
          onMeta: (_, _) {},
          onChanged: (items) => setState(() => _draft = _draft.copyWith(faqs: items)),
        ),
        if (_tab == 'updates') _listEditor(
          items: _draft.updates,
          eyebrow: 'Construction updates',
          title: 'Progress notes',
          onMeta: (_, _) {},
          onChanged: (items) => setState(() => _draft = _draft.copyWith(updates: items)),
        ),
        if (_tab == 'enquiry') _enquiryEditor(),
        if (_tab == 'images') _imagesEditor(),
        if (_tab == 'gallery') _galleryEditor(),
          ],
        ),
      ),
    );
  }

  Widget _brandEditor() {
    return Column(
      children: [
        _field('Brand name', _draft.brandName, (v) => _draft = _draft.copyWith(brandName: v)),
        _field('Project name', _draft.projectName, (v) => _draft = _draft.copyWith(projectName: v)),
        _field('Tagline', _draft.tagline, (v) => _draft = _draft.copyWith(tagline: v)),
        _field('Logo letters', _draft.logoText, (v) => _draft = _draft.copyWith(logoText: v)),
        ImagePickerField(
          label: 'Logo image',
          value: _draft.logoImageUrl,
          onChanged: (v) => setState(() => _draft = _draft.copyWith(logoImageUrl: v)),
        ),
        _field('Phone', _draft.phone, (v) => _draft = _draft.copyWith(phone: v)),
        _field('Email', _draft.email, (v) => _draft = _draft.copyWith(email: v)),
        _field('WhatsApp number', _draft.whatsapp, (v) => _draft = _draft.copyWith(whatsapp: v)),
        _field('WhatsApp message', _draft.whatsappMessage, (v) => _draft = _draft.copyWith(whatsappMessage: v), lines: 2),
        _field('Header button', _draft.headerCta, (v) => _draft = _draft.copyWith(headerCta: v)),
        _field('Footer note', _draft.footerNote, (v) => _draft = _draft.copyWith(footerNote: v), lines: 3),
        _field('Copyright', _draft.copyright, (v) => _draft = _draft.copyWith(copyright: v)),
        _field('Office address', _draft.address, (v) => _draft = _draft.copyWith(address: v), lines: 3),
        const SizedBox(height: 12),
        _colorField('Black', _draft.palette.black, (v) {
          _draft = _draft.copyWith(palette: _draft.palette.copyWith(black: v));
        }),
        _colorField('Brass gold', _draft.palette.brass, (v) {
          _draft = _draft.copyWith(palette: _draft.palette.copyWith(brass: v));
        }),
        _colorField('Blue', _draft.palette.blue, (v) {
          _draft = _draft.copyWith(palette: _draft.palette.copyWith(blue: v));
        }),
        _colorField('Background', _draft.palette.background, (v) {
          _draft = _draft.copyWith(palette: _draft.palette.copyWith(background: v));
        }),
        _colorField('Surface', _draft.palette.surface, (v) {
          _draft = _draft.copyWith(palette: _draft.palette.copyWith(surface: v));
        }),
        _colorField('Text', _draft.palette.text, (v) {
          _draft = _draft.copyWith(palette: _draft.palette.copyWith(text: v));
        }),
        _colorField('Muted text', _draft.palette.muted, (v) {
          _draft = _draft.copyWith(palette: _draft.palette.copyWith(muted: v));
        }),
      ],
    );
  }

  Widget _listingEditor() {
    return Column(
      children: [
        _field('Status (Ongoing / Completed / Upcoming)', _draft.status, (v) {
          _draft = _draft.copyWith(status: v);
        }),
        _field('Property type (Residential / Commercial)', _draft.propertyType, (v) {
          _draft = _draft.copyWith(propertyType: v);
        }),
        _field('Configurations', _draft.configurations, (v) {
          _draft = _draft.copyWith(configurations: v);
        }),
        _field('Walkthrough video URL', _draft.videoUrl, (v) {
          _draft = _draft.copyWith(videoUrl: v);
        }),
        _field('Brochure URL', _draft.brochureUrl, (v) {
          _draft = _draft.copyWith(brochureUrl: v);
        }),
        _field(
          'RERA disclaimer',
          _draft.reraDisclaimer,
          (v) => _draft = _draft.copyWith(reraDisclaimer: v),
          lines: 4,
        ),
      ],
    );
  }

  Widget _layoutEditor() {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            title: const Text('Show header'),
            value: _draft.layout.showHeader,
            onChanged: (v) => setState(() {
              _draft = _draft.copyWith(layout: _draft.layout.copyWith(showHeader: v));
            }),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            title: const Text('Show footer'),
            value: _draft.layout.showFooter,
            onChanged: (v) => setState(() {
              _draft = _draft.copyWith(layout: _draft.layout.copyWith(showFooter: v));
            }),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            title: const Text('Show floating WhatsApp button'),
            value: _draft.layout.showWhatsApp,
            onChanged: (v) => setState(() {
              _draft = _draft.copyWith(layout: _draft.layout.copyWith(showWhatsApp: v));
            }),
          ),
        ),
        _slider('Section spacing', _draft.layout.sectionSpacing, 40, 140, (v) {
          _draft = _draft.copyWith(layout: _draft.layout.copyWith(sectionSpacing: v));
        }),
        _slider('Content max width', _draft.layout.contentMaxWidth, 860, 1400, (v) {
          _draft = _draft.copyWith(layout: _draft.layout.copyWith(contentMaxWidth: v));
        }),
        _slider('Hero height (screen %)', _draft.layout.heroHeight, 0.6, 1.0, (v) {
          _draft = _draft.copyWith(layout: _draft.layout.copyWith(heroHeight: v));
        }),
        const SizedBox(height: 16),
        const Text('Section order & visibility'),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _draft.layout.sections.length,
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final sections = [..._draft.layout.sections];
              final item = sections.removeAt(oldIndex);
              sections.insert(newIndex, item);
              _draft = _draft.copyWith(layout: _draft.layout.copyWith(sections: sections));
            });
          },
          itemBuilder: (context, index) {
            final section = _draft.layout.sections[index];
            return Material(
              key: ValueKey(section.id),
              color: Colors.transparent,
              child: SwitchListTile(
                title: Text(section.label),
                subtitle: Text(section.id),
                value: section.visible,
                secondary: const Icon(Icons.drag_handle),
                onChanged: (v) {
                  setState(() {
                    final sections = [..._draft.layout.sections];
                    sections[index] = section.copyWith(visible: v);
                    _draft = _draft.copyWith(layout: _draft.layout.copyWith(sections: sections));
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _heroEditor() {
    return Column(
      children: [
        _field('Kicker', _draft.heroKicker, (v) => _draft = _draft.copyWith(heroKicker: v)),
        _field('Headline', _draft.heroTitle, (v) => _draft = _draft.copyWith(heroTitle: v), lines: 2),
        _field('Location', _draft.heroLocation, (v) => _draft = _draft.copyWith(heroLocation: v)),
        _field('Possession', _draft.heroPossession, (v) => _draft = _draft.copyWith(heroPossession: v)),
        _field('RERA', _draft.heroRera, (v) => _draft = _draft.copyWith(heroRera: v), lines: 2),
        ImagePickerField(
          label: 'Hero background image',
          value: _draft.heroImageUrl,
          onChanged: (v) => setState(() => _draft = _draft.copyWith(heroImageUrl: v)),
        ),
        const SizedBox(height: 12),
        _listOnlyEditor(
          items: _draft.heroOffers,
          onChanged: (items) => setState(() => _draft = _draft.copyWith(heroOffers: items)),
        ),
      ],
    );
  }

  Widget _aboutEditor() {
    return Column(
      children: [
        _field('Eyebrow', _draft.aboutEyebrow, (v) => _draft = _draft.copyWith(aboutEyebrow: v)),
        _field('Title', _draft.aboutTitle, (v) => _draft = _draft.copyWith(aboutTitle: v), lines: 2),
        _field('Body', _draft.aboutBody, (v) => _draft = _draft.copyWith(aboutBody: v), lines: 6),
        ImagePickerField(
          label: 'About image',
          value: _draft.aboutImageUrl,
          onChanged: (v) => setState(() => _draft = _draft.copyWith(aboutImageUrl: v)),
        ),
        const SizedBox(height: 12),
        _listOnlyEditor(
          items: _draft.stats,
          onChanged: (items) => setState(() => _draft = _draft.copyWith(stats: items)),
        ),
      ],
    );
  }

  Widget _enquiryEditor() {
    return Column(
      children: [
        _field('Eyebrow', _draft.enquiryEyebrow, (v) => _draft = _draft.copyWith(enquiryEyebrow: v)),
        _field('Title', _draft.enquiryTitle, (v) => _draft = _draft.copyWith(enquiryTitle: v)),
        _field('Body', _draft.enquiryBody, (v) => _draft = _draft.copyWith(enquiryBody: v), lines: 5),
        _field('Button label', _draft.enquiryCta, (v) => _draft = _draft.copyWith(enquiryCta: v)),
        _field(
          'Interested projects (comma separated)',
          _draft.interestedProjects.join(', '),
          (v) => _draft = _draft.copyWith(
            interestedProjects: v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          ),
          lines: 2,
        ),
      ],
    );
  }

  Widget _imagesEditor() {
    return Column(
      children: [
        ImagePickerField(
          label: 'Cover image (home listing card)',
          value: _draft.coverImageUrl,
          onChanged: (v) => setState(() => _draft = _draft.copyWith(coverImageUrl: v)),
        ),
        ImagePickerField(
          label: 'Logo image',
          value: _draft.logoImageUrl,
          onChanged: (v) => setState(() => _draft = _draft.copyWith(logoImageUrl: v)),
        ),
        ImagePickerField(
          label: 'Hero background',
          value: _draft.heroImageUrl,
          onChanged: (v) => setState(() => _draft = _draft.copyWith(heroImageUrl: v)),
        ),
        ImagePickerField(
          label: 'About image',
          value: _draft.aboutImageUrl,
          onChanged: (v) => setState(() => _draft = _draft.copyWith(aboutImageUrl: v)),
        ),
      ],
    );
  }

  Widget _galleryEditor() {
    return _listOnlyEditor(
      items: _draft.galleryItems,
      onChanged: (items) => setState(() => _draft = _draft.copyWith(galleryItems: items)),
    );
  }

  Widget _listEditor({
    required List<NamedItem> items,
    required String eyebrow,
    required String title,
    required void Function(String eyebrow, String title) onMeta,
    required ValueChanged<List<NamedItem>> onChanged,
  }) {
    return Column(
      children: [
        _field('Eyebrow', eyebrow, (v) => onMeta(v, title)),
        _field('Title', title, (v) => onMeta(eyebrow, v), lines: 2),
        _listOnlyEditor(items: items, onChanged: onChanged),
      ],
    );
  }

  Widget _listOnlyEditor({
    required List<NamedItem> items,
    required ValueChanged<List<NamedItem>> onChanged,
  }) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Item ${i + 1}'),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          final next = [...items]..removeAt(i);
                          onChanged(next);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: items[i].title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    onChanged: (v) {
                      final next = [...items];
                      next[i] = items[i].copyWith(title: v);
                      onChanged(next);
                    },
                  ),
                  TextFormField(
                    initialValue: items[i].subtitle,
                    decoration: const InputDecoration(labelText: 'Subtitle'),
                    onChanged: (v) {
                      final next = [...items];
                      next[i] = items[i].copyWith(subtitle: v);
                      onChanged(next);
                    },
                  ),
                  TextFormField(
                    initialValue: items[i].icon,
                    decoration: const InputDecoration(
                      labelText: 'Icon key (pool, spa, home, school...)',
                    ),
                    onChanged: (v) {
                      final next = [...items];
                      next[i] = items[i].copyWith(icon: v);
                      onChanged(next);
                    },
                  ),
                  ImagePickerField(
                    label: 'Item image',
                    value: items[i].imageUrl,
                    onChanged: (v) {
                      final next = [...items];
                      next[i] = items[i].copyWith(imageUrl: v);
                      onChanged(next);
                    },
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => onChanged([
            ...items,
            const NamedItem(title: 'New item', subtitle: ''),
          ]),
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ],
    );
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        maxLines: lines,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) => setState(() => onChanged(v)),
      ),
    );
  }

  Widget _colorField(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: hexColor(value),
              border: Border.all(color: Colors.white24),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: value,
              decoration: InputDecoration(labelText: label),
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  (${value.toStringAsFixed(2)})'),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }
}

class _AdminNav extends StatefulWidget {
  const _AdminNav({
    required this.colors,
    required this.current,
    required this.repo,
    required this.projectId,
    required this.onSelect,
  });

  final SiteColors colors;
  final String current;
  final ContentRepository repo;
  final String projectId;
  final ValueChanged<String> onSelect;

  @override
  State<_AdminNav> createState() => _AdminNavState();
}

class _AdminNavState extends State<_AdminNav> {
  late Stream<List<InquiryLead>> _inquiriesStream;

  @override
  void initState() {
    super.initState();
    _inquiriesStream = widget.repo.inquiriesStream(projectId: widget.projectId);
  }

  @override
  void didUpdateWidget(covariant _AdminNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId || oldWidget.repo != widget.repo) {
      _inquiriesStream = widget.repo.inquiriesStream(projectId: widget.projectId);
    }
  }

  static const categories = [
    (
      'Overview',
      Icons.dashboard_outlined,
      [
        ('preview', 'Live Preview', Icons.visibility_outlined),
        ('leads', 'Inquiries', Icons.people_outline),
      ]
    ),
    (
      'Settings',
      Icons.settings_outlined,
      [
        ('brand', 'Brand & Colors', Icons.palette_outlined),
        ('listing', 'Project Details', Icons.flag_outlined),
        ('layout', 'Page Layout', Icons.view_quilt_outlined),
      ]
    ),
    (
      'Content',
      Icons.article_outlined,
      [
        ('hero', 'Hero Section', Icons.star_outline),
        ('about', 'About', Icons.info_outline),
        ('highlights', 'Highlights', Icons.grid_view),
        ('specs', 'Specifications', Icons.list_alt_outlined),
        ('pricing', 'Pricing', Icons.payments_outlined),
        ('amenities', 'Amenities', Icons.spa_outlined),
        ('living', 'Living Experience', Icons.apartment_outlined),
        ('connectivity', 'Location', Icons.place_outlined),
        ('plans', 'Floor Plans', Icons.layers_outlined),
        ('faqs', 'FAQs', Icons.help_outline),
        ('updates', 'Updates', Icons.construction_outlined),
        ('enquiry', 'Enquiry Form', Icons.mail_outline),
      ]
    ),
    (
      'Media',
      Icons.image_outlined,
      [
        ('images', 'Global Images', Icons.image_outlined),
        ('gallery', 'Image Gallery', Icons.collections_outlined),
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InquiryLead>>(
      stream: _inquiriesStream,
      builder: (context, snapshot) {
        final inquiriesCount = (snapshot.data ?? []).where((i) => i.status == 'new').length;
        return Material(
          color: widget.colors.black,
          child: SizedBox(
            width: 280,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                for (final cat in categories)
                  ExpansionTile(
                    initiallyExpanded: cat.$3.any((item) => item.$1 == widget.current),
                    iconColor: widget.colors.brass,
                    collapsedIconColor: widget.colors.muted,
                    title: Text(
                      cat.$1,
                      style: GoogleFonts.outfit(
                        color: cat.$3.any((item) => item.$1 == widget.current) ? widget.colors.onDark : widget.colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    leading: Icon(
                      cat.$2,
                      color: cat.$3.any((item) => item.$1 == widget.current) ? widget.colors.onDark : widget.colors.muted,
                    ),
                    children: [
                      for (final item in cat.$3)
                        _NavButton(
                          icon: item.$3,
                          label: item.$2,
                          selected: widget.current == item.$1,
                          colors: widget.colors,
                          badgeCount: item.$1 == 'leads' ? inquiriesCount : 0,
                          onTap: () {
                            widget.onSelect(item.$1);
                            final scaffold = Scaffold.maybeOf(context);
                            if (scaffold != null && scaffold.hasDrawer && scaffold.isDrawerOpen) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.colors,
    this.badgeCount = 0,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final SiteColors colors;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.blue.withValues(alpha: 0.45) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: selected ? colors.brass : colors.muted, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: selected ? colors.brass : colors.muted,
                    fontSize: 14,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.brass,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.outfit(
                      color: colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

class _LeadsPane extends StatefulWidget {
  const _LeadsPane({required this.repo, required this.projectId});

  final ContentRepository repo;
  final String projectId;

  @override
  State<_LeadsPane> createState() => _LeadsPaneState();
}

class _LeadsPaneState extends State<_LeadsPane> {
  late Stream<List<InquiryLead>> _inquiriesStream;

  @override
  void initState() {
    super.initState();
    _inquiriesStream = widget.repo.inquiriesStream(projectId: widget.projectId);
  }

  @override
  void didUpdateWidget(covariant _LeadsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId || oldWidget.repo != widget.repo) {
      _inquiriesStream = widget.repo.inquiriesStream(projectId: widget.projectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InquiryLead>>(
      stream: _inquiriesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load inquiries: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final leads = snapshot.data!;
        if (leads.isEmpty) {
          return const Center(child: Text('No inquiries yet.'));
        }
        final format = DateFormat('dd MMM yyyy, hh:mm a');
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: leads.length,
          itemBuilder: (context, index) {
            final lead = leads[index];
            final colors = SiteScope.of(context).colors;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.muted.withValues(alpha: 0.2)),
              ),
              color: colors.background,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lead.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          value: lead.status,
                          underline: const SizedBox(),
                          style: GoogleFonts.outfit(
                            color: lead.status == 'new' ? colors.brass : colors.text,
                            fontWeight: FontWeight.w500,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'new', child: Text('New')),
                            DropdownMenuItem(value: 'contacted', child: Text('Contacted')),
                            DropdownMenuItem(value: 'closed', child: Text('Closed')),
                          ],
                          onChanged: (status) {
                            if (status != null) widget.repo.updateInquiryStatus(lead.id, status);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_outlined, size: 16, color: colors.muted),
                            const SizedBox(width: 8),
                            Text(lead.phone, style: GoogleFonts.outfit(color: colors.text)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email_outlined, size: 16, color: colors.muted),
                            const SizedBox(width: 8),
                            Text(lead.email, style: GoogleFonts.outfit(color: colors.text)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_outlined, size: 16, color: colors.muted),
                            const SizedBox(width: 8),
                            Text(format.format(lead.createdAt), style: GoogleFonts.outfit(color: colors.muted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lead.message,
                        style: GoogleFonts.outfit(
                          color: colors.text,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
