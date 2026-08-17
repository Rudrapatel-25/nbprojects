import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/site_content.dart';
import '../services/content_repository.dart';
import 'luxury.dart';
import 'site_chrome.dart';

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
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  final _dateController = TextEditingController();
  int _step = 0;
  String _interest = '';
  String _request = 'Site visit';
  String _timeSlot = '';
  String _timeWindow = '';
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final options = widget.content.interestedProjects.isNotEmpty
        ? widget.content.interestedProjects
        : [widget.content.projectName];
    _interest = options.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln('Hello, I would like to enquiry about *${widget.content.projectName}*:');
      buffer.writeln('');
      buffer.writeln('👤 *Name:* ${_name.text.trim()}');
      buffer.writeln('📞 *Phone:* ${_phone.text.trim()}');
      if (_email.text.trim().isNotEmpty) {
        buffer.writeln('✉️ *Email:* ${_email.text.trim()}');
      }
      buffer.writeln('🏠 *Interested in:* $_interest');
      buffer.writeln('📋 *Request:* $_request');

      if (_request == 'Site visit') {
        if (_dateController.text.isNotEmpty) {
          buffer.writeln('📅 *Preferred Date:* ${_dateController.text}');
        }
        if (_timeSlot.isNotEmpty) {
          buffer.writeln('⏰ *Preferred Time:* $_timeSlot');
        }
      } else if (_request == 'Callback') {
        if (_timeWindow.isNotEmpty) {
          buffer.writeln('⏰ *Preferred Window:* $_timeWindow');
        }
      }

      if (_message.text.trim().isNotEmpty) {
        buffer.writeln('💬 *Message:* ${_message.text.trim()}');
      }

      final fullMessage = buffer.toString().trim();

      try {
        await ContentRepository().submitInquiry(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          project: _interest,
          projectId: widget.projectId,
          message: fullMessage,
        );
      } catch (e) {
        print('Repository submit notice: $e');
      }

      await openWhatsApp(widget.content, message: fullMessage);

      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send enquiry: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget build(BuildContext context) {
    final colors = SiteScope.of(context).colors;
    final content = widget.content;
    if (_sent) {
      return PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you',
              style: GoogleFonts.playfairDisplay(color: colors.text, fontSize: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'Our team will reach you shortly to continue this conversation.',
              style: GoogleFonts.outfit(color: colors.muted, height: 1.7),
            ),
          ],
        ),
      );
    }

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
            const SizedBox(height: 22),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(right: 8),
                      color: i <= _step
                          ? colors.brass
                          : colors.brass.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            if (_step == 0) ...[
              _field(_name, 'Full name', requiredField: true),
              _field(_phone, 'Phone', requiredField: true, phone: true),
              _field(_email, 'Email'),
            ],
            if (_step == 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _interest,
                dropdownColor: colors.surface,
                decoration: _decoration('Interested in'),
                items: [
                  for (final option in (content.interestedProjects.isNotEmpty
                      ? content.interestedProjects
                      : [content.projectName]))
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (value) => setState(() => _interest = value ?? _interest),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _request,
                dropdownColor: colors.surface,
                decoration: _decoration('How can we help?'),
                items: const [
                  DropdownMenuItem(value: 'Site visit', child: Text('Book a site visit')),
                  DropdownMenuItem(value: 'Callback', child: Text('Request a callback')),
                  DropdownMenuItem(value: 'Brochure', child: Text('Request brochure')),
                ],
                onChanged: (value) => setState(() => _request = value ?? _request),
              ),
            ],
            if (_step == 2) ...[
              if (_request == 'Site visit') ...[
                _dateField('Preferred Date'),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _timeSlot.isEmpty ? null : _timeSlot,
                  dropdownColor: colors.surface,
                  decoration: _decoration('Preferred Time Slot'),
                  items: const [
                    DropdownMenuItem(value: 'Morning (10 AM - 12 PM)', child: Text('Morning (10 AM - 12 PM)')),
                    DropdownMenuItem(value: 'Afternoon (12 PM - 3 PM)', child: Text('Afternoon (12 PM - 3 PM)')),
                    DropdownMenuItem(value: 'Evening (3 PM - 6 PM)', child: Text('Evening (3 PM - 6 PM)')),
                  ],
                  onChanged: (value) => setState(() => _timeSlot = value ?? _timeSlot),
                ),
                const SizedBox(height: 14),
              ] else if (_request == 'Callback') ...[
                DropdownButtonFormField<String>(
                  value: _timeWindow.isEmpty ? null : _timeWindow,
                  dropdownColor: colors.surface,
                  decoration: _decoration('Preferred Time Window'),
                  items: const [
                    DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                    DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                    DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                  ],
                  onChanged: (value) => setState(() => _timeWindow = value ?? _timeWindow),
                ),
                const SizedBox(height: 14),
              ],
              _field(_message, 'Message (optional)', lines: 4),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: () => setState(() => _step -= 1),
                    child: Text('Back', style: GoogleFonts.outfit(color: colors.muted)),
                  ),
                const Spacer(),
                LuxuryButton(
                  label: _step < 2
                      ? 'Continue'
                      : (_sending ? 'Sending...' : content.enquiryCta),
                  onPressed: _sending
                      ? () {}
                      : () {
                          if (_step == 0 && !(_form.currentState?.validate() ?? false)) {
                            return;
                          }
                          if (_step < 2) {
                            setState(() => _step += 1);
                          } else {
                            _submit();
                          }
                        },
                ),
              ],
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        validator: requiredField
            ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: _decoration(label),
      ),
    );
  }

  Widget _dateField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        onTap: () async {
          final scope = SiteScope.of(context);
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 60)),
            builder: (dialogContext, child) {
              final colors = scope.colors;
              return Theme(
                data: Theme.of(dialogContext).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: colors.brass,
                    onPrimary: colors.black,
                    surface: colors.surface,
                    onSurface: colors.text,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            setState(() {
              _dateController.text = "${date.day}/${date.month}/${date.year}";
            });
          }
        },
        decoration: _decoration(label).copyWith(
          suffixIcon: Icon(Icons.calendar_today, color: SiteScope.of(context).colors.brass, size: 20),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    final colors = SiteScope.of(context).colors;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: colors.muted),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.brass.withValues(alpha: 0.35)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.brass),
      ),
    );
  }
}
