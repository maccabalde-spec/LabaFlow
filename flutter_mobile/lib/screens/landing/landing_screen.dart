import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════
//  LANDING SCREEN
//  Replicates the LabaFlow HTML landing page in Flutter
// ═══════════════════════════════════════════════════════════

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollCtrl = ScrollController();
  final _reviewNameC = TextEditingController();
  final _reviewServiceC = TextEditingController();
  final _reviewTextC = TextEditingController();
  int _reviewRating = 5;
  bool _reviewLoading = false;

  // FAQ open states
  final List<bool> _faqOpen = List.generate(7, (_) => false);

  // Section keys for navbar scroll
  final _howKey = GlobalKey();
  final _servicesKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _reviewsKey = GlobalKey();
  final _faqKey = GlobalKey();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _reviewNameC.dispose();
    _reviewServiceC.dispose();
    _reviewTextC.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitReview() async {
    final name = _reviewNameC.text.trim();
    final service = _reviewServiceC.text.trim();
    final text = _reviewTextC.text.trim();
    if (name.isEmpty || text.isEmpty) {
      if (mounted)
        await showErrorDialog(context, 'Name and review text are required.');
      return;
    }
    setState(() => _reviewLoading = true);
    await context.read<AppProvider>().addReview(
      name: name,
      service: service.isEmpty ? 'Laundry Service' : service,
      text: text,
      rating: _reviewRating,
    );
    if (!mounted) return;
    setState(() {
      _reviewLoading = false;
      _reviewNameC.clear();
      _reviewServiceC.clear();
      _reviewTextC.clear();
      _reviewRating = 5;
    });
    await showSuccessDialog(
      context,
      'Review Submitted!',
      'Thank you for your feedback!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 960;

    // Color aliases
    const bg = AppColors.lpBg;
    const surface = AppColors.lpWhite;
    const text = AppColors.lpText;
    const muted = AppColors.lpMuted;
    const border = AppColors.lpBorder;
    const accent = AppColors.lpAccent;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Sticky Navbar ──────────────────────────────
          _Navbar(
            dark: false,
            isWide: isWide,
            accent: accent,
            surface: surface,
            text: text,
            border: border,
            onHowIt: () => _scrollTo(_howKey),
            onServices: () => _scrollTo(_servicesKey),
            onPricing: () => _scrollTo(_pricingKey),
            onReviews: () => _scrollTo(_reviewsKey),
            onFaq: () => _scrollTo(_faqKey),
            onSignIn: () => context.go('/auth'),
            onBookNow: () => context.go('/auth?tab=reg'),
          ),
          // ── Scrollable body ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero
                  _HeroSection(
                    dark: false,
                    isWide: isWide,
                    bg: bg,
                    surface: surface,
                    text: text,
                    muted: muted,
                    accent: accent,
                    border: border,
                    onBook: () => context.go('/auth?tab=reg'),
                    onSignIn: () => context.go('/auth'),
                  ),
                  // Badges
                  _BadgesRow(dark: false),
                  // How It Works
                  KeyedSubtree(
                    key: _howKey,
                    child: _HowItWorks(
                      dark: false,
                      isWide: isWide,
                      bg: bg,
                      surface: surface,
                      text: text,
                      muted: muted,
                      border: border,
                      accent: accent,
                    ),
                  ),
                  // Services
                  KeyedSubtree(
                    key: _servicesKey,
                    child: _ServicesSection(
                      dark: false,
                      isWide: isWide,
                      accent: accent,
                      text: text,
                      muted: muted,
                    ),
                  ),
                  // Pricing
                  KeyedSubtree(
                    key: _pricingKey,
                    child: _PricingSection(
                      dark: false,
                      isWide: isWide,
                      bg: bg,
                      surface: surface,
                      text: text,
                      muted: muted,
                      border: border,
                      accent: accent,
                      onBook: () => context.go('/auth?tab=reg'),
                    ),
                  ),
                  // Reviews
                  KeyedSubtree(
                    key: _reviewsKey,
                    child: _ReviewsSection(
                      dark: false,
                      isWide: isWide,
                      bg: bg,
                      surface: surface,
                      text: text,
                      muted: muted,
                      border: border,
                      accent: accent,
                      reviews: provider.reviews,
                      avgRating: provider.avgRating,
                      nameC: _reviewNameC,
                      serviceC: _reviewServiceC,
                      textC: _reviewTextC,
                      rating: _reviewRating,
                      loading: _reviewLoading,
                      onRating: (v) => setState(() => _reviewRating = v),
                      onSubmit: _submitReview,
                    ),
                  ),
                  // FAQ
                  KeyedSubtree(
                    key: _faqKey,
                    child: _FaqSection(
                      dark: false,
                      bg: bg,
                      surface: surface,
                      text: text,
                      muted: muted,
                      border: border,
                      accent: accent,
                      open: _faqOpen,
                      onToggle: (i) =>
                          setState(() => _faqOpen[i] = !_faqOpen[i]),
                    ),
                  ),
                  // CTA Banner
                  _CtaBanner(onBook: () => context.go('/auth?tab=reg')),
                  // Footer
                  _Footer(
                    dark: false,
                    text: text,
                    muted: muted,
                    border: border,
                    accent: accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navbar ────────────────────────────────────────────────────

class _Navbar extends StatelessWidget {
  final bool dark, isWide;
  final Color accent, surface, text, border;
  final VoidCallback onHowIt, onServices, onPricing, onReviews, onFaq;
  final VoidCallback onSignIn, onBookNow;

  const _Navbar({
    required this.dark,
    required this.isWide,
    required this.accent,
    required this.surface,
    required this.text,
    required this.border,
    required this.onHowIt,
    required this.onServices,
    required this.onPricing,
    required this.onReviews,
    required this.onFaq,
    required this.onSignIn,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: surface.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Logo
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: text,
                    ),
                    children: [
                      TextSpan(text: 'Laba'),
                      TextSpan(
                        text: 'Flow',
                        style: TextStyle(color: accent),
                      ),
                    ],
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 32),
                  _NavLink('How It Works', text, onHowIt),
                  _NavLink('Services', text, onServices),
                  _NavLink('Pricing', text, onPricing),
                  _NavLink('Reviews', text, onReviews),
                  _NavLink('FAQ', text, onFaq),
                ],
                const Spacer(),
                if (isWide) ...[
                  OutlinedButton(
                    onPressed: onSignIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: text,
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onBookNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Book Now'),
                  ),
                ] else
                  PopupMenuButton<int>(
                    tooltip: 'Open navigation menu',
                    icon: Icon(Icons.menu, color: text),
                    onSelected: (item) {
                      switch (item) {
                        case 0:
                          onHowIt();
                          break;
                        case 1:
                          onServices();
                          break;
                        case 2:
                          onPricing();
                          break;
                        case 3:
                          onReviews();
                          break;
                        case 4:
                          onFaq();
                          break;
                        case 5:
                          onSignIn();
                          break;
                        case 6:
                          onBookNow();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 0, child: Text('How It Works')),
                      PopupMenuItem(value: 1, child: Text('Services')),
                      PopupMenuItem(value: 2, child: Text('Pricing')),
                      PopupMenuItem(value: 3, child: Text('Reviews')),
                      PopupMenuItem(value: 4, child: Text('FAQ')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 5, child: Text('Sign In')),
                      PopupMenuItem(value: 6, child: Text('Book Now')),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavLink(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool dark, isWide;
  final Color bg, surface, text, muted, accent, border;
  final VoidCallback onBook, onSignIn;

  const _HeroSection({
    required this.dark,
    required this.isWide,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.border,
    required this.onBook,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isWide ? 80 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _HeroText(
                        text: text,
                        muted: muted,
                        accent: accent,
                        onBook: onBook,
                        onSignIn: onSignIn,
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/step-drop-off.jpg',
                              height: 210,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 210,
                                color: const Color(0xFFE0F2FE),
                                child: const Center(
                                  child: Icon(
                                    Icons.local_laundry_service_outlined,
                                    size: 56,
                                    color: AppColors.lightAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PricingCard(
                            surface: surface,
                            text: text,
                            muted: muted,
                            border: border,
                            accent: accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _HeroText(
                      text: text,
                      muted: muted,
                      accent: accent,
                      onBook: onBook,
                      onSignIn: onSignIn,
                    ),
                    const SizedBox(height: 32),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/step-drop-off.jpg',
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 190,
                          color: const Color(0xFFE0F2FE),
                          child: const Center(
                            child: Icon(
                              Icons.local_laundry_service_outlined,
                              size: 48,
                              color: AppColors.lightAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PricingCard(
                      surface: surface,
                      text: text,
                      muted: muted,
                      border: border,
                      accent: accent,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final Color text, muted, accent;
  final VoidCallback onBook, onSignIn;
  const _HeroText({
    required this.text,
    required this.muted,
    required this.accent,
    required this.onBook,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.3)),
          ),
          child: Text(
            'Lab-a-Day Laundry Shop',
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Fresh Laundry,\nZero Hassle.',
          style: TextStyle(
            color: text,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Professional laundry service with RFID tracking, loyalty rewards, and cashless payments. Drop off and we handle the rest.',
          style: TextStyle(color: muted, fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Book Now →'),
            ),
            OutlinedButton(
              onPressed: onSignIn,
              style: OutlinedButton.styleFrom(
                foregroundColor: text,
                side: BorderSide(color: text.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Sign In'),
            ),
            OutlinedButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              label: const Text('Track My Order'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _HeroNote(Icons.nfc, 'RFID order tracking', muted),
            _HeroNote(Icons.payments_outlined, 'Cash and GCash', muted),
            _HeroNote(Icons.loyalty_outlined, 'LabaPoints rewards', muted),
          ],
        ),
      ],
    );
  }
}

class _HeroNote extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color muted;
  const _HeroNote(this.icon, this.label, this.muted);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.lightAccent),
        Text(label, style: TextStyle(fontSize: 12, color: muted)),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final Color surface, text, muted, border, accent;
  const _PricingCard({
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.local_laundry_service, color: accent, size: 36),
          const SizedBox(height: 12),
          Text(
            'Quick Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          const SizedBox(height: 4),
          Text('Starting prices', style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 20),
          _PriceRow(
            Icons.checkroom_outlined,
            'Clothes',
            '₱180',
            'per 7 kg',
            text,
            muted,
            border,
          ),
          _PriceRow(
            Icons.bed_outlined,
            'Bedsheet',
            '₱190',
            'per 5 kg',
            text,
            muted,
            border,
          ),
          _PriceRow(
            Icons.king_bed_outlined,
            'Comforter',
            '₱200',
            'per pc',
            text,
            muted,
            border,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Earn LabaPoints with every wash!',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class _PriceRow extends StatelessWidget {
  final IconData icon;
  final String label, price, sub;
  final Color text, muted, border;
  const _PriceRow(
    this.icon,
    this.label,
    this.price,
    this.sub,
    this.text,
    this.muted,
    this.border,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: text),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: text,
                ),
              ),
              Text(sub, style: TextStyle(fontSize: 11, color: muted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Badges Row ────────────────────────────────────────────────

class _BadgesRow extends StatelessWidget {
  final bool dark;
  const _BadgesRow({required this.dark});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.water_drop_outlined, 'Surf Detergent'),
      (Icons.local_florist_outlined, 'Surf Conditioner'),
      (Icons.science_outlined, 'Zonrox Bleach'),
      (Icons.rss_feed, 'RFID Tracking'),
      (Icons.payments_outlined, 'GCash & Cash'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: AppColors.infoBg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 32,
            runSpacing: 14,
            children: items
                .map(
                  (item) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1, color: AppColors.lightAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          color: AppColors.lightText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ── How It Works ──────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final bool dark, isWide;
  final Color bg, surface, text, muted, border, accent;
  const _HowItWorks({
    required this.dark,
    required this.isWide,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
  });

  static const _steps = [
    (
      'assets/images/step-drop-off.jpg',
      'Drop Off',
      'Bring your laundry to our shop. We weigh, tag with RFID, and issue your digital receipt.',
    ),
    (
      'assets/images/step-wash-detergent.jpg',
      'We Wash & Dry',
      'Your laundry is washed with Surf, conditioned, and dried to perfection in our modern machines.',
    ),
    (
      'assets/images/step-ready-alert.jpg',
      'Ready Alert',
      'Receive a notification when your laundry is ready. Track real-time status in the app.',
    ),
    (
      'assets/images/step-pickup-pay.jpg',
      'Pick Up & Pay',
      'Collect your fresh laundry and pay via Cash or GCash. Earn LabaPoints for every visit!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isWide ? 72 : 48),
      color: bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _SectionHeader(
                'Ready in 4 Easy Steps',
                'From drop-off to pickup, every order is tracked along the way.',
                text,
                muted,
                accent,
              ),
              const SizedBox(height: 40),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _steps
                          .asMap()
                          .entries
                          .map(
                            (e) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: e.key < _steps.length - 1 ? 20 : 0,
                                ),
                                child: _StepCard(
                                  step: e.key + 1,
                                  image: e.value.$1,
                                  title: e.value.$2,
                                  desc: e.value.$3,
                                  surface: surface,
                                  text: text,
                                  muted: muted,
                                  border: border,
                                  accent: accent,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : Column(
                      children: _steps
                          .asMap()
                          .entries
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _StepCard(
                                step: e.key + 1,
                                image: e.value.$1,
                                title: e.value.$2,
                                desc: e.value.$3,
                                surface: surface,
                                text: text,
                                muted: muted,
                                border: border,
                                accent: accent,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String image, title, desc;
  final Color surface, text, muted, border, accent;
  const _StepCard({
    required this.step,
    required this.image,
    required this.title,
    required this.desc,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(image, fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$step',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(color: muted, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

// ── Services ──────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  final bool dark, isWide;
  final Color accent, text, muted;
  const _ServicesSection({
    required this.dark,
    required this.isWide,
    required this.accent,
    required this.text,
    required this.muted,
  });

  static const _services = [
    (
      Icons.local_laundry_service_outlined,
      'Full Wash & Dry',
      'clothes',
      'Complete wash, dry, and fold service for everyday clothing. Includes Surf detergent and conditioner.',
      'assets/images/service-clothes.jpg',
    ),
    (
      Icons.bed_outlined,
      'Bedsheet Wash',
      'bedsheet',
      'Deep clean for bedsheets, pillowcases, and bed covers. Fresh and sanitized every time.',
      'assets/images/service-bedsheets.jpg',
    ),
    (
      Icons.king_bed_outlined,
      'Comforter Wash',
      'comforter',
      'Heavy-duty washing for thick comforters and duvets. Proper drying ensures no moisture remains.',
      'assets/images/service-comforter.jpg',
    ),
    (
      Icons.local_drink_outlined,
      'Surf Liquid Detergent',
      'surf_detergent',
      'We use Surf Liquid Detergent — tough on stains, gentle on fabrics, fresh scent every wash.',
      'assets/images/step-wash-detergent.jpg',
    ),
    (
      Icons.spa_outlined,
      'Surf Fabric Conditioner',
      'surf_conditioner',
      'Surf Fabric Conditioner on every load — softer clothes, long-lasting freshness.',
      'assets/images/step-wash-detergent.jpg',
    ),
    (
      Icons.cleaning_services_outlined,
      'Zonrox Color Safe',
      'zonrox_colorsafe',
      'Color-safe oxygen bleach helps lift tough stains while protecting colored fabrics.',
      'assets/images/service-zonrox-colorsafe.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isWide ? 72 : 48),
      decoration: const BoxDecoration(color: Color(0xFFF0F8FC)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _SectionHeader(
                'Our Services',
                'Everything you need for fresh, clean laundry',
                text,
                AppColors.lpMuted,
                accent,
              ),
              const SizedBox(height: 40),
              isWide ? _buildGrid() : _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      children: [
        Row(
          children: _services
              .take(3)
              .map(
                (s) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: s != _services[2] ? 16 : 0),
                    child: _ServiceCard(
                      icon: s.$1,
                      title: s.$2,
                      desc: s.$4,
                      accent: accent,
                      image: s.$5,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: _services
              .skip(3)
              .map(
                (s) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: s != _services.last ? 16 : 0,
                    ),
                    child: _ServiceCard(
                      icon: s.$1,
                      title: s.$2,
                      desc: s.$4,
                      accent: accent,
                      image: s.$5,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildList() {
    return Column(
      children: _services
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceCard(
                icon: s.$1,
                title: s.$2,
                desc: s.$4,
                accent: accent,
                image: s.$5,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color accent;
  final String? image;
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.accent,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.lpBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(
                  image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE0F2FE),
                    child: Icon(icon, color: accent, size: 40),
                  ),
                ),
              ),
            )
          else
            Icon(icon, color: accent, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.lpText,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(
              color: AppColors.lpMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pricing ───────────────────────────────────────────────────

class _PricingSection extends StatelessWidget {
  final bool dark, isWide;
  final Color bg, surface, text, muted, border, accent;
  final VoidCallback onBook;
  const _PricingSection({
    required this.dark,
    required this.isWide,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isWide ? 72 : 48),
      color: bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _SectionHeader(
                'Transparent Pricing',
                'No hidden fees. Pay only for what you wash.',
                text,
                muted,
                accent,
              ),
              const SizedBox(height: 40),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PricingDetailCard(
                            icon: Icons.checkroom_outlined,
                            title: 'Clothes',
                            subtitle: 'Full Wash & Dry',
                            price: '₱180',
                            unit: 'for 7 kg',
                            features: [
                              'Base: ₱180 for up to 7 kg',
                              '+₱25 per extra kg',
                              'Sets of 9kg for 10kg+',
                              'Surf detergent + conditioner',
                              'Wash, dry & fold',
                            ],
                            surface: surface,
                            text: text,
                            muted: muted,
                            border: border,
                            accent: accent,
                            onBook: onBook,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _PricingDetailCard(
                            icon: Icons.bed_outlined,
                            title: 'Bedsheet',
                            subtitle: 'Bedding & Linen',
                            price: '₱190',
                            unit: 'for 5 kg',
                            features: [
                              'Base: ₱190 for up to 5 kg',
                              '+₱38 per extra kg',
                              'Includes pillowcases',
                              'Deep sanitize wash',
                              'Hygienic drying',
                            ],
                            surface: surface,
                            text: text,
                            muted: muted,
                            border: border,
                            accent: accent,
                            onBook: onBook,
                            featured: true,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _PricingDetailCard(
                            icon: Icons.king_bed_outlined,
                            title: 'Comforter',
                            subtitle: 'Heavy Bedding',
                            price: '₱200',
                            unit: 'per piece',
                            features: [
                              '₱200 per comforter',
                              'Thick duvet capable',
                              'Industrial-grade wash',
                              'Full drying guaranteed',
                              'No moisture retained',
                            ],
                            surface: surface,
                            text: text,
                            muted: muted,
                            border: border,
                            accent: accent,
                            onBook: onBook,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _PricingDetailCard(
                          icon: Icons.checkroom_outlined,
                          title: 'Clothes',
                          subtitle: 'Full Wash & Dry',
                          price: '₱180',
                          unit: 'for 7 kg',
                          features: [
                            'Base: ₱180 for up to 7 kg',
                            '+₱25 per extra kg',
                            'Sets of 9kg for 10kg+',
                            'Surf detergent + conditioner',
                            'Wash, dry & fold',
                          ],
                          surface: surface,
                          text: text,
                          muted: muted,
                          border: border,
                          accent: accent,
                          onBook: onBook,
                        ),
                        const SizedBox(height: 16),
                        _PricingDetailCard(
                          icon: Icons.bed_outlined,
                          title: 'Bedsheet',
                          subtitle: 'Bedding & Linen',
                          price: '₱190',
                          unit: 'for 5 kg',
                          features: [
                            'Base: ₱190 for up to 5 kg',
                            '+₱38 per extra kg',
                            'Includes pillowcases',
                            'Deep sanitize wash',
                            'Hygienic drying',
                          ],
                          surface: surface,
                          text: text,
                          muted: muted,
                          border: border,
                          accent: accent,
                          onBook: onBook,
                          featured: true,
                        ),
                        const SizedBox(height: 16),
                        _PricingDetailCard(
                          icon: Icons.king_bed_outlined,
                          title: 'Comforter',
                          subtitle: 'Heavy Bedding',
                          price: '₱200',
                          unit: 'per piece',
                          features: [
                            '₱200 per comforter',
                            'Thick duvet capable',
                            'Industrial-grade wash',
                            'Full drying guaranteed',
                            'No moisture retained',
                          ],
                          surface: surface,
                          text: text,
                          muted: muted,
                          border: border,
                          accent: accent,
                          onBook: onBook,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingDetailCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, price, unit;
  final List<String> features;
  final Color surface, text, muted, border, accent;
  final VoidCallback onBook;
  final bool featured;
  const _PricingDetailCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.unit,
    required this.features,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
    required this.onBook,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: featured ? accent.withOpacity(0.08) : surface,
        border: Border.all(
          color: featured ? accent : border,
          width: featured ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (featured)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Most Popular',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Icon(icon, color: accent, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: TextStyle(color: text),
              children: [
                TextSpan(
                  text: price,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: featured ? accent : accent.withOpacity(0.15),
                foregroundColor: featured ? Colors.white : accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Book This Service',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reviews ───────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final bool dark, isWide;
  final Color bg, surface, text, muted, border, accent;
  final List<Review> reviews;
  final double avgRating;
  final TextEditingController nameC, serviceC, textC;
  final int rating;
  final bool loading;
  final ValueChanged<int> onRating;
  final VoidCallback onSubmit;
  const _ReviewsSection({
    required this.dark,
    required this.isWide,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
    required this.reviews,
    required this.avgRating,
    required this.nameC,
    required this.serviceC,
    required this.textC,
    required this.rating,
    required this.loading,
    required this.onRating,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const inputBg = Color(0xFFF9FAFB);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isWide ? 72 : 48),
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _SectionHeader(
                'Customer Reviews',
                'What our customers say about us',
                text,
                muted,
                accent,
              ),
              const SizedBox(height: 8),
              if (reviews.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < avgRating.round() ? Icons.star : Icons.star_border,
                        color: const Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${avgRating.toStringAsFixed(1)} (${reviews.length} reviews)',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              // Reviews grid
              if (reviews.isNotEmpty) ...[
                isWide ? _buildReviewGrid() : _buildReviewList(),
                const SizedBox(height: 40),
              ],
              // Submission form
              _ReviewForm(
                surface: surface,
                text: text,
                muted: muted,
                border: border,
                accent: accent,
                inputBg: inputBg,
                nameC: nameC,
                serviceC: serviceC,
                textC: textC,
                rating: rating,
                loading: loading,
                onRating: onRating,
                onSubmit: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewGrid() {
    final chunks = <List<Review>>[];
    for (int i = 0; i < reviews.length; i += 3) {
      chunks.add(reviews.skip(i).take(3).toList());
    }
    return Column(
      children: chunks
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: e.key < row.length - 1 ? 16 : 0,
                          ),
                          child: _ReviewCard(
                            review: e.value,
                            surface: surface,
                            text: text,
                            muted: muted,
                            border: border,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildReviewList() {
    return Column(
      children: reviews
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(
                review: r,
                surface: surface,
                text: text,
                muted: muted,
                border: border,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final Color surface, text, muted, border;
  const _ReviewCard({
    required this.review,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.lpAccent.withOpacity(0.15),
                radius: 18,
                child: Text(
                  review.name.isNotEmpty ? review.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.lpAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      review.service,
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFF59E0B),
                size: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            review.text,
            style: TextStyle(color: muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  final Color surface, text, muted, border, accent, inputBg;
  final TextEditingController nameC, serviceC, textC;
  final int rating;
  final bool loading;
  final ValueChanged<int> onRating;
  final VoidCallback onSubmit;
  const _ReviewForm({
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
    required this.inputBg,
    required this.nameC,
    required this.serviceC,
    required this.textC,
    required this.rating,
    required this.loading,
    required this.onRating,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave a Review',
            style: TextStyle(
              color: text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _LpField(
                  controller: nameC,
                  label: 'Your Name',
                  hint: 'Juan dela Cruz',
                  inputBg: inputBg,
                  text: text,
                  border: border,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _LpField(
                  controller: serviceC,
                  label: 'Service Used',
                  hint: 'Clothes Wash, Bedsheet...',
                  inputBg: inputBg,
                  text: text,
                  border: border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Star rating
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RATING',
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => onRating(i + 1),
                    child: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFF59E0B),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LpField(
            controller: textC,
            label: 'Your Review',
            hint: 'Tell us about your experience...',
            inputBg: inputBg,
            text: text,
            border: border,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LpField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final Color inputBg, text, border;
  final int maxLines;
  const _LpField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.inputBg,
    required this.text,
    required this.border,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: text.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: 13, color: text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: text.withOpacity(0.35)),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.lpAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── FAQ ───────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  final bool dark;
  final Color bg, surface, text, muted, border, accent;
  final List<bool> open;
  final ValueChanged<int> onToggle;
  const _FaqSection({
    required this.dark,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
    required this.open,
    required this.onToggle,
  });

  static const _items = [
    (
      'How long does laundry take?',
      'Standard turnaround is same-day for items dropped off before 10 AM. Otherwise, your laundry is ready by the next morning. You will receive a notification when it\'s ready.',
    ),
    (
      'How does RFID tracking work?',
      'Each batch is tagged with a unique RFID chip. You can track your laundry\'s real-time status — from drop-off, through washing and drying, all the way to ready for pickup — right in the app.',
    ),
    (
      'What detergents do you use?',
      'We use Surf Detergent for washing, Surf Conditioner for softening and fragrance, and Zonrox Bleach for white items (only when requested or appropriate).',
    ),
    (
      'How do I pay?',
      'We accept Cash and GCash. Payment is made upon pickup. For GCash, just show your reference number to the staff.',
    ),
    (
      'What are LabaPoints?',
      'Every peso you spend earns you LabaPoints. Accumulate points to climb tiers (Bronze → Silver → Gold → Platinum) and unlock percentage discounts on future orders.',
    ),
    (
      'Can I book in advance?',
      'Yes! Use the Book Service feature in the app to schedule your laundry. This helps us prepare and ensures faster processing when you arrive.',
    ),
    (
      'What if my item is lost or damaged?',
      'We take full responsibility for items in our care. RFID tracking minimizes mix-ups. In the rare event of an issue, please contact us immediately and we will resolve it promptly.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _SectionHeader(
                'Frequently Asked Questions',
                'Everything you need to know',
                text,
                muted,
                accent,
              ),
              const SizedBox(height: 32),
              ..._items.asMap().entries.map(
                (e) => _FaqItem(
                  question: e.value.$1,
                  answer: e.value.$2,
                  isOpen: open[e.key],
                  onToggle: () => onToggle(e.key),
                  surface: surface,
                  text: text,
                  muted: muted,
                  border: border,
                  accent: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question, answer;
  final bool isOpen;
  final VoidCallback onToggle;
  final Color surface, text, muted, border, accent;
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isOpen,
    required this.onToggle,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: isOpen ? accent : border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Text(
                answer,
                style: TextStyle(color: muted, fontSize: 13, height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}

// ── CTA Banner ────────────────────────────────────────────────

class _CtaBanner extends StatelessWidget {
  final VoidCallback onBook;
  const _CtaBanner({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lpAccent, AppColors.lpAccent2],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const Text(
                'Ready for Fresh Laundry?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Join hundreds of happy customers enjoying hassle-free laundry service.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.lpAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Book Now →'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool dark;
  final Color text, muted, border, accent;
  const _Footer({
    required this.dark,
    required this.text,
    required this.muted,
    required this.border,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: bg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _FooterBrand()),
                        Expanded(
                          child: _FooterCol('Services', [
                            'Full Wash & Dry',
                            'Bedsheet Wash',
                            'Comforter Wash',
                            'Wash Only',
                            'Dry Only',
                          ]),
                        ),
                        Expanded(
                          child: _FooterCol('Features', [
                            'RFID Tracking',
                            'LabaPoints',
                            'GCash Payments',
                            'Real-time Status',
                            'Mobile App',
                          ]),
                        ),
                        Expanded(
                          child: _FooterCol('Contact', [
                            'Lab-a-Day Laundry',
                            'General Santos City',
                            'labaday@gmail.com',
                            '09XX XXX XXXX',
                          ]),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FooterBrand(),
                      const SizedBox(height: 24),
                      _FooterCol('Services', [
                        'Full Wash & Dry',
                        'Bedsheet Wash',
                        'Comforter Wash',
                      ]),
                      const SizedBox(height: 20),
                      _FooterCol('Contact', [
                        'Lab-a-Day Laundry',
                        'General Santos City',
                        'labaday@gmail.com',
                      ]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Divider(color: AppColors.lightBorder),
              const SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} Lab-a-Day Laundry. All rights reserved.',
                style: const TextStyle(
                  color: AppColors.lightMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'LabaFlow',
          style: const TextStyle(
            color: AppColors.lightText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Lab-a-Day Laundry Management System. Professional laundry service with modern tech.',
          style: TextStyle(
            color: AppColors.lightMuted,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _FooterCol extends StatelessWidget {
  final String title;
  final List<String> items;
  const _FooterCol(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.lightText,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              item,
              style: const TextStyle(color: AppColors.lightMuted, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final Color text, muted, accent;
  const _SectionHeader(
    this.title,
    this.subtitle,
    this.text,
    this.muted,
    this.accent,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: text,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: muted, fontSize: 15, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
