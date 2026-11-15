import 'package:flutter/material.dart';
import '../models/roblox_game.dart';

/// Banner for a game. Priority: user's picture -> local asset thumbnail ->
/// colour gradient + icon. Optionally shows a small chip (game.badge).
class GameBanner extends StatelessWidget {
  final RobloxGame game;
  final double? height;
  final double radius;
  final double iconSize;

  const GameBanner({
    super.key,
    required this.game,
    this.height,
    this.radius = 12,
    this.iconSize = 48,
  });

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [game.bannerColor, Color.lerp(game.bannerColor, Colors.black, 0.55)!],
        ),
      ),
      child: Center(child: Icon(game.icon, size: iconSize, color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = game.imageBytes;

    Widget content;
    if (bytes != null) {
      content = Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (game.assetImage != null) {
      content = Image.asset(
        game.assetImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      content = _fallback();
    }

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (game.badge != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  game.badge!,
                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
