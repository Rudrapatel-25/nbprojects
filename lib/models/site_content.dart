String _s(Map<String, dynamic> map, String key, String fallback) {
  final value = map[key];
  if (value == null) return fallback;
  return value.toString();
}

bool _b(Map<String, dynamic> map, String key, bool fallback) {
  final value = map[key];
  if (value is bool) return value;
  return fallback;
}

double _d(Map<String, dynamic> map, String key, double fallback) {
  final value = map[key];
  if (value is num) return value.toDouble();
  return fallback;
}

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

class NamedItem {
  const NamedItem({
    required this.title,
    this.subtitle = '',
    this.icon = 'star',
    this.imageUrl = '',
  });

  final String title;
  final String subtitle;
  final String icon;
  final String imageUrl;

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'icon': icon,
        'imageUrl': imageUrl,
      };

  factory NamedItem.fromMap(Map<String, dynamic> map) => NamedItem(
        title: _s(map, 'title', ''),
        subtitle: _s(map, 'subtitle', ''),
        icon: _s(map, 'icon', 'star'),
        imageUrl: _s(map, 'imageUrl', ''),
      );

  NamedItem copyWith({
    String? title,
    String? subtitle,
    String? icon,
    String? imageUrl,
  }) =>
      NamedItem(
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        icon: icon ?? this.icon,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}

class Palette {
  const Palette({
    this.black = '#141210',
    this.brass = '#A4844A',
    this.blue = '#1E3A5F',
    this.background = '#F3EEE4',
    this.surface = '#FFFBF6',
    this.text = '#1A1714',
    this.muted = '#6D675F',
  });

  final String black;
  final String brass;
  final String blue;
  final String background;
  final String surface;
  final String text;
  final String muted;

  Map<String, dynamic> toMap() => {
        'black': black,
        'brass': brass,
        'blue': blue,
        'background': background,
        'surface': surface,
        'text': text,
        'muted': muted,
      };

  factory Palette.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const {};
    return Palette(
      black: _s(data, 'black', '#141210'),
      brass: _s(data, 'brass', '#A4844A'),
      blue: _s(data, 'blue', '#1E3A5F'),
      background: _s(data, 'background', '#F3EEE4'),
      surface: _s(data, 'surface', '#FFFBF6'),
      text: _s(data, 'text', '#1A1714'),
      muted: _s(data, 'muted', '#6D675F'),
    );
  }

  Palette copyWith({
    String? black,
    String? brass,
    String? blue,
    String? background,
    String? surface,
    String? text,
    String? muted,
  }) =>
      Palette(
        black: black ?? this.black,
        brass: brass ?? this.brass,
        blue: blue ?? this.blue,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        text: text ?? this.text,
        muted: muted ?? this.muted,
      );
}

class LayoutSection {
  const LayoutSection({
    required this.id,
    required this.label,
    this.visible = true,
  });

  final String id;
  final String label;
  final bool visible;

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'visible': visible,
      };

  factory LayoutSection.fromMap(Map<String, dynamic> map) => LayoutSection(
        id: _s(map, 'id', ''),
        label: _s(map, 'label', ''),
        visible: _b(map, 'visible', true),
      );

  LayoutSection copyWith({String? id, String? label, bool? visible}) =>
      LayoutSection(
        id: id ?? this.id,
        label: label ?? this.label,
        visible: visible ?? this.visible,
      );
}

class LayoutConfig {
  const LayoutConfig({
    this.showHeader = true,
    this.showFooter = true,
    this.showWhatsApp = true,
    this.sectionSpacing = 88,
    this.contentMaxWidth = 1200,
    this.heroHeight = 0.82,
    this.sections = const [
      LayoutSection(id: 'hero', label: 'Hero'),
      LayoutSection(id: 'about', label: 'Overview'),
      LayoutSection(id: 'highlights', label: 'Why Legacy Tower'),
      LayoutSection(id: 'specs', label: 'Specifications', visible: false),
      LayoutSection(id: 'pricing', label: 'Pricing', visible: false),
      LayoutSection(id: 'living', label: 'Living Experience', visible: false),
      LayoutSection(id: 'gallery', label: 'Gallery'),
      LayoutSection(id: 'floorPlans', label: 'Floor Plans'),
      LayoutSection(id: 'amenities', label: 'Amenities'),
      LayoutSection(id: 'video', label: 'Walkthrough'),
      LayoutSection(id: 'connectivity', label: 'Location'),
      LayoutSection(id: 'credibility', label: 'Developer Credibility'),
      LayoutSection(id: 'brochure', label: 'Brochure CTA'),
      LayoutSection(id: 'updates', label: 'Construction Updates', visible: false),
      LayoutSection(id: 'faqs', label: 'FAQs', visible: false),
      LayoutSection(id: 'enquiry', label: 'Enquiry Form'),
      LayoutSection(id: 'tools', label: 'EMI & Area Tools', visible: false),
    ],
  });

