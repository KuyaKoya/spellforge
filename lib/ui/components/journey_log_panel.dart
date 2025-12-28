import 'package:flutter/material.dart';
import '../../narrative/journey_log.dart';

/// Journey Log panel widget.
/// LOCKED UX: Narrative archive that feels like it existed before the player.
///
/// Access:
/// - Pause menu only
/// - Optional left-edge swipe (non-combat only)
///
/// Visual Identity (LOCKED):
/// - Dark background
/// - Serif or serif-adjacent font
/// - Low contrast text
/// - Minimal separators
///
/// Behavior:
/// - Entries persist across runs
/// - No timestamps visible
/// - Entries ordered by discovery
///
/// ABSOLUTE RULE: Lore only. No numbers. Never same event as Combat Log.
class JourneyLogPanel extends StatelessWidget {
  final JourneyLog journeyLog;
  final bool showAllRuns;
  final VoidCallback? onClose;

  const JourneyLogPanel({
    super.key,
    required this.journeyLog,
    this.showAllRuns = true, // Persist across runs
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final entries =
        journeyLog.allEntries; // Always show all - persists across runs

    return Container(
      width: 300,
      height: double.infinity,
      decoration: const BoxDecoration(
        // Dark background - LOCKED
        color: Color(0xFF0d1117),
        border: Border(left: BorderSide(color: Color(0xFF21262d), width: 1)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildEntryList(entries)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF21262d), width: 1)),
      ),
      child: Row(
        children: [
          // No emoji icons - minimal
          Expanded(
            child: Text(
              'Journey',
              style: TextStyle(
                // Serif-adjacent font - LOCKED
                fontFamily: 'Georgia',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade400,
                letterSpacing: 1,
              ),
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryList(List<JourneyEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'The pages are empty.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        // Ordered by discovery - oldest first
        final entry = entries[index];
        return _buildEntryCard(entry, index);
      },
    );
  }

  Widget _buildEntryCard(JourneyEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimal separator - just a faint line
          if (index > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 1,
              color: const Color(0xFF21262d).withValues(alpha: 0.3),
            ),

          // Title - low contrast
          Text(
            entry.title,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Content - low contrast, serif
          Text(
            entry.content,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),

          // Source attribution
          if (entry.source != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— ${entry.source}',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
