// ════════════════════════════════════════════════════════════════
// 設定頁 - 主題切換器
// ════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_themes.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final groups = AppThemes.grouped();
    final order = ['default', 'korean', 'japanese', 'dark', 'anime'];

    return Scaffold(
      backgroundColor: theme.bgBody,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '主題設定',
          style: GoogleFonts.getFont(
            theme.fontTitleFamily,
            fontWeight: FontWeight.w900,
            color: theme.ink,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: theme.ink),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 目前主題介紹
          _CurrentThemeCard(theme: theme),
          const SizedBox(height: 18),

          // 分區段渲染
          for (final family in order)
            if (groups[family] != null) ...[
              _SectionTitle(label: kFamilyLabels[family]!, theme: theme),
              const SizedBox(height: 8),
              for (final t in groups[family]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ThemeOptionCard(
                    option: t,
                    selected: t.key == theme.key,
                    current: theme,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(themeProvider.notifier).setTheme(t.key);
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

// ─── 目前主題卡 ─────────────────────────────────
class _CurrentThemeCard extends StatelessWidget {
  final AppThemeData theme;
  const _CurrentThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: theme.cardBlur, sigmaY: theme.cardBlur),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primary, theme.accent],
            ),
            borderRadius: BorderRadius.circular(theme.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (theme.motif != null) ...[
                    Text(
                      theme.motif!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '目前主題',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                theme.name,
                style: GoogleFonts.getFont(
                  theme.fontTitleFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                theme.sub,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                theme.tagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 區段標題 ─────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  final AppThemeData theme;
  const _SectionTitle({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
      child: Row(
        children: [
          Container(
            width: 4, height: 14,
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.getFont(
              theme.fontTitleFamily,
              fontWeight: FontWeight.w900,
              color: theme.ink,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 主題選項卡 ───────────────────────────────
class _ThemeOptionCard extends StatelessWidget {
  final AppThemeData option;
  final AppThemeData current;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.option,
    required this.current,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: current.bgCard,
          borderRadius: BorderRadius.circular(current.radius * 0.8),
          border: Border.all(
            color: selected ? option.accent : current.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: option.accent.withValues(alpha: 0.18),
                blurRadius: 14,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 色票預覽 (主題色三色組)
            _SwatchPreview(option: option, currentRadius: current.radius * 0.5),
            const SizedBox(width: 12),
            // 名稱 + 副標
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (option.motif != null) ...[
                        Text(
                          option.motif!,
                          style: TextStyle(
                              fontSize: 14,
                              color: option.accent,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          option.name,
                          style: GoogleFonts.getFont(
                            current.fontTitleFamily,
                            fontWeight: FontWeight.w900,
                            color: current.ink,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.sub,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: current.ink2,
                        letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 勾選圖示
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: selected ? option.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? option.accent : current.divider,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// 色票預覽方塊 (上半 primary, 下半 accent + 三條 tag 色)
class _SwatchPreview extends StatelessWidget {
  final AppThemeData option;
  final double currentRadius;
  const _SwatchPreview({required this.option, required this.currentRadius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(currentRadius),
      child: SizedBox(
        width: 56, height: 56,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Container(color: option.primary)),
                  Expanded(child: Container(color: option.accent)),
                ],
              ),
            ),
            SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(child: Container(color: option.tagFood)),
                  Expanded(child: Container(color: option.tagSight)),
                  Expanded(child: Container(color: option.tagTransport)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