  final bool showHeader;
  final bool showFooter;
  final bool showWhatsApp;
  final double sectionSpacing;
  final double contentMaxWidth;
  final double heroHeight;
  final List<LayoutSection> sections;

  Map<String, dynamic> toMap() => {
        'showHeader': showHeader,
        'showFooter': showFooter,
        'showWhatsApp': showWhatsApp,
        'sectionSpacing': sectionSpacing,
        'contentMaxWidth': contentMaxWidth,
        'heroHeight': heroHeight,
        'sections': sections.map((s) => s.toMap()).toList(),
      };

  factory LayoutConfig.fromMap(Map<String, dynamic>? map) {
    final defaults = const LayoutConfig();
    if (map == null) return defaults;
    final parsed = _maps(map['sections'])
        .map(LayoutSection.fromMap)
        .where((s) => s.id.isNotEmpty)
        .toList();
    final byId = {for (final section in parsed) section.id: section};
    final merged = <LayoutSection>[];
    final seen = <String>{};
    for (final def in defaults.sections) {
      merged.add(byId[def.id] ?? def);
      seen.add(def.id);
    }
    for (final section in parsed) {
      if (!seen.contains(section.id)) merged.add(section);
    }
    return LayoutConfig(
      showHeader: _b(map, 'showHeader', true),
      showFooter: _b(map, 'showFooter', true),
      showWhatsApp: _b(map, 'showWhatsApp', true),
      sectionSpacing: _d(map, 'sectionSpacing', 88),
      contentMaxWidth: _d(map, 'contentMaxWidth', 1200),
      heroHeight: _d(map, 'heroHeight', 0.82),
      sections: merged.isEmpty ? defaults.sections : merged,
    );
  }

  LayoutConfig copyWith({
    bool? showHeader,
    bool? showFooter,
    bool? showWhatsApp,
    double? sectionSpacing,
    double? contentMaxWidth,
    double? heroHeight,
    List<LayoutSection>? sections,
  }) =>
      LayoutConfig(
        showHeader: showHeader ?? this.showHeader,
        showFooter: showFooter ?? this.showFooter,
        showWhatsApp: showWhatsApp ?? this.showWhatsApp,
        sectionSpacing: sectionSpacing ?? this.sectionSpacing,
        contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
        heroHeight: heroHeight ?? this.heroHeight,
        sections: sections ?? this.sections,
      );
}

class SiteContent {
  const SiteContent({
    required this.brandName,
    required this.projectName,
    required this.tagline,
    required this.phone,
    required this.email,
    required this.whatsapp, required this.whatsappMessage,
    required this.logoText,
    this.logoImageUrl = '',
    this.coverImageUrl = '',
    this.heroImageUrl = '',
    this.aboutImageUrl = '',
    this.gallery = const [],
    this.galleryItems = const [],
    required this.palette,
    required this.layout,
    required this.headerCta,
    required this.heroKicker,
    required this.heroTitle,
    required this.heroLocation,
    required this.heroPossession,
    required this.heroRera,
    required this.heroOffers,
    required this.aboutEyebrow,
    required this.aboutTitle,
    required this.aboutBody,
    required this.stats,
    required this.highlightsEyebrow,
    required this.highlightsTitle,
    required this.highlights,
    required this.amenitiesEyebrow,
    required this.amenitiesTitle,
    required this.amenities,
    required this.livingEyebrow,
    required this.livingTitle,
    required this.livingItems,
    required this.connectivityEyebrow,
    required this.connectivityTitle,
    required this.locations,
    required this.enquiryEyebrow,
    required this.enquiryTitle,
    required this.enquiryBody,
    required this.enquiryCta,
    required this.interestedProjects,
    required this.footerNote,
    required this.copyright,
    this.address =
        'FP No. 949/1, NB House, Survey No. 838/1/1, Science City Road, Sola, Ahmedabad, Gujarat 380060',
    this.videoUrl = '',
    this.brochureUrl = '',
    this.reraDisclaimer =
        'All specifications, prices and timelines are as provided by the promoter. Please verify the RERA registration on the Gujarat RERA website before making any purchase decision.',
    this.status = 'Ongoing',
    this.propertyType = 'Residential',
    this.configurations = '4 BHK, 5 BHK',
    this.specs = const [],
    this.pricing = const [],
    this.floorPlans = const [],
    this.faqs = const [],
    this.updates = const [],
  });

