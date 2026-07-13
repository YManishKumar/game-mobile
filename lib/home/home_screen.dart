import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/router.dart';
import '../app/theme.dart';
import '../shared/widgets/game_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('Board Games',
                        style: Theme.of(context).textTheme.displaySmall)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.15, curve: Curves.easeOutCubic),
                const SizedBox(height: 6),
                Text('Play offline. Beat the AI.',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 40),
                GameCard(
                  title: 'Chess',
                  subtitle: 'Classic strategy vs AI',
                  icon: Icons.grid_view_rounded,
                  onTap: () => Navigator.of(context).pushNamed(Routes.chess),
                ),
                const SizedBox(height: AppTheme.gap),
                GameCard(
                  title: 'Dugna',
                  subtitle: 'Dominoes vs AI',
                  icon: Icons.casino_rounded,
                  enabled: false, // wired in the Dugna plan
                  onTap: () {},
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
