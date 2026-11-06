import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ═══════════════════════════════════════════════════════════
//  SHARED WIDGETS
//  Reusable components mirroring the HTML CSS classes
// ═══════════════════════════════════════════════════════════

/// A quiet soap-bubble motif for the background of app dashboards.
class OceanicBubbleBackground extends StatelessWidget {
  const OceanicBubbleBackground({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
        child: CustomPaint(
          painter: _OceanicBubblePainter(),
          child: SizedBox.expand(),
        ),
      );
}

class _OceanicBubblePainter extends CustomPainter {
  const _OceanicBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const bubbles = [
      (0.04, 0.08, 0.045),
      (0.92, 0.11, 0.070),
      (0.84, 0.34, 0.028),
      (0.08, 0.55, 0.026),
      (0.97, 0.70, 0.046),
      (0.12, 0.91, 0.060),
      (0.68, 0.93, 0.025),
      (0.77, 0.63, 0.035),
    ];
    final bubbleScale = size.shortestSide;
    final fill = Paint()
      ..color = const Color(0x245DC5CC)
      ..style = PaintingStyle.fill;
    final rim = Paint()
      ..color = const Color(0x3D078695)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final shine = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final bubble in bubbles) {
      final center = Offset(size.width * bubble.$1, size.height * bubble.$2);
      final radius = bubbleScale * bubble.$3;
      canvas.drawCircle(center, radius, fill);
      canvas.drawCircle(center, radius, rim);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * .72),
        3.55,
        1.1,
        false,
        shine,
      );
    }

    final waves = Paint()
      ..color = const Color(0x2471BFC3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (var band = 0; band < 2; band++) {
      final y = size.height * (.84 + band * .055);
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * .28,
          y - size.height * .035,
          size.width * .58,
          y + size.height * .025,
          size.width,
          y - size.height * .015,
        );
      canvas.drawPath(path, waves);
    }
  }

  @override
  bool shouldRepaint(covariant _OceanicBubblePainter oldDelegate) => false;
}