  final String brandName;
  final String projectName;
  final String tagline;
  final String phone;
  final String email;
  final String whatsapp; final String whatsappMessage;
  final String logoText;
  final String logoImageUrl;
  final String coverImageUrl;
  final String heroImageUrl;
  final String aboutImageUrl;
  final List<String> gallery;
  final List<NamedItem> galleryItems;
  final Palette palette;
  final LayoutConfig layout;
  final String headerCta;
  final String heroKicker;
  final String heroTitle;
  final String heroLocation;
  final String heroPossession;
  final String heroRera;
  final List<NamedItem> heroOffers;
  final String aboutEyebrow;
  final String aboutTitle;
  final String aboutBody;
  final List<NamedItem> stats;
  final String highlightsEyebrow;
  final String highlightsTitle;
  final List<NamedItem> highlights;
  final String amenitiesEyebrow;
  final String amenitiesTitle;
  final List<NamedItem> amenities;
  final String livingEyebrow;
  final String livingTitle;
  final List<NamedItem> livingItems;
  final String connectivityEyebrow;
  final String connectivityTitle;
  final List<NamedItem> locations;
  final String enquiryEyebrow;
  final String enquiryTitle;
  final String enquiryBody;
  final String enquiryCta;
  final List<String> interestedProjects;
  final String footerNote;
  final String copyright;
  final String address;
  final String videoUrl;
  final String brochureUrl;
  final String reraDisclaimer;
  final String status;
  final String propertyType;
  final String configurations;
  final List<NamedItem> specs;
  final List<NamedItem> pricing;
  final List<NamedItem> floorPlans;
  final List<NamedItem> faqs;
  final List<NamedItem> updates;

  Map<String, dynamic> toMap() => {
        'brandName': brandName,
        'projectName': projectName,
        'tagline': tagline,
        'phone': phone,
        'email': email,
        'whatsapp': whatsapp, 'whatsappMessage': whatsappMessage,
        'logoText': logoText,
        'logoImageUrl': logoImageUrl,
        'coverImageUrl': coverImageUrl,
        'heroImageUrl': heroImageUrl,
        'aboutImageUrl': aboutImageUrl,
        'gallery': galleryItems.map((e) => e.imageUrl).toList(),
        'galleryItems': galleryItems.map((e) => e.toMap()).toList(),
        'palette': palette.toMap(),
        'layout': layout.toMap(),
        'headerCta': headerCta,
        'heroKicker': heroKicker,
        'heroTitle': heroTitle,
        'heroLocation': heroLocation,
        'heroPossession': heroPossession,
        'heroRera': heroRera,
        'heroOffers': heroOffers.map((e) => e.toMap()).toList(),
        'aboutEyebrow': aboutEyebrow,
        'aboutTitle': aboutTitle,
        'aboutBody': aboutBody,
        'stats': stats.map((e) => e.toMap()).toList(),
        'highlightsEyebrow': highlightsEyebrow,
        'highlightsTitle': highlightsTitle,
        'highlights': highlights.map((e) => e.toMap()).toList(),
        'amenitiesEyebrow': amenitiesEyebrow,
        'amenitiesTitle': amenitiesTitle,
        'amenities': amenities.map((e) => e.toMap()).toList(),
        'livingEyebrow': livingEyebrow,
        'livingTitle': livingTitle,
        'livingItems': livingItems.map((e) => e.toMap()).toList(),
        'connectivityEyebrow': connectivityEyebrow,
        'connectivityTitle': connectivityTitle,
        'locations': locations.map((e) => e.toMap()).toList(),
        'enquiryEyebrow': enquiryEyebrow,
        'enquiryTitle': enquiryTitle,
        'enquiryBody': enquiryBody,
        'enquiryCta': enquiryCta,
        'interestedProjects': interestedProjects,
        'footerNote': footerNote,
        'copyright': copyright,
        'address': address,
        'videoUrl': videoUrl,
        'brochureUrl': brochureUrl,
        'reraDisclaimer': reraDisclaimer,
        'status': status,
        'propertyType': propertyType,
        'configurations': configurations,
        'specs': specs.map((e) => e.toMap()).toList(),
        'pricing': pricing.map((e) => e.toMap()).toList(),
        'floorPlans': floorPlans.map((e) => e.toMap()).toList(),
        'faqs': faqs.map((e) => e.toMap()).toList(),
        'updates': updates.map((e) => e.toMap()).toList(),
      };

