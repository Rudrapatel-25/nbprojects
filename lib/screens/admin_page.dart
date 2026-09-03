import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/inquiry_lead.dart';
import '../models/site_content.dart';
import '../services/content_repository.dart';
import '../services/sheets_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/luxury.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _repo = ContentRepository();

  bool _authenticated = false;
  Map<String, dynamic>? _adminUser;

  // Login Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loginLoading = false;
  String? _loginError;
  bool _rememberMe = true;

  // Dashboard Filters
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _configFilter = 'All';
  String _waFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('admin_remember_me') ?? false;
      if (remember) {
        final email = prefs.getString('admin_saved_email') ?? '';
        final password = prefs.getString('admin_saved_password') ?? '';
        if (mounted) {
          setState(() {
            _rememberMe = true;
            if (email.isNotEmpty) _emailController.text = email;
            if (password.isNotEmpty) _passwordController.text = password;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _loginError = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _loginLoading = true;
      _loginError = null;
    });

    try {
      final user = await _repo.verifyAdminCredentials(email, password);
      if (user != null) {
        // Save or clear Remember Me in SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
            await prefs.setBool('admin_remember_me', true);
            await prefs.setString('admin_saved_email', email);
            await prefs.setString('admin_saved_password', password);
          } else {
            await prefs.setBool('admin_remember_me', false);
            await prefs.remove('admin_saved_email');
            await prefs.remove('admin_saved_password');
          }
        } catch (e) {
          debugPrint('Preferences notice: $e');
        }

        TextInput.finishAutofillContext();

        setState(() {
          _authenticated = true;
          _adminUser = user;
          _loginLoading = false;
        });
      } else {
        setState(() {
          _loginLoading = false;
          _loginError = 'Invalid email or password. Please verify your credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _loginLoading = false;
        _loginError = 'Login check notice: $e';
      });
    }
  }

  void _handleLogout() {
    setState(() {
      _authenticated = false;
      _adminUser = null;
      if (!_rememberMe) {
        _emailController.clear();
        _passwordController.clear();
      }
      _loginError = null;
    });
  }

  void _exportToExcel(List<InquiryLead> leads) {
    if (leads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No inquiries available to export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    // UTF-8 BOM for Microsoft Excel recognition
    buffer.write('\uFEFF');
    buffer.writeln('Date & Time,Customer Name,Mobile Number,Configuration,Purpose,Message,Status,WhatsApp Status,WhatsApp Message ID');

    for (final lead in leads) {
      final dateStr =
          '${lead.createdAt.day.toString().padLeft(2, '0')}-${lead.createdAt.month.toString().padLeft(2, '0')}-${lead.createdAt.year} ${lead.createdAt.hour.toString().padLeft(2, '0')}:${lead.createdAt.minute.toString().padLeft(2, '0')}';
      final row = [
        _escapeCsv(dateStr),
        _escapeCsv(lead.name),
        _escapeCsv(lead.phone),
        _escapeCsv(lead.configuration),
        _escapeCsv(lead.purpose),
        _escapeCsv(lead.message),
        _escapeCsv(lead.status),
        _escapeCsv(lead.whatsappStatus),
        _escapeCsv(lead.whatsappMessageId ?? ''),
      ];
      buffer.writeln(row.join(','));
    }

    final bytes = utf8.encode(buffer.toString());
    final base64Data = base64Encode(bytes);
    final uri = Uri.parse('data:text/csv;charset=utf-8;base64,$base64Data');
    launchUrl(uri, mode: LaunchMode.externalApplication);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF141210),
        content: Text(
          'Exported ${leads.length} inquiries to Excel CSV.',
          style: GoogleFonts.outfit(color: const Color(0xFFF3EEE4)),
        ),
      ),
    );
  }

  String _escapeCsv(String value) {
    final v = value.replaceAll('"', '""').replaceAll('\n', ' ').replaceAll('\r', ' ');
    return '"$v"';
  }

  Future<void> _resendWhatsApp(InquiryLead lead) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1B17),
        content: Text('Sending WhatsApp message to ${lead.phone}...'),
        duration: const Duration(seconds: 2),
      ),
    );
    final result = await WhatsAppService.sendBookingTemplate(lead.phone);
    await _repo.updateInquiryWhatsAppStatus(
      lead.id,
      result.statusText,
      messageId: result.messageId,
      error: result.error,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.redAccent,
        content: Text(
          result.success
              ? 'WhatsApp message delivered successfully to ${lead.phone}!'
              : 'Failed to send WhatsApp: ${result.error}',
        ),
      ),
    );
  }

  Widget _buildWhatsAppStatusBadge(SiteColors colors, InquiryLead lead) {
    final status = lead.whatsappStatus.trim();
    final isSuccess = status.toLowerCase() == 'sent' || status.toLowerCase() == 'success';
    final isFailed = status.toLowerCase() == 'failed' || status.toLowerCase() == 'fail';

    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String displayLabel;

    if (isSuccess) {
      bg = const Color(0xFF2E7D32).withValues(alpha: 0.18);
      border = const Color(0xFF81C784);
      textColor = const Color(0xFF81C784);
      icon = Icons.check_circle_outline;
      displayLabel = 'Sent';
    } else if (isFailed) {
      bg = Colors.redAccent.withValues(alpha: 0.18);
      border = Colors.redAccent;
      textColor = Colors.redAccent;
      icon = Icons.error_outline;
      displayLabel = 'Failed';
    } else {
      bg = Colors.white.withValues(alpha: 0.05);
      border = Colors.white.withValues(alpha: 0.2);
      textColor = colors.onDark.withValues(alpha: 0.5);
      icon = Icons.remove_circle_outline;
      displayLabel = '—';
    }

    return Tooltip(
      message: isSuccess
          ? 'Delivered via Botbiz WhatsApp API\nID: ${lead.whatsappMessageId ?? "Success"}'
          : isFailed
              ? 'Delivery failed: ${lead.whatsappError ?? "Unknown error"}\nClick retry icon to re-send'
              : 'WhatsApp not sent or pending',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border.withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: textColor),
                const SizedBox(width: 5),
                Text(
                  displayLabel,
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isFailed || (!isSuccess && status != '-')) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.refresh, size: 14),
              tooltip: 'Retry sending WhatsApp message',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              color: colors.brass,
              onPressed: () => _resendWhatsApp(lead),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultContent = SiteContent.defaults();
    final colors = SiteColors(defaultContent.palette);

    return Scaffold(
      backgroundColor: colors.black,
      body: _authenticated
          ? _buildDashboard(colors, defaultContent)
          : _buildLoginScreen(colors),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGIN SCREEN
  // ---------------------------------------------------------------------------
  Widget _buildLoginScreen(SiteColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1714),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.brass.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Mark
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.brass, width: 1.5),
                        color: colors.black,
                      ),
                      child: Image.asset(
                        'assets/images/nbdeveloperlogo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            'NB',
                            style: GoogleFonts.cinzel(
                              color: colors.brass,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'NB DEVELOPER',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      color: colors.brass,
                      fontSize: 13,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Admin Portal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: colors.onDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NB Legacy Tower Leads & Bookings',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: colors.onDark.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_loginError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _loginError!,
                                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (_loginError!.contains('permission-denied')) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tip: In Firebase Console > Cloud Firestore > Rules, allow read for "/admin/{id}" and click Publish.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email Field
                  Text(
                    'ADMIN EMAIL',
                    style: GoogleFonts.cinzel(
                      color: colors.brass,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email, AutofillHints.username],
                    style: GoogleFonts.outfit(color: colors.onDark),
                    decoration: InputDecoration(
                      hintText: 'admin@example.com',
                      hintStyle: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.3)),
                      prefixIcon: Icon(Icons.email_outlined, color: colors.brass, size: 20),
                      filled: true,
                      fillColor: colors.black,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.brass.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.brass, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Text(
                    'PASSWORD',
                    style: GoogleFonts.cinzel(
                      color: colors.brass,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    style: GoogleFonts.outfit(color: colors.onDark),
                    onSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: colors.brass, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: colors.brass.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: colors.black,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.brass.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.brass, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Remember Me Checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: colors.brass,
                          checkColor: colors.black,
                          side: BorderSide(color: colors.brass.withValues(alpha: 0.6), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _rememberMe = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Text(
                          'Remember me',
                          style: GoogleFonts.outfit(
                            color: colors.onDark.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.brass,
                        foregroundColor: colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _loginLoading ? null : _handleLogin,
                      child: _loginLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              'SIGN IN',
                              style: GoogleFonts.cinzel(
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link back to site
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: Icon(Icons.arrow_back, size: 16, color: colors.onDark.withValues(alpha: 0.6)),
                      label: Text(
                        'Back to NB Legacy Tower Site',
                        style: GoogleFonts.outfit(
                          color: colors.onDark.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
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

  // ---------------------------------------------------------------------------
  // DASHBOARD SCREEN
  // ---------------------------------------------------------------------------
  Widget _buildDashboard(SiteColors colors, SiteContent defaultContent) {
    return StreamBuilder<List<InquiryLead>>(
      stream: _repo.inquiriesStream(),
      builder: (context, snapshot) {
        final allLeads = snapshot.data ?? [];
        final filteredLeads = _filterLeads(allLeads);

        final screenWidth = MediaQuery.sizeOf(context).width;
        final isMobile = screenWidth < 600;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0D0B),
          appBar: _buildAppBar(context, colors, allLeads),
          body: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
              ? Center(child: CircularProgressIndicator(color: colors.brass))
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 20,
                    vertical: isMobile ? 16 : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Metrics Cards
                          _buildMetricsRow(colors, allLeads),
                          const SizedBox(height: 20),

                          // Search and Filters
                          _buildFilterBar(colors, allLeads),
                          const SizedBox(height: 16),

                          // Results Counter
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                'SHOWING ${filteredLeads.length} OF ${allLeads.length} INQUIRIES',
                                style: GoogleFonts.cinzel(
                                  color: colors.brass,
                                  fontSize: 12,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF66BB6A),
                                ),
                                onPressed: () => _exportToExcel(filteredLeads),
                                icon: const Icon(Icons.file_download_outlined, size: 18),
                                label: Text(
                                  'Export to Excel (.csv)',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Inquiries Data View (Responsive: Table on Desktop, Cards on Mobile)
                          if (filteredLeads.isEmpty)
                            _buildEmptyState(colors)
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 850) {
                                  return _buildMobileCardList(colors, filteredLeads);
                                } else {
                                  return _buildDesktopDataTable(colors, filteredLeads);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, SiteColors colors, List<InquiryLead> leads) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 768;

    return AppBar(
      backgroundColor: const Color(0xFF141210),
      elevation: 4,
      surfaceTintColor: Colors.transparent,
      titleSpacing: isCompact ? 12 : 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 32 : 38,
            height: isCompact ? 32 : 38,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: colors.brass.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(4),
              color: colors.black,
            ),
            child: Image.asset(
              'assets/images/nbdeveloperlogo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  'NB',
                  style: GoogleFonts.cinzel(
                    color: colors.brass,
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 11 : 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompact ? 'NB ADMIN' : 'NB LEGACY TOWER',
                style: GoogleFonts.cinzel(
                  color: colors.onDark,
                  fontSize: isCompact ? 13 : 14,
                  letterSpacing: isCompact ? 1.5 : 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isCompact)
                Text(
                  'Admin Management Portal',
                  style: GoogleFonts.outfit(
                    color: colors.brass,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (isCompact) ...[
          // Compact actions for mobile
          IconButton(
            tooltip: 'Export Excel',
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF81C784), size: 22),
            onPressed: () => _exportToExcel(leads),
          ),
          IconButton(
            tooltip: 'Live Site',
            icon: Icon(Icons.open_in_new, size: 20, color: colors.onDark.withValues(alpha: 0.8)),
            onPressed: () => context.go('/'),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.account_circle_outlined, color: colors.brass, size: 24),
            tooltip: 'Admin Menu',
            color: const Color(0xFF1E1B17),
            onSelected: (val) {
              if (val == 'logout') _handleLogout();
              if (val == 'site') context.go('/');
              if (val == 'export') _exportToExcel(leads);
              if (val == 'sheet') {
                launchUrl(Uri.parse(SheetsService.sheetUrl), mode: LaunchMode.externalApplication);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _adminUser?['displayName'] ?? 'NB Admin',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if ((_adminUser?['email'] ?? '').isNotEmpty)
                      Text(
                        _adminUser!['email'],
                        style: GoogleFonts.outfit(color: colors.brass, fontSize: 11),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'sheet',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, size: 16, color: Color(0xFF0F9D58)),
                    const SizedBox(width: 8),
                    Text('Google Sheet', style: GoogleFonts.outfit(color: colors.onDark, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF81C784)),
                    const SizedBox(width: 8),
                    Text('Export to Excel', style: GoogleFonts.outfit(color: colors.onDark, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'site',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 16, color: colors.onDark.withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    Text('Live Site', style: GoogleFonts.outfit(color: colors.onDark, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text('Sign Out', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ] else ...[
          // Full actions for desktop
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: Icon(Icons.open_in_new, size: 16, color: colors.onDark.withValues(alpha: 0.7)),
            label: Text(
              'Live Site',
              style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => launchUrl(
              Uri.parse(SheetsService.sheetUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: Text(
              'Google Sheet',
              style: GoogleFonts.cinzel(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => _exportToExcel(leads),
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: Text(
              'Export Excel',
              style: GoogleFonts.cinzel(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.brass.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.brass.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, color: colors.brass, size: 16),
                const SizedBox(width: 6),
                Text(
                  _adminUser?['displayName'] ?? 'NB Admin',
                  style: GoogleFonts.outfit(
                    color: colors.onDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sign Out',
            icon: Icon(Icons.logout, color: colors.onDark.withValues(alpha: 0.75)),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 16),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // METRICS ROW
  // ---------------------------------------------------------------------------
  Widget _buildMetricsRow(SiteColors colors, List<InquiryLead> allLeads) {
    final total = allLeads.length;
    final simplex4BHK = allLeads.where((l) => l.configuration.contains('4 BHK')).length;
    final bungalow5BHK = allLeads.where((l) => l.configuration.contains('5 BHK')).length;
    final newLeads = allLeads.where((l) => l.status.toLowerCase() == 'new').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 48) / 4
            : constraints.maxWidth >= 500
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _metricCard(
              title: 'Total Inquiries',
              count: '$total',
              subtitle: 'All registrations',
              icon: Icons.people_outline,
              color: colors.brass,
              width: cardWidth,
            ),
            _metricCard(
              title: '4 BHK Simplex',
              count: '$simplex4BHK',
              subtitle: '5,420 Sq. Ft. leads',
              icon: Icons.apartment_outlined,
              color: const Color(0xFF64B5F6),
              width: cardWidth,
            ),
            _metricCard(
              title: '5 BHK Bungalow',
              count: '$bungalow5BHK',
              subtitle: '9,400 Sq. Ft. duplex leads',
              icon: Icons.villa_outlined,
              color: const Color(0xFFFFB74D),
              width: cardWidth,
            ),
            _metricCard(
              title: 'New / Pending',
              count: '$newLeads',
              subtitle: 'Awaiting callback',
              icon: Icons.notification_important_outlined,
              color: const Color(0xFF81C784),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF181512),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.cinzel(
                    color: const Color(0xFFE8DFD3).withValues(alpha: 0.7),
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  count,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFE8DFD3).withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER BAR
  // ---------------------------------------------------------------------------
  Widget _buildFilterBar(SiteColors colors, List<InquiryLead> allLeads) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF181512),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.brass.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search box
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(color: colors.onDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone...',
                  hintStyle: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.4), fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: colors.brass, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF0F0D0B),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.brass.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.brass),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Dropdowns
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Status Filter
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0D0B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.brass.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Status: ',
                            style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.6), fontSize: 13),
                          ),
                          DropdownButton<String>(
                            value: _statusFilter,
                            dropdownColor: const Color(0xFF1E1B17),
                            style: GoogleFonts.outfit(color: colors.brass, fontSize: 13, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                              DropdownMenuItem(value: 'new', child: Text('New')),
                              DropdownMenuItem(value: 'contacted', child: Text('Contacted')),
                              DropdownMenuItem(value: 'completed', child: Text('Completed')),
                            ],
                            onChanged: (val) => setState(() => _statusFilter = val ?? 'All'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Configuration Filter
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0D0B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.brass.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Config: ',
                            style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.6), fontSize: 13),
                          ),
                          DropdownButton<String>(
                            value: _configFilter,
                            dropdownColor: const Color(0xFF1E1B17),
                            style: GoogleFonts.outfit(color: colors.brass, fontSize: 13, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Configs')),
                              DropdownMenuItem(value: '4 BHK', child: Text('4 BHK Simplex')),
                              DropdownMenuItem(value: '5 BHK', child: Text('5 BHK Bungalow')),
                            ],
                            onChanged: (val) => setState(() => _configFilter = val ?? 'All'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // WhatsApp Filter
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0D0B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.brass.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'WhatsApp: ',
                            style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.6), fontSize: 13),
                          ),
                          DropdownButton<String>(
                            value: _waFilter,
                            dropdownColor: const Color(0xFF1E1B17),
                            style: GoogleFonts.outfit(color: colors.brass, fontSize: 13, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All WhatsApp')),
                              DropdownMenuItem(value: 'Sent', child: Text('Sent')),
                              DropdownMenuItem(value: 'Failed', child: Text('Failed')),
                            ],
                            onChanged: (val) => setState(() => _waFilter = val ?? 'All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER HELPER
  // ---------------------------------------------------------------------------
  List<InquiryLead> _filterLeads(List<InquiryLead> leads) {
    final query = _searchController.text.trim().toLowerCase();
    return leads.where((lead) {
      // Search
      if (query.isNotEmpty) {
        final matchesName = lead.name.toLowerCase().contains(query);
        final matchesPhone = lead.phone.toLowerCase().contains(query);
        final matchesConfig = lead.configuration.toLowerCase().contains(query);
        final matchesPurpose = lead.purpose.toLowerCase().contains(query);
        final matchesMessage = lead.message.toLowerCase().contains(query);
        final matchesWa = lead.whatsappStatus.toLowerCase().contains(query);
        if (!matchesName && !matchesPhone && !matchesConfig && !matchesPurpose && !matchesMessage && !matchesWa) {
          return false;
        }
      }

      // Status Filter
      if (_statusFilter != 'All' && lead.status.toLowerCase() != _statusFilter.toLowerCase()) {
        return false;
      }

      // Config Filter
      if (_configFilter != 'All' && !lead.configuration.toLowerCase().contains(_configFilter.toLowerCase())) {
        return false;
      }

      // WhatsApp Filter
      if (_waFilter != 'All') {
        if (_waFilter == 'Sent' && lead.whatsappStatus.toLowerCase() != 'sent') {
          return false;
        }
        if (_waFilter == 'Failed' && lead.whatsappStatus.toLowerCase() != 'failed') {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // DESKTOP DATA TABLE
  // ---------------------------------------------------------------------------
  Widget _buildDesktopDataTable(SiteColors colors, List<InquiryLead> leads) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF181512),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.brass.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1000),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF221E1A)),
            dataRowMaxHeight: 68,
            columns: [
              DataColumn(
                label: Text(
                  'DATE & TIME',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'CUSTOMER NAME',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'MOBILE NUMBER',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'CONFIGURATION',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'PURPOSE',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'MESSAGE',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'WHATSAPP',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'STATUS',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'ACTIONS',
                  style: GoogleFonts.cinzel(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              for (final lead in leads)
                DataRow(
                  cells: [
                    // Date
                    DataCell(
                      Text(
                        '${lead.createdAt.day.toString().padLeft(2, '0')}-${lead.createdAt.month.toString().padLeft(2, '0')}-${lead.createdAt.year}\n${lead.createdAt.hour.toString().padLeft(2, '0')}:${lead.createdAt.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ),
                    // Name
                    DataCell(
                      Text(
                        lead.name,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    // Mobile (clickable to call)
                    DataCell(
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('tel:${lead.phone}')),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 14, color: colors.brass),
                            const SizedBox(width: 6),
                            Text(
                              lead.phone,
                              style: GoogleFonts.outfit(
                                color: colors.brass,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Configuration
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lead.configuration.contains('5 BHK')
                              ? const Color(0xFFFFB74D).withValues(alpha: 0.15)
                              : colors.brass.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: lead.configuration.contains('5 BHK')
                                ? const Color(0xFFFFB74D).withValues(alpha: 0.6)
                                : colors.brass.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          lead.configuration,
                          style: GoogleFonts.outfit(
                            color: lead.configuration.contains('5 BHK') ? const Color(0xFFFFB74D) : colors.brass,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Purpose
                    DataCell(
                      Text(
                        lead.purpose,
                        style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ),
                    // Message
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          lead.message.isNotEmpty ? lead.message : '—',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ),
                    ),
                    // WhatsApp Status
                    DataCell(
                      _buildWhatsAppStatusBadge(colors, lead),
                    ),
                    // Status
                    DataCell(
                      _buildStatusDropdown(colors, lead),
                    ),
                    // Actions
                    DataCell(
                      IconButton(
                        tooltip: 'Delete inquiry',
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(lead),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE CARD LIST
  // ---------------------------------------------------------------------------
  Widget _buildMobileCardList(SiteColors colors, List<InquiryLead> leads) {
    return Column(
      children: [
        for (final lead in leads)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF181512),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.brass.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.name,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lead.createdAt.day.toString().padLeft(2, '0')}-${lead.createdAt.month.toString().padLeft(2, '0')}-${lead.createdAt.year} at ${lead.createdAt.hour.toString().padLeft(2, '0')}:${lead.createdAt.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusDropdown(colors, lead),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.brass.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.brass.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        lead.configuration,
                        style: GoogleFonts.outfit(color: colors.brass, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lead.purpose,
                        style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.8), fontSize: 11),
                      ),
                    ),
                    _buildWhatsAppStatusBadge(colors, lead),
                  ],
                ),
                if (lead.message.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF100E0C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lead.message,
                      style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.75), fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Divider(color: colors.brass.withValues(alpha: 0.2), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Direct Call
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.brass),
                        foregroundColor: colors.brass,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () => launchUrl(Uri.parse('tel:${lead.phone}')),
                      icon: const Icon(Icons.phone, size: 14),
                      label: Text(lead.phone, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Delete inquiry',
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(lead),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STATUS DROPDOWN
  // ---------------------------------------------------------------------------
  Widget _buildStatusDropdown(SiteColors colors, InquiryLead lead) {
    Color badgeColor;
    switch (lead.status.toLowerCase()) {
      case 'completed':
        badgeColor = const Color(0xFF81C784);
        break;
      case 'contacted':
        badgeColor = const Color(0xFF64B5F6);
        break;
      default:
        badgeColor = const Color(0xFFFFB74D);
    }

    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
        ),
        child: DropdownButton<String>(
          value: ['new', 'contacted', 'completed'].contains(lead.status.toLowerCase())
              ? lead.status.toLowerCase()
              : 'new',
          isDense: true,
          dropdownColor: const Color(0xFF1E1B17),
          icon: Icon(Icons.arrow_drop_down, color: badgeColor, size: 18),
          style: GoogleFonts.cinzel(
            color: badgeColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          items: const [
            DropdownMenuItem(value: 'new', child: Text('NEW')),
            DropdownMenuItem(value: 'contacted', child: Text('CONTACTED')),
            DropdownMenuItem(value: 'completed', child: Text('COMPLETED')),
          ],
          onChanged: (newStatus) {
            if (newStatus != null && newStatus != lead.status) {
              _repo.updateInquiryStatus(lead.id, newStatus);
            }
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE CONFIRMATION
  // ---------------------------------------------------------------------------
  void _confirmDelete(InquiryLead lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1714),
        title: Text(
          'Delete Inquiry?',
          style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 20),
        ),
        content: Text(
          'Are you sure you want to delete the inquiry from ${lead.name} (${lead.phone})?',
          style: GoogleFonts.outfit(color: const Color(0xFFE8DFD3).withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: GoogleFonts.cinzel(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              _repo.deleteInquiry(lead.id);
            },
            child: Text('DELETE', style: GoogleFonts.cinzel(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(SiteColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF181512),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.brass.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 54, color: colors.brass.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Inquiries Found',
            style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _statusFilter != 'All' || _configFilter != 'All'
                ? 'Try clearing search or filter settings.'
                : 'Customer tour bookings and requests will appear here in real time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: colors.onDark.withValues(alpha: 0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
