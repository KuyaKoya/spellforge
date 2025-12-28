import 'package:flutter/material.dart';
import '../../domain/enemy.dart';

/// Enemy sprite overlay that displays animated GIF sprites.
/// 
/// Since Flame doesn't have native GIF support, we use Flutter's Image widget
/// with the enemy sprites positioned over the Flame canvas.
class EnemySpriteOverlay extends StatelessWidget {
  final List<Enemy> enemies;
  final int? highlightedIndex;
  final void Function(int index)? onTap;

  const EnemySpriteOverlay({
    super.key,
    required this.enemies,
    this.highlightedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: enemies.asMap().entries.map((entry) {
            final index = entry.key;
            final enemy = entry.value;
            
            // Calculate position based on enemy count
            final enemyCount = enemies.length;
            double leftFactor, topFactor;
            
            if (enemyCount == 1) {
              leftFactor = 0.60;
              topFactor = 0.15;
            } else if (enemyCount == 2) {
              leftFactor = 0.55 + index * 0.12;
              topFactor = 0.12 + index * 0.10;
            } else {
              leftFactor = 0.50 + index * 0.10;
              topFactor = 0.08 + index * 0.12;
            }
            
            return Positioned(
              left: constraints.maxWidth * leftFactor,
              top: constraints.maxHeight * topFactor,
              child: _AnimatedEnemySprite(
                enemy: enemy,
                isHighlighted: index == highlightedIndex,
                onTap: () => onTap?.call(index),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Individual animated enemy sprite
class _AnimatedEnemySprite extends StatefulWidget {
  final Enemy enemy;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _AnimatedEnemySprite({
    required this.enemy,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  State<_AnimatedEnemySprite> createState() => _AnimatedEnemySpriteState();
}

class _AnimatedEnemySpriteState extends State<_AnimatedEnemySprite>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get the sprite asset path for this enemy
  String? get _spriteAssetPath {
    switch (widget.enemy.id) {
      case 'fireImp':
        return 'assets/enemy_sprites/fire_imp.gif';
      case 'flameSerpent':
        return 'assets/enemy_sprites/fire_serpent.gif';
      case 'waterSprite':
      case 'waterSpirit':
        return 'assets/enemy_sprites/water spirit.gif';
      case 'seaSerpent':
      case 'seaStalker':
        return 'assets/enemy_sprites/sea_serpent.gif';
      case 'earthGolem':
        return 'assets/enemy_sprites/earth_golem.gif';
      default:
        return null;
    }
  }

  Color get _elementColor {
    switch (widget.enemy.element.name) {
      case 'fire':
        return const Color(0xFFf85149);
      case 'water':
        return const Color(0xFF58a6ff);
      case 'earth':
        return const Color(0xFF7c6f4a);
      case 'air':
        return const Color(0xFF79c0ff);
      default:
        return const Color(0xFF8b949e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _spriteAssetPath;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.translate(
            offset: Offset(0, -_bounceAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  // Element glow
                  BoxShadow(
                    color: _elementColor.withValues(alpha: _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: widget.isHighlighted ? 5 : 2,
                  ),
                  // Highlight glow
                  if (widget.isHighlighted)
                    BoxShadow(
                      color: const Color(0xFFe3b341).withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: widget.isHighlighted
                        ? Border.all(color: const Color(0xFFe3b341), width: 3)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: assetPath != null
                      ? _buildGifSprite(assetPath)
                      : _buildFallbackSprite(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGifSprite(String assetPath) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if GIF fails to load
        return _buildFallbackSprite();
      },
    );
  }

  Widget _buildFallbackSprite() {
    final icon = switch (widget.enemy.element.name) {
      'fire' => '🔥',
      'water' => '💧',
      'earth' => '🪨',
      'air' => '💨',
      _ => '👹',
    };

    return Container(
      color: _elementColor.withValues(alpha: 0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(
              widget.enemy.name,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFFc9d1d9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Player sprite component that could be enhanced with animations
class PlayerSpriteOverlay extends StatefulWidget {
  final String element;
  final bool isCasting;
  final bool isHit;

  const PlayerSpriteOverlay({
    super.key,
    required this.element,
    this.isCasting = false,
    this.isHit = false,
  });

  @override
  State<PlayerSpriteOverlay> createState() => _PlayerSpriteOverlayState();
}

class _PlayerSpriteOverlayState extends State<PlayerSpriteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _elementColor {
    switch (widget.element) {
      case 'fire':
        return const Color(0xFFf85149);
      case 'water':
        return const Color(0xFF58a6ff);
      case 'earth':
        return const Color(0xFF7c6f4a);
      case 'air':
        return const Color(0xFF79c0ff);
      default:
        return const Color(0xFF8b949e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Color overlayColor = Colors.transparent;
        if (widget.isCasting) {
          overlayColor = _elementColor.withValues(alpha: 0.3);
        } else if (widget.isHit) {
          overlayColor = const Color(0xFFf85149).withValues(alpha: 0.3);
        }

        return Transform.translate(
          offset: Offset(0, -_breathAnimation.value),
          child: Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _elementColor.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: _elementColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                if (widget.isCasting)
                  BoxShadow(
                    color: _elementColor.withValues(alpha: 0.6),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262d),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // State overlay
                if (overlayColor != Colors.transparent)
                  Container(
                    decoration: BoxDecoration(
                      color: overlayColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                // Mage icon
                const Center(
                  child: Text('🧙', style: TextStyle(fontSize: 48)),
                ),
                // Element indicator
                Positioned(
                  right: 4,
                  top: 4,
                  child: Text(
                    switch (widget.element) {
                      'fire' => '🔥',
                      'water' => '💧',
                      'earth' => '🪨',
                      'air' => '💨',
                      _ => '✨',
                    },
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
