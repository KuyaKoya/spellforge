import 'package:flutter/material.dart';
import '../../../systems/audio_manager.dart';

class RandomEventOverlay extends StatefulWidget {
  final Map<String, dynamic> event;
  final Function(String choiceKey) onChoice;

  const RandomEventOverlay({
    super.key,
    required this.event,
    required this.onChoice,
  });

  @override
  State<RandomEventOverlay> createState() => _RandomEventOverlayState();
}

class _RandomEventOverlayState extends State<RandomEventOverlay> {
  @override
  void initState() {
    super.initState();
    // Phase 7.6.2: Play mystery event background music when overlay opens
    AudioManager.instance.playMysteryEventMusic();
  }

  @override
  void dispose() {
    // Phase 7.6.2: Stop mystery event music when overlay closes
    AudioManager.instance.stopMysteryEventMusic();
    super.dispose();
  }

  /// Handle choice with audio transition
  void _handleChoice(String choiceKey) {
    // Stop music before callback (music will be fully stopped in dispose)
    AudioManager.instance.stopMysteryEventMusic();
    widget.onChoice(choiceKey);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.event['title'] as String? ?? 'Random Event';
    final description = widget.event['description'] as String? ?? '';
    final choices = widget.event['choices'] as List? ?? [];

    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF161b22).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade700, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.help_outline, color: Colors.amber, size: 40),
                const SizedBox(width: 16),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade200,
                        letterSpacing: 2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.amber.shade900),
            const SizedBox(height: 24),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ...choices.map((c) {
              final choiceMap = c as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => _handleChoice(choiceMap['key']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21262d),
                    foregroundColor: Colors.amber.shade200,
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(color: Colors.amber.shade900),
                  ),
                  child: Text(
                    choiceMap['text'],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
