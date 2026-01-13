import 'package:flutter/material.dart';
import '../../systems/audio_manager.dart';
import '../../systems/progression_system.dart';
import '../../systems/save_manager.dart';

class SettingsOverlay extends StatefulWidget {
  final ProgressionSystem progressionSystem;
  final VoidCallback onReset;

  const SettingsOverlay({
    super.key,
    required this.progressionSystem,
    required this.onReset,
  });

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  // Store local state for sliders/toggles to update UI immediately
  late double _musicVolume;
  late double _sfxVolume;
  late bool _musicEnabled;
  late bool _sfxEnabled;

  double _lastNonZeroMusicVolume = 0.7;
  double _lastNonZeroSfxVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _musicVolume = AudioManager.instance.musicVolume;
    _sfxVolume = AudioManager.instance.sfxVolume;
    _musicEnabled = _musicVolume > 0;
    _sfxEnabled = _sfxVolume > 0;

    if (_musicVolume > 0) _lastNonZeroMusicVolume = _musicVolume;
    if (_sfxVolume > 0) _lastNonZeroSfxVolume = _sfxVolume;
  }

  void _updateMusicVolume(double value) {
    setState(() {
      _musicVolume = value;
      _musicEnabled = value > 0;
      if (value > 0) _lastNonZeroMusicVolume = value;
    });
    AudioManager.instance.setMusicVolume(value);
  }

  void _toggleMusic(bool value) {
    if (value) {
      _updateMusicVolume(_lastNonZeroMusicVolume);
    } else {
      _updateMusicVolume(0.0);
    }
  }

  void _updateSfxVolume(double value) {
    setState(() {
      _sfxVolume = value;
      _sfxEnabled = value > 0;
      if (value > 0) _lastNonZeroSfxVolume = value;
    });
    AudioManager.instance.setSfxVolume(value);
  }

  void _toggleSfx(bool value) {
    if (value) {
      _updateSfxVolume(_lastNonZeroSfxVolume);
    } else {
      _updateSfxVolume(0.0);
    }
  }

  Future<void> _handleReset() async {
    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161b22),
        title: const Text(
          'ERASE ALL DATA?',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will permanently delete your progress, unlocks, and save data. This cannot be undone.',
          style: TextStyle(fontFamily: 'monospace', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text(
              'ERASE',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.progressionSystem.resetAll();
      await SaveManager.instance.deleteSave();

      // Close settings
      if (mounted) {
        Navigator.of(context).pop();
        widget.onReset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0d1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Audio Section
              _buildSectionTitle('AUDIO'),
              const SizedBox(height: 16),

              // Music
              _buildToggleRow('Background Music', _musicEnabled, _toggleMusic),
              _buildSlider(
                _musicVolume,
                _updateMusicVolume,
                active: _musicEnabled,
              ),

              const SizedBox(height: 16),

              // SFX
              _buildToggleRow('Sound Effects', _sfxEnabled, _toggleSfx),
              _buildSlider(_sfxVolume, _updateSfxVolume, active: _sfxEnabled),

              const SizedBox(height: 32),

              // Danger Zone
              _buildSectionTitle('DATA MANAGEMENT', color: Colors.grey),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _handleReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'RESET GAME STATE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Close Button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.amber,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.amber,
          activeTrackColor: Colors.amber.withValues(alpha: 0.3),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.shade800,
        ),
      ],
    );
  }

  Widget _buildSlider(
    double value,
    ValueChanged<double> onChanged, {
    bool active = true,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: active ? Colors.amber : Colors.grey.shade700,
        inactiveTrackColor: Colors.grey.shade800,
        thumbColor: active ? Colors.amber : Colors.grey,
        overlayColor: Colors.amber.withValues(alpha: 0.2),
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      child: Slider(value: value, onChanged: active ? onChanged : null),
    );
  }
}
