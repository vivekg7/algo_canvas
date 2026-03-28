import 'package:flutter/material.dart';
import 'package:algo_canvas/theme/app_theme.dart';
import 'package:algo_canvas/theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _sectionHeader(context, 'Appearance'),
            _themeTile(context),
            const Divider(),
            _accentColorTile(context),
            const Divider(),
            _animationsTile(context),
            const SizedBox(height: 16),
            _sectionHeader(context, 'About'),
            _aboutTile(context),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _themeTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeLabel = switch (themeController.mode) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
      AppThemeMode.amoled => 'AMOLED',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.brightness_6_outlined, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme'),
                Text(
                  themeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      icon: Icon(Icons.settings_brightness_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.amoled,
                      icon: Icon(Icons.brightness_1_outlined, size: 18),
                    ),
                  ],
                  selected: {themeController.mode},
                  onSelectionChanged: (s) => themeController.setMode(s.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accentColorTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.palette_outlined, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Accent color'),
                Text(
                  themeController.accent.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in AccentColor.values)
                      GestureDetector(
                        onTap: () => themeController.setAccent(color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.seed,
                            shape: BoxShape.circle,
                            border: themeController.accent == color
                                ? Border.all(
                                    color: colorScheme.onSurface,
                                    width: 2.5,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animationsTile(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        Icons.animation,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: const Text('Animations'),
      subtitle: const Text('Card entrances, transitions, and legend effects'),
      value: themeController.animationsEnabled,
      onChanged: (v) => themeController.setAnimationsEnabled(v),
    );
  }

  Widget _aboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About Algo Canvas'),
      subtitle: const Text('v0.1.0'),
      onTap: () => _showAbout(context),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AboutDialog(
        applicationName: 'Algo Canvas',
        applicationVersion: 'v0.1.0',
        applicationIcon: Icon(Icons.auto_graph_rounded, size: 48),
        children: [
          Text(
            'An interactive algorithm visualizer for learning.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            'Watch algorithms come to life step by step. '
            'Explore sorting, graph traversal, pathfinding, simulations, '
            'and more through interactive visualizations.',
          ),
          SizedBox(height: 12),
          Text(
            'No internet. No ads. No tracking.\n'
            'Just you and the algorithms.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 12),
          Text(
            'Licensed under GPLv3.',
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(height: 12),
          Text(
            'github.com/vivekg7/algo_canvas',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
