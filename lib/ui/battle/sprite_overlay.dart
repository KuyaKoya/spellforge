import 'package:flutter/material.dart';
import '../../domain/enemy.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENEMY SPRITE OVERLAY
/// Position: Zone 1 (Top 35% enemy area) - centered, elevated
/// ═══════════════════════════════════════════════════════════════════════════
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
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Zone 1 height (top 35% + some battlefield intrusion)
        final zone1Height = screenHeight * 0.40;

        return Stack(
          children: enemies.asMap().entries.map((entry) {
            final index = entry.key;
            final enemy = entry.value;

            // Calculate position based on enemy count
            // Enemies should be centered in the upper area
            final enemyCount = enemies.length;

            double leftFactor;
            double topFactor;
            double spriteScale;

            if (enemyCount == 1) {
              // Single enemy: further right (Pokémon style)
              leftFactor = 0.72;
              topFactor = 0.20;
              spriteScale = 1.2;
            } else if (enemyCount == 2) {
              // Two enemies: staggered diagonal
              leftFactor = 0.45 + index * 0.20;
              topFactor = 0.15 + index * 0.12;
              spriteScale = 1.0;
            } else {
              // Three+ enemies: spread horizontally with slight stagger
              leftFactor = 0.35 + index * 0.18;
              topFactor = 0.12 + (index % 2) * 0.10;
              spriteScale = 0.9;
            }

            final spriteSize = 100 * spriteScale;

            return Positioned(
              left: screenWidth * leftFactor - spriteSize / 2,
              top: zone1Height * topFactor,
              child: _AnimatedEnemySprite(
                enemy: enemy,
                size: spriteSize,
                isHighlighted: index == highlightedIndex,
                isTargetable: onTap != null,
                onTap: () => onTap?.call(index),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Individual animated enemy sprite with breathing/hover animation
class _AnimatedEnemySprite extends StatefulWidget {
  final Enemy enemy;
  final double size;
  final bool isHighlighted;
  final bool isTargetable;
  final VoidCallback? onTap;

  const _AnimatedEnemySprite({
    required this.enemy,
    required this.size,
    this.isHighlighted = false,
    this.isTargetable = false,
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

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
    final size = widget.size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Transform.translate(
            offset: Offset(0, -_bounceAnimation.value),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  // Ground shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: Offset(4, 8 + _bounceAnimation.value),
                  ),
                  // Element glow
                  BoxShadow(
                    color: _elementColor.withValues(
                      alpha: _glowAnimation.value,
                    ),
                    blurRadius: widget.isHighlighted ? 25 : 15,
                    spreadRadius: widget.isHighlighted ? 5 : 2,
                  ),
                  // Target highlight glow
                  if (widget.isHighlighted)
                    BoxShadow(
                      color: const Color(0xFFe3b341).withValues(alpha: 0.7),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  // Targetable pulse
                  if (widget.isTargetable && !widget.isHighlighted)
                    BoxShadow(
                      color: const Color(
                        0xFFe3b341,
                      ).withValues(alpha: _glowAnimation.value * 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    border: widget.isHighlighted
                        ? Border.all(color: const Color(0xFFe3b341), width: 3)
                        : widget.isTargetable
                        ? Border.all(
                            color: const Color(0xFFe3b341).withValues(
                              alpha: 0.5 + _glowAnimation.value * 0.5,
                            ),
                            width: 2,
                          )
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
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            _elementColor.withValues(alpha: 0.4),
            _elementColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: widget.size * 0.4)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.enemy.name,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFFc9d1d9),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Intent indicator
          const SizedBox(height: 2),
          _buildIntentIndicator(),
        ],
      ),
    );
  }

  Widget _buildIntentIndicator() {
    final intentIcon = switch (widget.enemy.intent) {
      EnemyIntent.attack => '⚔️',
      EnemyIntent.defend => '🛡️',
      EnemyIntent.debuff => '💀',
      EnemyIntent.spell => '✨',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(intentIcon, style: const TextStyle(fontSize: 12)),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PLAYER SPRITE OVERLAY (Optional Flutter-based player sprite)
/// Position: Zone 2 (Battlefield) - bottom-left, facing right
/// ═══════════════════════════════════════════════════════════════════════════
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

    _breathAnimation = Tween<double>(
      begin: 0,
      end: 4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
            width: 90,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _elementColor.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: [
                // Ground shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: Offset(2, 6 + _breathAnimation.value),
                ),
                // Element glow
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          const Color(0xFF2d333b),
                          const Color(0xFF21262d),
                        ],
                      ),
                    ),
                  ),
                  // State overlay
                  if (overlayColor != Colors.transparent)
                    Container(decoration: BoxDecoration(color: overlayColor)),
                  // Mage icon
                  const Center(
                    child: Text('🧙', style: TextStyle(fontSize: 40)),
                  ),
                  // Element indicator
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(switch (widget.element) {
                        'fire' => '🔥',
                        'water' => '💧',
                        'earth' => '🪨',
                        'air' => '💨',
                        _ => '✨',
                      }, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
