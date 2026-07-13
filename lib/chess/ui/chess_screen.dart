import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../controller/chess_controller.dart';
import 'chess_board.dart';

class ChessScreen extends ConsumerWidget {
  const ChessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessControllerProvider);
    final controller = ref.read(chessControllerProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.gap),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(state.status,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: controller.newGame,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.gap),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ChessBoard(
                        fen: state.fen,
                        enabled: !state.thinking &&
                            !state.isGameOver &&
                            state.isWhiteToMove,
                        lastFrom: state.lastFrom,
                        lastTo: state.lastTo,
                        onMove: controller.playHumanMove,
                      ),
                    ),
                  ),
                ),
              ),
              if (state.isGameOver)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(state.status,
                              style: Theme.of(context).textTheme.headlineMedium)
                          .animate()
                          .fadeIn()
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: AppTheme.gap),
                      FilledButton(
                        onPressed: controller.newGame,
                        child: const Text('New game'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
