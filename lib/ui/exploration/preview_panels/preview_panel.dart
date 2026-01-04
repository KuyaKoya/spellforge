import 'package:flutter/material.dart';

/// Base preview panel widget for interactables.
///
/// Provides a consistent structure for all preview panels:
/// - Title with icon
/// - Content area
/// - Optional risk hint
/// - Optional Director line
/// - Action buttons
abstract class PreviewPanel extends StatelessWidget {
  /// Title of the preview.
  final String title;

  /// Icon widget or emoji.
  final Widget? icon;

  /// Optional risk hint text.
  final String? riskHint;

  /// Optional Director commentary.
  final String? directorLine;

  /// Callback for confirm action.
  final VoidCallback? onConfirm;

  /// Callback for cancel action.
  final VoidCallback? onCancel;

  /// Confirm button label.
  final String confirmLabel;

  /// Cancel button label.
  final String cancelLabel;

  /// Accent color for the panel.
  final Color accentColor;

  /// Whether to show the cancel button.
  final bool showCancel;

  /// Whether the confirm action is enabled.
  final bool confirmEnabled;

  const PreviewPanel({
    super.key,
    required this.title,
    this.icon,
    this.riskHint,
    this.directorLine,
    this.onConfirm,
    this.onCancel,
    this.confirmLabel = 'CONFIRM',
    this.cancelLabel = 'BACK',
    this.accentColor = const Color(0xFF58a6ff),
    this.showCancel = true,
    this.confirmEnabled = true,
  });

  /// Build the content area of the preview panel.
  /// Override in subclasses to provide specific content.
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    // Get screen height to limit panel size
    final screenHeight = MediaQuery.of(context).size.height;
    final maxContentHeight =
        screenHeight * 0.5; // Max 50% of screen for content

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.95),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),

          // Scrollable content area with max height
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxContentHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: buildContent(context),
            ),
          ),

          // Risk hint
          if (riskHint != null) _buildRiskHint(),

          // Director line
          if (directorLine != null) _buildDirectorLine(),

          const SizedBox(height: 12),

          // Actions
          _buildActions(),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFf85149).withValues(alpha: 0.1),
        border: Border.all(
          color: const Color(0xFFf85149).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              riskHint!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFFf85149),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorLine() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF21262d),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF8b949e),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              directorLine!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (showCancel && onCancel != null)
            Expanded(
              child: _ActionButton(
                label: cancelLabel,
                color: const Color(0xFF6e7681),
                onTap: onCancel,
              ),
            ),
          if (showCancel && onCancel != null) const SizedBox(width: 12),
          if (onConfirm != null)
            Expanded(
              child: _ActionButton(
                label: confirmLabel,
                color: accentColor,
                onTap: confirmEnabled ? onConfirm : null,
                filled: true,
              ),
            ),
        ],
      ),
    );
  }
}

/// Action button for preview panels.
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.color,
    this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final displayColor = isDisabled ? color.withValues(alpha: 0.3) : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? displayColor.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(color: displayColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: displayColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat row widget for displaying key-value pairs.
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? icon;
  final double? barPercent;
  final Color? barColor;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.barPercent,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          if (barPercent != null) ...[
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF21262d),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: barPercent!.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor ?? const Color(0xFF58a6ff),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else
            const Expanded(child: SizedBox()),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFFc9d1d9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tag widget for displaying traits, elements, etc.
class PreviewTag extends StatelessWidget {
  final String text;
  final Color color;
  final Widget? icon;

  const PreviewTag({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
