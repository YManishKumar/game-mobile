import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.surface, Color(0xFF1D2740)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: widget.enabled ? 0.25 : 0.0),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppTheme.surfaceGlass),
          ),
          padding: const EdgeInsets.all(AppTheme.gap),
          child: Row(
            children: [
              Icon(widget.icon, size: 56, color: AppTheme.accentGlow),
              const SizedBox(width: AppTheme.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textMuted)),
                    if (!widget.enabled)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Coming soon',
                            style: TextStyle(color: AppTheme.textMuted)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
    );
  }
}
