import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _eodTimeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _eodTimeController = TextEditingController(text: '21:00');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _eodTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        _nameController.text = appState.user['name'] ?? '';
        _eodTimeController.text =
            appState.settings['eodTime'] ?? '21:00';

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
        final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
        final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
        final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
        final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'SETTINGS',
              style: TextStyle(
                fontFamily: AppTheme.spaceMono,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: bgColor,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance
                _SettingsSection(
                  label: 'APPEARANCE //',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DARK MODE',
                        style: TextStyle(
                          fontFamily: AppTheme.spaceMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => appState.toggleTheme(),
                        child: Container(
                          width: 44,
                          height: 24,
                          decoration: BoxDecoration(
                            color: (appState.settings['isDark'] ?? true)
                                ? AppTheme.uiColor
                                : borderColor,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: borderColor),
                          ),
                          child: Align(
                            alignment: (appState.settings['isDark'] ?? true)
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: (appState.settings['isDark'] ?? true)
                                    ? Colors.black
                                    : muteColor,
                                shape: BoxShape.rectangle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Profile
                _SettingsSection(
                  label: 'PROFILE //',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR NAME',
                        style: TextStyle(
                          fontFamily: AppTheme.spaceMono,
                          fontSize: 9,
                          color: muteColor,
                          letterSpacing: 0.14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 13),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(color: AppTheme.uiColor),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              appState.setUserName(_nameController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('// Name saved.'),
                                  backgroundColor: AppTheme.uiColor,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 18),
                              color: AppTheme.uiColor,
                              child: const Text(
                                'SAVE',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Notifications
                _SettingsSection(
                  label: 'NOTIFICATIONS //',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'END OF DAY REMINDER',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fires if habits incomplete',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 9,
                                  color: isDark ? AppTheme.darkDim : AppTheme.lightDim,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              appState.setEODSettings(
                                !appState.settings['eodEnabled'],
                                _eodTimeController.text,
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 24,
                              decoration: BoxDecoration(
                                color: appState.settings['eodEnabled']
                                    ? AppTheme.uiColor
                                    : borderColor,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: borderColor),
                              ),
                              child: Align(
                                alignment: appState.settings['eodEnabled']
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: appState.settings['eodEnabled']
                                        ? Colors.black
                                        : muteColor,
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (appState.settings['eodEnabled']) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'REMINDER TIME',
                          style: TextStyle(
                            fontFamily: AppTheme.spaceMono,
                            fontSize: 9,
                            color: AppTheme.darkMuted,
                            letterSpacing: 0.14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _eodTimeController,
                          style: const TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 13),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: AppTheme.uiColor),
                            ),
                          ),
                          onChanged: (val) {
                            appState.setEODSettings(
                              true,
                              val,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Data
                _SettingsSection(
                  label: 'DATA //',
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _exportData(context, appState),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            color: surfaceColor,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'EXPORT DATA (CLIPBOARD)',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 10,
                                  color: textColor,
                                ),
                              ),
                              const Icon(Icons.copy, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _importData(context, appState),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            color: surfaceColor,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'IMPORT DATA (CLIPBOARD)',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 10,
                                  color: textColor,
                                ),
                              ),
                              const Icon(Icons.paste, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _eraseData(context, appState),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                            color: Colors.red.withOpacity(0.08),
                          ),
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ERASE ALL DATA',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                              Icon(Icons.delete, color: Colors.red, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exportData(BuildContext context, AppState appState) {
    final data = appState.exportData();
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('// Data copied to clipboard.')),
    );
  }

  void _importData(BuildContext context, AppState appState) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    
    try {
      await appState.importData(data!.text!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('// Data imported. Welcome back.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('// Invalid data format.')),
      );
    }
  }

  void _eraseData(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(),
        title: Text(
          'ERASE ALL DATA?',
          style: TextStyle(
            fontFamily: AppTheme.spaceMono,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        content: Text(
          'This cannot be undone. All habits and history will be lost.',
          style: TextStyle(
            fontFamily: AppTheme.spaceGrotesk,
            color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: AppTheme.spaceMono,
                fontSize: 11,
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              appState.eraseAllData();
              Navigator.pop(context);
            },
            child: const Text(
              'ERASE',
              style: TextStyle(
                fontFamily: AppTheme.spaceMono,
                fontSize: 11,
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsSection({Key? key, required this.label, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.spaceMono,
            fontSize: 9,
            color: muteColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }
}
