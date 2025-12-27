import 'package:flutter/material.dart';

/// Displays a styled line from the game log.
///
/// Automatically styles the line based on its content (victories, defeats,
/// status effects, etc.).
class LogLine extends StatelessWidget {
  final String text;

  const LogLine({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final (color, weight) = _getStyle(text);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: color,
          fontWeight: weight,
          height: 1.4,
        ),
      ),
    );
  }

  (Color, FontWeight) _getStyle(String line) {
    // Header/border styles
    if (line.startsWith('===') ||
        line.startsWith('╔') ||
        line.startsWith('║') ||
        line.startsWith('╚')) {
      return (Colors.amber.shade400, FontWeight.bold);
    }

    // Divider styles
    if (line.startsWith('---') ||
        line.startsWith('───') ||
        line.startsWith('┌') ||
        line.startsWith('└') ||
        line.startsWith('│')) {
      return (Colors.grey.shade400, FontWeight.normal);
    }

    // Victory/defeat
    if (line.contains('VICTORY')) {
      return (Colors.green.shade400, FontWeight.bold);
    }
    if (line.contains('DEFEAT') || line.contains('fallen')) {
      return (Colors.red.shade400, FontWeight.bold);
    }

    // Elite content
    if (line.contains('ELITE') || line.contains('💀')) {
      return (Colors.purple.shade300, FontWeight.bold);
    }

    // Warnings
    if (line.contains('⚠️') || line.contains('WARNING')) {
      return (Colors.orange.shade400, FontWeight.normal);
    }

    // Damage
    if (line.contains('Damage:')) {
      return (Colors.orange.shade400, FontWeight.normal);
    }

    // Effectiveness indicators
    if (line.contains('Strong effectiveness') || line.contains('✅')) {
      return (Colors.green.shade400, FontWeight.normal);
    }
    if (line.contains('Weak effectiveness') || line.contains('❌')) {
      return (Colors.red.shade400, FontWeight.normal);
    }

    // Actions/choices
    if (line.startsWith('[')) {
      return (Colors.cyan.shade400, FontWeight.normal);
    }

    // Star ratings
    if (line.contains('★')) {
      return (Colors.yellow.shade400, FontWeight.normal);
    }

    // Status effects
    if (line.contains('applied') ||
        line.contains('Burn') ||
        line.contains('Slow')) {
      return (Colors.purple.shade300, FontWeight.normal);
    }

    // Resources/rewards
    if (line.contains('fragments') ||
        line.contains('Earned') ||
        line.contains('💎')) {
      return (Colors.teal.shade400, FontWeight.normal);
    }
    if (line.contains('✨') || line.contains('Crystal')) {
      return (Colors.cyan.shade300, FontWeight.normal);
    }
    if (line.contains('📖') || line.contains('Learned')) {
      return (Colors.blue.shade400, FontWeight.normal);
    }
    if (line.contains('🏆') || line.contains('REWARD')) {
      return (Colors.amber.shade300, FontWeight.normal);
    }

    return (Colors.grey.shade300, FontWeight.normal);
  }
}

/// Displays the game log as a scrollable list.
class LogView extends StatelessWidget {
  final List<String> logs;
  final ScrollController? controller;

  const LogView({super.key, required this.logs, this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return LogLine(text: logs[index]);
      },
    );
  }
}
