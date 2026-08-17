import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nbprojects/models/site_content.dart';
import 'package:nbprojects/screens/inquiry_page.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  VisibilityDetectorController.instance.updateInterval = Duration.zero;

  testWidgets('enquiry page renders legacy tower hero', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    await tester.pumpWidget(
      MaterialApp(
        home: InquiryPage(content: SiteContent.defaults(), preview: true),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Where Luxury Finds'), findsOneWidget);
    expect(find.textContaining('NB DEVELOPER'), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('defaults include company address', (tester) async {
    expect(
      SiteContent.defaults().address.contains('Science City Road'),
      isTrue,
    );
  });
}