  factory SiteContent.fromMap(Map<String, dynamic>? map) {
    final defaults = SiteContent.defaults();
    if (map == null) return defaults;
    List<NamedItem> items(String key, List<NamedItem> fallback) {
      final parsed = _maps(map[key]).map(NamedItem.fromMap).toList();
      return parsed.isEmpty ? fallback : parsed;
    }

    return SiteContent(
      brandName: _s(map, 'brandName', defaults.brandName),
      projectName: _s(map, 'projectName', defaults.projectName),
      tagline: _s(map, 'tagline', defaults.tagline),
      phone: _s(map, 'phone', defaults.phone),
      email: _s(map, 'email', defaults.email),
      whatsapp: _s(map, 'whatsapp', defaults.whatsapp), whatsappMessage: _s(map, 'whatsappMessage', defaults.whatsappMessage),
      logoText: _s(map, 'logoText', defaults.logoText),
      logoImageUrl: _s(map, 'logoImageUrl', defaults.logoImageUrl),
      coverImageUrl: _s(map, 'coverImageUrl', defaults.coverImageUrl),
      heroImageUrl: _s(map, 'heroImageUrl', defaults.heroImageUrl),
      aboutImageUrl: _s(map, 'aboutImageUrl', defaults.aboutImageUrl),
      gallery: (map['gallery'] is List)
          ? (map['gallery'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : defaults.gallery,
      galleryItems: () {
        final parsed = _maps(map['galleryItems']).map(NamedItem.fromMap).toList();
        if (parsed.isNotEmpty) return parsed;
        final rawGallery = (map['gallery'] is List)
            ? (map['gallery'] as List)
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList()
            : defaults.gallery;
        const defaultTags = ['Residence', 'Arrival', 'Living', 'Suite', 'Facade', 'Amenity'];
        return [
          for (var i = 0; i < rawGallery.length; i++)
            NamedItem(
              title: defaultTags[i % defaultTags.length],
              imageUrl: rawGallery[i],
            ),
        ];
      }(),
      palette: Palette.fromMap(
        map['palette'] is Map
            ? Map<String, dynamic>.from(map['palette'] as Map)
            : null,
      ),
      layout: LayoutConfig.fromMap(
        map['layout'] is Map
            ? Map<String, dynamic>.from(map['layout'] as Map)
            : null,
      ),
      headerCta: _s(map, 'headerCta', defaults.headerCta),
      heroKicker: _s(map, 'heroKicker', defaults.heroKicker),
      heroTitle: _s(map, 'heroTitle', defaults.heroTitle),
      heroLocation: _s(map, 'heroLocation', defaults.heroLocation),
      heroPossession: _s(map, 'heroPossession', defaults.heroPossession),
      heroRera: _s(map, 'heroRera', defaults.heroRera),
      heroOffers: items('heroOffers', defaults.heroOffers),
      aboutEyebrow: _s(map, 'aboutEyebrow', defaults.aboutEyebrow),
      aboutTitle: _s(map, 'aboutTitle', defaults.aboutTitle),
      aboutBody: _s(map, 'aboutBody', defaults.aboutBody),
      stats: items('stats', defaults.stats),
      highlightsEyebrow: _s(map, 'highlightsEyebrow', defaults.highlightsEyebrow),
      highlightsTitle: _s(map, 'highlightsTitle', defaults.highlightsTitle),
      highlights: items('highlights', defaults.highlights),
      amenitiesEyebrow: _s(map, 'amenitiesEyebrow', defaults.amenitiesEyebrow),
      amenitiesTitle: _s(map, 'amenitiesTitle', defaults.amenitiesTitle),
      amenities: items('amenities', defaults.amenities),
      livingEyebrow: _s(map, 'livingEyebrow', defaults.livingEyebrow),
      livingTitle: _s(map, 'livingTitle', defaults.livingTitle),
      livingItems: items('livingItems', defaults.livingItems),
      connectivityEyebrow:
          _s(map, 'connectivityEyebrow', defaults.connectivityEyebrow),
      connectivityTitle:
          _s(map, 'connectivityTitle', defaults.connectivityTitle),
      locations: items('locations', defaults.locations),
      enquiryEyebrow: _s(map, 'enquiryEyebrow', defaults.enquiryEyebrow),
      enquiryTitle: _s(map, 'enquiryTitle', defaults.enquiryTitle),
      enquiryBody: _s(map, 'enquiryBody', defaults.enquiryBody),
      enquiryCta: _s(map, 'enquiryCta', defaults.enquiryCta),
      interestedProjects: (map['interestedProjects'] is List)
          ? (map['interestedProjects'] as List).map((e) => e.toString()).toList()
          : defaults.interestedProjects,
      footerNote: _s(map, 'footerNote', defaults.footerNote),
      copyright: _s(map, 'copyright', defaults.copyright),
      address: _s(map, 'address', defaults.address),
      videoUrl: _s(map, 'videoUrl', defaults.videoUrl),
      brochureUrl: _s(map, 'brochureUrl', defaults.brochureUrl),
      reraDisclaimer: _s(map, 'reraDisclaimer', defaults.reraDisclaimer),
      status: _s(map, 'status', defaults.status),
      propertyType: _s(map, 'propertyType', defaults.propertyType),
      configurations: _s(map, 'configurations', defaults.configurations),
      specs: items('specs', defaults.specs),
      pricing: items('pricing', defaults.pricing),
      floorPlans: items('floorPlans', defaults.floorPlans),
      faqs: items('faqs', defaults.faqs),
      updates: items('updates', defaults.updates),
    );
  }

  SiteContent copyWith({
    String? brandName,
    String? projectName,
    String? tagline,
    String? phone,
    String? email,
    String? whatsapp, String? whatsappMessage,
    String? logoText,
    String? logoImageUrl,
    String? coverImageUrl,
    String? heroImageUrl,
    String? aboutImageUrl,
    List<String>? gallery,
    List<NamedItem>? galleryItems,
    Palette? palette,
    LayoutConfig? layout,
    String? headerCta,
    String? heroKicker,
    String? heroTitle,
    String? heroLocation,
    String? heroPossession,
    String? heroRera,
    List<NamedItem>? heroOffers,
    String? aboutEyebrow,
    String? aboutTitle,
    String? aboutBody,
    List<NamedItem>? stats,
    String? highlightsEyebrow,
    String? highlightsTitle,
    List<NamedItem>? highlights,
    String? amenitiesEyebrow,
    String? amenitiesTitle,
    List<NamedItem>? amenities,
    String? livingEyebrow,
    String? livingTitle,
    List<NamedItem>? livingItems,
    String? connectivityEyebrow,
    String? connectivityTitle,
    List<NamedItem>? locations,
    String? enquiryEyebrow,
    String? enquiryTitle,
    String? enquiryBody,
    String? enquiryCta,
    List<String>? interestedProjects,
    String? footerNote,
    String? copyright,
    String? address,
    String? videoUrl,
    String? brochureUrl,
    String? reraDisclaimer,
    String? status,
    String? propertyType,
    String? configurations,
    List<NamedItem>? specs,
    List<NamedItem>? pricing,
    List<NamedItem>? floorPlans,
    List<NamedItem>? faqs,
    List<NamedItem>? updates,
  }) =>
      SiteContent(
        brandName: brandName ?? this.brandName,
        projectName: projectName ?? this.projectName,
        tagline: tagline ?? this.tagline,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        whatsapp: whatsapp ?? this.whatsapp, whatsappMessage: whatsappMessage ?? this.whatsappMessage,
        logoText: logoText ?? this.logoText,
        logoImageUrl: logoImageUrl ?? this.logoImageUrl,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        heroImageUrl: heroImageUrl ?? this.heroImageUrl,
        aboutImageUrl: aboutImageUrl ?? this.aboutImageUrl,
        gallery: gallery ?? this.gallery,
        galleryItems: galleryItems ?? this.galleryItems,
        palette: palette ?? this.palette,
        layout: layout ?? this.layout,
        headerCta: headerCta ?? this.headerCta,
        heroKicker: heroKicker ?? this.heroKicker,
        heroTitle: heroTitle ?? this.heroTitle,
        heroLocation: heroLocation ?? this.heroLocation,
        heroPossession: heroPossession ?? this.heroPossession,
        heroRera: heroRera ?? this.heroRera,
        heroOffers: heroOffers ?? this.heroOffers,
        aboutEyebrow: aboutEyebrow ?? this.aboutEyebrow,
        aboutTitle: aboutTitle ?? this.aboutTitle,
        aboutBody: aboutBody ?? this.aboutBody,
        stats: stats ?? this.stats,
        highlightsEyebrow: highlightsEyebrow ?? this.highlightsEyebrow,
        highlightsTitle: highlightsTitle ?? this.highlightsTitle,
        highlights: highlights ?? this.highlights,
        amenitiesEyebrow: amenitiesEyebrow ?? this.amenitiesEyebrow,
        amenitiesTitle: amenitiesTitle ?? this.amenitiesTitle,
        amenities: amenities ?? this.amenities,
        livingEyebrow: livingEyebrow ?? this.livingEyebrow,
        livingTitle: livingTitle ?? this.livingTitle,
        livingItems: livingItems ?? this.livingItems,
        connectivityEyebrow: connectivityEyebrow ?? this.connectivityEyebrow,
        connectivityTitle: connectivityTitle ?? this.connectivityTitle,
        locations: locations ?? this.locations,
        enquiryEyebrow: enquiryEyebrow ?? this.enquiryEyebrow,
        enquiryTitle: enquiryTitle ?? this.enquiryTitle,
        enquiryBody: enquiryBody ?? this.enquiryBody,
        enquiryCta: enquiryCta ?? this.enquiryCta,
        interestedProjects: interestedProjects ?? this.interestedProjects,
        footerNote: footerNote ?? this.footerNote,
        copyright: copyright ?? this.copyright,
        address: address ?? this.address,
        videoUrl: videoUrl ?? this.videoUrl,
        brochureUrl: brochureUrl ?? this.brochureUrl,
        reraDisclaimer: reraDisclaimer ?? this.reraDisclaimer,
        status: status ?? this.status,
        propertyType: propertyType ?? this.propertyType,
        configurations: configurations ?? this.configurations,
        specs: specs ?? this.specs,
        pricing: pricing ?? this.pricing,
        floorPlans: floorPlans ?? this.floorPlans,
        faqs: faqs ?? this.faqs,
        updates: updates ?? this.updates,
      );

  factory SiteContent.defaults() => const SiteContent(
        brandName: 'NB Developer',
        projectName: 'NB Legacy Tower',
        tagline: 'Crafting Communities Since 1946',
        phone: '+91 97271 14499',
        email: 'enquiry@nbdeveloper.co.in',
        whatsapp: '919727114499', whatsappMessage: 'Hello, I would like to enquire about NB Legacy Tower.',
        logoText: 'NB',
        logoImageUrl: 'assets/images/nbdeveloperlogo.png',
        coverImageUrl: 'assets/images/nblegacy/Final Cam_05.jpg',
        heroImageUrl: 'assets/images/nblegacy/Final Cam_01.jpg',
        aboutImageUrl: 'assets/images/nblegacy/Final Cam_06.jpg',
        gallery: [
          'assets/images/nblegacy/Final Cam_01.jpg',
          'assets/images/nblegacy/Final Cam_05.jpg',
          'assets/images/nblegacy/Final Cam_06.jpg',
          'assets/images/nblegacy/Final Cam_09.jpg',
          'assets/images/nblegacy/Final Cam_11.jpg',
          'assets/images/nblegacy/Final Cam_14.jpg',
          'assets/images/nblegacy/Final Cam_15.jpg',
          'assets/images/nblegacy/Final Cam_17.jpg',
          'assets/images/nblegacy/Final_Montage_view.jpg',
        ],
        galleryItems: [
          NamedItem(
            title: 'Tower Exterior',
            imageUrl: 'assets/images/nblegacy/Final Cam_01.jpg',
          ),
          NamedItem(
            title: '4 BHK Living Room',
            imageUrl: 'assets/images/nblegacy/Final_4BHK_Livingroom_View_01.jpg',
          ),
          NamedItem(
            title: '5 BHK Living Room',
            imageUrl: 'assets/images/nblegacy/Final_5BHK_Living room_View.jpg',
          ),
          NamedItem(
            title: 'Double Height Lobby Entrance',
            imageUrl: 'assets/images/nblegacy/Final_Double_Height_Lift_Entrance_Lobby_View.jpg',
          ),
          NamedItem(
            title: 'Rooftop Terrace Lounge',
            imageUrl: 'assets/images/nblegacy/Final_Terrace_view.jpg',
          ),
        ],
        palette: Palette(),
        layout: LayoutConfig(),
        headerCta: 'BOOK A PRIVATE VIEWING',
        heroKicker: "Ahmedabad's Finest Address.",
        heroTitle: 'Where Luxury Finds Its True Scale.',
        heroLocation: 'Science Park, Ahmedabad',
        heroPossession: 'Possession: Dec 2029',
        heroRera:
            'PR/GJ/AHMEDABAD/DASKROI/Ahmedabad Municipal Corporation/RAA16634/240326/311232',
        heroOffers: [
          NamedItem(
            title: '4 BHK Simplex',
            subtitle: '₹4.5 Cr Onwards',
            icon: 'apartment',
          ),
          NamedItem(
            title: '5 BHK Vertical Bungalow',
            subtitle: '₹8.1 Cr Onwards',
            icon: 'villa',
          ),
        ],
        aboutEyebrow: 'About NB Legacy Tower',
        aboutTitle: 'A Five-Star Arrival, Every Time You Come Home',
        aboutBody:
            'NB Legacy Tower is an exclusive collection of 4 BHK simplex and 5 BHK vertical bungalow residences in Science Park, Ahmedabad. Rising 22 storeys, the landmark combines expansive residences, refined architecture and an elevated lifestyle designed around privacy, comfort and distinction.',
        stats: [
          NamedItem(title: '22 Storeys', subtitle: 'Luxury Tower', icon: 'layers'),
          NamedItem(title: '211 Residences', subtitle: 'Exclusive Collection', icon: 'home'),
          NamedItem(title: '35+ Premium', subtitle: 'Lifestyle Amenities', icon: 'spa'),
          NamedItem(title: 'Science Park', subtitle: 'Ahmedabad', icon: 'place'),
        ],
        highlightsEyebrow: 'WHY LEGACY TOWER',
        highlightsTitle: 'A Rare Convergence of Scale, Location & Heritage',
        highlights: [
          NamedItem(
            title: 'Landmark Address',
            subtitle:
                'Situated on Science Park Road, Science City — Ahmedabad\'s most coveted ultra-luxury corridor.',
            icon: 'place',
          ),
          NamedItem(
            title: 'Large-Format Residences',
            subtitle:
                'Expansive 4 BHK Simplex (5,420 sq ft) and 5 BHK Vertical Bungalows (9,400 sq ft) with double-height living.',
            icon: 'apartment',
          ),
          NamedItem(
            title: 'Low-Density Living',
            subtitle:
                'Only 211 exclusive residences across a 22-storey tower, ensuring privacy and quietude.',
            icon: 'people',
          ),
          NamedItem(
            title: 'Curated Lifestyle',
            subtitle:
                '35+ world-class amenities including a 5-star double-height entrance lobby, private theatre & infinity pool.',
            icon: 'spa',
          ),
          NamedItem(
            title: 'Long-Term Family Value',
            subtitle:
                'NB Developer — Since 1946. A legacy spanning eight decades.',
            icon: 'family_restroom',
          ),
        ],
        amenitiesEyebrow: 'Premium Amenities',
        amenitiesTitle: 'Discover a lifestyle that goes beyond expectations',
        amenities: [
          NamedItem(title: 'Infinity Swimming Pool', icon: 'pool', imageUrl: 'assets/images/nblegacy/Final_Swimmingpool_view.jpg'),
          NamedItem(title: 'Private Theater', icon: 'theaters', imageUrl: 'assets/images/nblegacy/Final_Theater_view.jpg'),
          NamedItem(title: 'Banquet Hall', icon: 'celebration', imageUrl: 'assets/images/nblegacy/Final_Banquet_view.jpg'),
          NamedItem(title: 'Co-Working Space', icon: 'work', imageUrl: 'assets/images/nblegacy/Final_Co-working space_view.jpg'),
          NamedItem(title: 'Conference Room', icon: 'business', imageUrl: 'assets/images/nblegacy/Final_Conference_view.jpg'),
          NamedItem(title: 'Digital Library & Lounge', icon: 'menu_book', imageUrl: 'assets/images/nblegacy/Final_Lounge_view.jpg'),
          NamedItem(title: 'Game Zone', icon: 'sports_esports', imageUrl: 'assets/images/nblegacy/Final_Gameroom_View.jpg'),
          NamedItem(title: 'Cricket & Badminton', icon: 'sports_tennis', imageUrl: 'assets/images/nblegacy/Final_Cricket_Badbinton_view.jpg'),
          NamedItem(title: 'Fitness Centre / Gym', icon: 'fitness_center', imageUrl: 'assets/images/nblegacy/Final_Gym_view.jpg'),
          NamedItem(title: 'Salon & Spa', icon: 'spa', imageUrl: 'assets/images/nblegacy/Final_Salon_view.jpg'),
          NamedItem(title: 'Digital Golf Simulator', icon: 'golf_course', imageUrl: 'assets/images/nblegacy/Final_Golf stimulation_View.jpg'),
          NamedItem(title: 'Pet Park', icon: 'pets', imageUrl: 'assets/images/nblegacy/Final_Pet Area_view.jpg'),
        ],
        livingEyebrow: 'EXCLUSIVELY DESIGNED RESIDENCES',
        livingTitle: 'Masterpieces of Scale & Spatial Luxury',
        livingItems: [
          NamedItem(
            title: 'Grandeur & Entrance',
            subtitle:
                'Soaring volumes, refined architecture and a double-height entrance lobby that feels like a private five-star hotel.',
            icon: 'apartment',
            imageUrl:
                'assets/images/nblegacy/Final_Double_Height_Lift_Entrance_Lobby_View.jpg',
          ),
          NamedItem(
            title: '4 BHK Simplex Living',
            subtitle:
                'Expansive 4 BHK simplex residences with dedicated living, dining, kitchen, and balcony views planned for effortless comfort.',
            icon: 'king_bed',
            imageUrl:
                'assets/images/nblegacy/Final_4BHK_Livingroom_View_01.jpg',
          ),
          NamedItem(
            title: '5 BHK Vertical Bungalow',
            subtitle:
                'Vertical bungalow duplex residences with double-height living rooms and master bedroom suites designed for scale and privacy.',
            icon: 'auto_awesome',
            imageUrl:
                'assets/images/nblegacy/Final_5BHK_Living room_View.jpg',
          ),
        ],
        connectivityEyebrow: 'Prime Connectivity',
        connectivityTitle: 'A location that connects exclusivity with convenience',
        locations: [
          NamedItem(title: 'S.P. Ring Road', subtitle: '400 M', icon: 'alt_route'),
          NamedItem(title: 'Science City', subtitle: '1 KM', icon: 'science'),
          NamedItem(title: 'CIMS Hospital', subtitle: '2 KM', icon: 'local_hospital'),
          NamedItem(title: 'S.G. Highway', subtitle: '3 KM', icon: 'directions_car'),
          NamedItem(title: 'Jain Derasar', subtitle: '300 MTR', icon: 'temple_hindu'),
          NamedItem(title: 'Oxygen Park', subtitle: '300 MTR', icon: 'park'),
          NamedItem(title: 'Swaminarayan Mandir', subtitle: '1.5 KM', icon: 'account_balance'),
          NamedItem(title: 'Premium Schools', subtitle: '3 KM', icon: 'school'),
          NamedItem(title: 'Vaishnodevi Circle', subtitle: '10 MINS', icon: 'alt_route'),
          NamedItem(title: 'Intl Airport (SVPI)', subtitle: '25 MINS', icon: 'flight'),
        ],
        enquiryEyebrow: 'Experience Legacy Living',
        enquiryTitle: 'Schedule a Home Tour',
        enquiryBody:
            'Step into a world crafted for distinction. Leave your details and our team will reach out to guide you through your homebuying journey. We look forward to welcoming you to NB Legacy Tower.',
        enquiryCta: 'BOOK A PRIVATE VIEWING',
        interestedProjects: [
          '4 BHK Simplex (5,420 Sq. Ft.)',
          '5 BHK Vertical Bungalow (9,400 Sq. Ft.)',
          'Both Configurations',
        ],
        footerNote:
            'A landmark of ultra-luxury living by NB Developer — rooted in legacy since 1946.',
        copyright: '© 2026 NB Developer. All rights reserved.',
        address:
            'FP No. 949/1, NB House, Survey No. 838/1/1, Science City Road, Sola, Ahmedabad, Gujarat 380060',
        videoUrl: '',
        brochureUrl: '',
        reraDisclaimer:
            'All specifications, prices and timelines are as provided by the promoter. Please verify the RERA registration on the Gujarat RERA website before making any purchase decision.',
        status: 'Ongoing',
        propertyType: 'Residential',
        configurations: '4 & 5 BHK Luxury Residences',
        specs: [
          NamedItem(title: 'Typology', subtitle: '4 BHK Simplex & 5 BHK Vertical Bungalow'),
          NamedItem(title: 'Storeys', subtitle: '22 Storey luxury tower'),
          NamedItem(title: 'Residences', subtitle: '211 exclusive homes'),
          NamedItem(title: 'Location', subtitle: 'Science Park, Ahmedabad'),
          NamedItem(title: 'Possession', subtitle: 'December 2029'),
          NamedItem(title: 'Vastu', subtitle: '100% Vastu compliant'),
        ],
        pricing: [
          NamedItem(title: '4 BHK Simplex', subtitle: '₹4.5 Cr Onwards'),
          NamedItem(title: '5 BHK Vertical Bungalow', subtitle: '₹8.1 Cr Onwards'),
        ],
        floorPlans: [
          NamedItem(
            title: '4 BHK Simplex Residence',
            subtitle: '₹4.5 Cr Onwards • 5,420 Sq. Ft. Approx.',
            imageUrl:
                'assets/images/nblegacy/Final_4BHK_Livingroom_View_01.jpg',
          ),
          NamedItem(
            title: '5 BHK Vertical Bungalow',
            subtitle: '₹8.1 Cr Onwards • 9,400 Sq. Ft. Approx. (Duplex)',
            imageUrl:
                'assets/images/nblegacy/Final_5BHK_Living room_View.jpg',
          ),
        ],
        faqs: [
          NamedItem(
            title: 'Where is NB Legacy Tower located?',
            subtitle:
                'Science Park, Ahmedabad, close to Science City, S P Ring Road and SG Highway.',
          ),
          NamedItem(
            title: 'What configurations are available?',
            subtitle:
                '4 BHK Simplex (5,420 Sq. Ft.) and 5 BHK Vertical Bungalow (9,400 Sq. Ft. duplex).',
          ),
          NamedItem(
            title: 'When is possession scheduled?',
            subtitle: 'December 2029, subject to published RERA timelines.',
          ),
          NamedItem(
            title: 'Is the project RERA registered?',
            subtitle:
                'Yes. Please refer to the RERA number on this page and verify it on the Gujarat RERA portal.',
          ),
        ],
        updates: [
          NamedItem(
            title: 'Construction in progress',
            subtitle:
                'Works are underway at Science Park. Request a site visit for the latest status.',
          ),
        ],
      );
}
