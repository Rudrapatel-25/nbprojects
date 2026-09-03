import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/site_content.dart';
import '../services/content_repository.dart';
import 'luxury.dart';

class EnquiryForm extends StatefulWidget {
  const EnquiryForm({
    super.key,
    required this.content,
    required this.projectId,
    this.preview = false,
    this.source = 'project',
  });

  final SiteContent content;
  final String projectId;
  final bool preview;
  final String source;

  @override
  State<EnquiryForm> createState() => _EnquiryFormState();
}

class _EnquiryFormState extends State<EnquiryForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  String _configuration = '';
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final options = widget.content.interestedProjects.isNotEmpty
        ? widget.content.interestedProjects
        : [
            '4 BHK Simplex (5,420 Sq. Ft.)',
            '5 BHK Vertical Bungalow (9,400 Sq. Ft.)',
            'Both Configurations',
          ];
    _configuration = options.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      await ContentRepository().submitInquiry(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        project: _configuration,
        purpose: 'Site Visit',
        projectId: widget.projectId.isNotEmpty ? widget.projectId : 'nb-legacy-tower',
        message: _message.text.trim(),
      );

      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit booking: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    final content = widget.content;

    if (_sent) {
      return PaperCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.brass.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.brass, width: 1.5),
                ),
                child: Icon(Icons.check_circle_outline, color: colors.brass, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                'Viewing Request Received',
                style: GoogleFonts.playfairDisplay(
                  color: colors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you, ${_name.text.trim()}. Your inquiry for $_configuration at ${content.projectName} has been registered successfully. Our luxury advisory team will contact you shortly on ${_phone.text.trim()}.',
                style: GoogleFonts.outfit(
                  color: colors.muted,
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.brass),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: () {
                  setState(() {
                    _sent = false;
                    _name.clear();
                    _phone.clear();
                    _message.clear();
                  });
                },
                child: Text(
                  'SUBMIT ANOTHER INQUIRY',
                  style: GoogleFonts.cinzel(
                    color: colors.brass,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final options = widget.content.interestedProjects.isNotEmpty
        ? widget.content.interestedProjects
        : [
            '4 BHK Simplex (5,420 Sq. Ft.)',
            '5 BHK Vertical Bungalow (9,400 Sq. Ft.)',
            'Both Configurations',
          ];

    return PaperCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.enquiryEyebrow.toUpperCase(),
              style: GoogleFonts.cinzel(
                color: colors.brass,
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content.enquiryTitle,
              style: GoogleFonts.playfairDisplay(color: colors.text, fontSize: 32),
            ),
            const SizedBox(height: 10),
            Text(
              content.enquiryBody,
              style: GoogleFonts.outfit(color: colors.muted, height: 1.7),
            ),
            const SizedBox(height: 28),
            _field(
              _name,
              'Full Name',
              requiredField: true,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _field(
              _phone,
              'Mobile Number',
              requiredField: true,
              phone: true,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _configuration.isNotEmpty && options.contains(_configuration)
                  ? _configuration
                  : options.first,
              dropdownColor: colors.surface,
              decoration: _decoration('Preferred Configuration', icon: Icons.home_work_outlined),
              items: [
                for (final option in options)
                  DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: GoogleFonts.outfit(color: colors.text, fontSize: 15),
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _configuration = value ?? _configuration),
            ),
            const SizedBox(height: 16),
            _field(
              _message,
              'Message / Specific Requirements (Optional)',
              lines: 3,
              prefixIcon: Icons.chat_bubble_outline,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: LuxuryButton(
                label: _sending ? 'SCHEDULING TOUR...' : content.enquiryCta,
                onPressed: _sending ? () {} : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool requiredField = false,
    bool phone = false,
    int lines = 1,
    IconData? prefixIcon,
  }) {
    final colors = SiteScope.of(context).colors;
    return TextFormField(
      controller: controller,
      maxLines: lines,
      keyboardType: phone ? TextInputType.phone : TextInputType.text,
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your $label';
              }
              if (phone) {
                final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 8) {
                  return 'Please enter a valid mobile number';
                }
              }
              return null;
            }
          : null,
      style: GoogleFonts.outfit(color: colors.text, fontSize: 15),
      decoration: _decoration(label, icon: prefixIcon),
    );
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    final colors = SiteScope.of(context).colors;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: colors.muted, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: colors.brass, size: 20) : null,
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.brass.withValues(alpha: 0.35)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.brass, width: 1.5),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