class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const PasswordInputField({
    super.key,
    required this.controller,
    required this.decoration,
    this.style,
    this.keyboardType = TextInputType.visiblePassword,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final label = _obscured ? 'Show password' : 'Hide password';
    return TextField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      style: widget.style,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: widget.decoration.copyWith(
        suffixIcon: IconButton(
          tooltip: label,
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}

// ── Status Badge ────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case OrderStatus.pending:
        bg = const Color(0xFFEFF6FF);
        fg = AppColors.statusPending;
        break;
      case OrderStatus.received:
        bg = const Color(0xFFE0F2FE);
        fg = AppColors.statusReceived;
        break;
      case OrderStatus.processing:
        bg = const Color(0xFFFEF3C7);
        fg = AppColors.statusProcessing;
        break;
      case OrderStatus.ready:
        bg = const Color(0xFFDCFCE7);
        fg = AppColors.statusReady;
        break;
      case OrderStatus.released:
        bg = const Color(0xFFEDE9FE);
        fg = AppColors.statusReleased;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        status.key,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ── Role Badge ──────────────────────────────────────────────

class RoleBadge extends StatelessWidget {
  final UserRole role;
  const RoleBadge(this.role, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (role) {
      case UserRole.admin:
        bg = const Color(0x267DD3FC);
        fg = AppColors.lightAccent;
        break;
      case UserRole.seller:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case UserRole.customer:
        bg = const Color(0x1FB8D4F0);
        fg = AppColors.lightMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        role.name,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: valueColor ?? theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card with Header ────────────────────────────────────────

class AppCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets? padding;
  const AppCard({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.brightness == Brightness.dark
        ? AppColors.lightBorder
        : AppColors.lightBorder;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Progress Bar (Inventory Level) ──────────────────────────

class LevelBar extends StatelessWidget {
  final double pct;
  const LevelBar({super.key, required this.pct});

  @override
  Widget build(BuildContext context) {
    final isLow = pct <= 25;
    final color = pct > 50
        ? AppColors.success
        : pct > 20
        ? AppColors.warn
        : AppColors.danger;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isLow ? AppColors.danger : AppColors.success,
              ),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${pct.round()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Notice Banner ───────────────────────────────────────────

class NoticeBanner extends StatelessWidget {
  final String text;
  final NoticeType type;
  const NoticeBanner({
    super.key,
    required this.text,
    this.type = NoticeType.info,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, fg;
    switch (type) {
      case NoticeType.warn:
        bg = const Color(0x1AFBBF24);
        border = const Color(0x4DFBBF24);
        fg = AppColors.warn;
        break;
      case NoticeType.success:
        bg = const Color(0x1434D399);
        border = const Color(0x4034D399);
        fg = AppColors.success;
        break;
      case NoticeType.error:
        bg = const Color(0x1AFB7185);
        border = const Color(0x4DFB7185);
        fg = AppColors.danger;
        break;
      default:
        bg = const Color(0x1438BDF8);
        border = const Color(0x3338BDF8);
        fg = AppColors.lightAccent2;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}

enum NoticeType { info, warn, success, error }

// ── Promo Tag ───────────────────────────────────────────────

class PromoTag extends StatelessWidget {
  final String code;
  const PromoTag(this.code, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x2EC4B5FD),
        border: Border.all(color: const Color(0x4DC4B5FD)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '🏷 $code',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC4B5FD),
        ),
      ),
    );
  }
}

// ── Loyalty Tier Badge ──────────────────────────────────────

class TierBadge extends StatelessWidget {
  final LoyaltyTier tier;
  const TierBadge(this.tier, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = Color(tier.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tier.name,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Order Timeline ──────────────────────────────────────────

class OrderTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  const OrderTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statuses = OrderStatus.values;
    final si = statuses.indexOf(currentStatus);
    return Row(
      children: statuses.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        Color dotColor;
        Color lineColor;
        if (i < si) {
          dotColor = AppColors.success;
          lineColor = AppColors.success;
        } else if (i == si) {
          dotColor = AppColors.lightBtn;
          lineColor = AppColors.lightBorder;
        } else {
          dotColor = AppColors.lightBorder;
          lineColor = AppColors.lightBorder;
        }
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= si
                            ? AppColors.success
                            : AppColors.lightBorder,
                      ),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (i < statuses.length - 1)
                    Expanded(child: Container(height: 2, color: lineColor)),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                s.key,
                style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.lightMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Primary Button ──────────────────────────────────────────

class PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryBtn({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
            : Text(label),
      ),
    );
  }
}

// ── Dialog utilities ────────────────────────────────────────

/// Consistent empty state for lists and dashboard panels.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.lightDim),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.lightText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.lightMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showSuccessDialog(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog(
    context: context,
    builder: (_) => _LabaDialog(
      icon: Icons.check_circle,
      iconColor: AppColors.success,
      title: title,
      message: message,
    ),
  );
}

Future<void> showErrorDialog(BuildContext context, String message) {
  return showDialog(
    context: context,
    builder: (_) => _LabaDialog(
      icon: Icons.error,
      iconColor: AppColors.danger,
      title: 'Error',
      message: message,
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Yes',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _LabaDialog(
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warn,
      title: title,
      message: message,
      confirmText: confirmText,
      showCancel: true,
    ),
  );
  return result ?? false;
}

class _LabaDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? confirmText;
  final bool showCancel;
  const _LabaDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.confirmText,
    this.showCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white;
    final border = AppColors.lightBorder;
    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.lightText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.lightMuted,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showCancel) ...[
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.lightText),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, showCancel ? true : null),
                  child: Text(confirmText ?? 'OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading Overlay ──────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final String message;
  const LoadingOverlay({super.key, this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xE6F0F4F8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightAccent2),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.lightText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
