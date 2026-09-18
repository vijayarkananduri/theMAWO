import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/theme/app_theme.dart';
import 'package:mawo/services/feedback_service.dart';
import 'package:mawo/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        _nameController.text = appState.user['name'] ?? '';

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

                _SettingsSection(
                  label: 'FEEDBACK //',
                  child: Column(
                    children: [
                      _FeedbackToggle(
                        label: 'HAPTICS',
                        description: 'Tactile response on meaningful actions',
                        value: appState.hapticsEnabled,
                        onChanged: (value) => appState.setFeedbackSettings(haptics: value),
                        borderColor: borderColor,
                        muteColor: muteColor,
                      ),
                      const SizedBox(height: 14),
                      _FeedbackToggle(
                        label: 'COMPLETION FX',
                        description: 'Glow, motion, and milestone feedback',
                        value: appState.completionFxEnabled,
                        onChanged: (value) => appState.setFeedbackSettings(completionFx: value),
                        borderColor: borderColor,
                        muteColor: muteColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _SettingsSection(
                  label: 'REMINDERS //',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('END-OF-DAY CHECK-IN', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 11)),
                        subtitle: Text('Daily reflection reminder', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 12, color: muteColor)),
                        value: appState.settings['eodEnabled'] == true,
                        activeColor: AppTheme.uiColor,
                        onChanged: (value) async {
                          try {
                            await appState.setEODSettings(value);
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('// Reminder not scheduled: $e')));
                          }
                        },
                      ),
                      if (appState.settings['eodEnabled'] == true)
                        Row(
                          children: [
                            Expanded(child: Text(appState.settings['eodTime'] ?? '21:00', style: const TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 13))),
                            TextButton(onPressed: () => _pickEodTime(context, appState), child: const Text('SET TIME', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 10, color: AppTheme.uiColor))),
                          ],
                        ),
                      const Divider(),
                      Align(alignment: Alignment.centerLeft, child: Text('DIAGNOSTICS', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 9, color: muteColor))),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(onPressed: () async { await NotificationService().showTestNotification(); }, child: const Text('TEST NOW')),
                          TextButton(onPressed: () async { await NotificationService().openExactAlarmSettings(); }, child: const Text('ALARM SETTINGS')),
                          TextButton(onPressed: () => _recalibrateClock(context, appState), child: const Text('CALIBRATE CLOCK')),
                          TextButton(onPressed: () async { try { await NotificationService().scheduleTestNotification(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('// Scheduled test set for 2 minutes.'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('// Scheduled test failed: $e'))); } }, child: const Text('TEST IN 2 MIN')),
                          TextButton(onPressed: () async { try { await appState.rescheduleAllNotifications(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('// Reminders rescheduled.'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('// Reschedule failed: $e'))); } }, child: const Text('RESCHEDULE')),
                        ],
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

                const SizedBox(height: 12),

                _SettingsSection(
                  label: 'ABOUT //',
                  child: Column(
                    children: [
                      _ExternalLink(label: 'MY PORTFOLIO', url: 'https://vijayarka.netlify.app', borderColor: borderColor, surfaceColor: surfaceColor),
                      const SizedBox(height: 8),
                      _ExternalLink(label: 'RESEARCH PAPER', url: 'https://zenodo.org/records/16889414', borderColor: borderColor, surfaceColor: surfaceColor),
                    ],
                  ),
                ),
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
                                'EXPORT DATA (JSON FILE)',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 10,
                                  color: textColor,
                                ),
                              ),
                              const Icon(Icons.save_alt, size: 16),
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
                                'IMPORT DATA (JSON FILE)',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 10,
                                  color: textColor,
                                ),
                              ),
                              const Icon(Icons.folder_open, size: 16),
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

  Future<void> _recalibrateClock(BuildContext context, AppState appState) async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: now, firstDate: now.subtract(const Duration(days: 365)), lastDate: now.add(const Duration(days: 365)));
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null || !context.mounted) return;
    await appState.calibrateClock(DateTime(date.year, date.month, date.day, time.hour, time.minute));
    await appState.rescheduleAllNotifications();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('// Clock calibrated and reminders rescheduled.')));
  }

  Future<void> _pickEodTime(BuildContext context, AppState appState) async {
    final current = (appState.settings['eodTime'] ?? '21:00').toString().split(':');
    final initial = TimeOfDay(hour: int.tryParse(current.first) ?? 21, minute: int.tryParse(current.last) ?? 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    try {
      await appState.setEODSettings(true, value);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('// Reminder not scheduled: $e')));
    }
  }

  Future<void> _exportData(BuildContext context, AppState appState) async {
    try {
      final data = appState.exportData();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save MAWO backup',
        fileName: 'mawo-backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return;
      await File(path).writeAsString(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('// JSON backup saved. Your data is safe.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('// Export failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importData(BuildContext context, AppState appState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Choose MAWO JSON backup',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null) return;
      final selected = result.files.single;
      final contents = selected.bytes != null
          ? String.fromCharCodes(selected.bytes!)
          : selected.path == null
              ? null
              : await File(selected.path!).readAsString();
      if (contents == null) throw const FormatException('No file data');
      await appState.importData(contents);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('// JSON backup imported. Welcome back.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('// Invalid data format. Please check your backup.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
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

class _ExternalLink extends StatelessWidget {
  final String label;
  final String url;
  final Color borderColor;
  final Color surfaceColor;
  const _ExternalLink({required this.label, required this.url, required this.borderColor, required this.surfaceColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final uri = Uri.parse(url);
      try {
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('// No browser available on this device.')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('// Could not open this link.')));
        }
      }
    },
    child: Container(
      width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: borderColor), color: surfaceColor),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 10)), const Icon(Icons.open_in_new, size: 15)]),
    ),
  );
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

class _FeedbackToggle extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color borderColor;
  final Color muteColor;

  const _FeedbackToggle({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.borderColor,
    required this.muteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(description, style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 8, color: muteColor)),
            ],
          ),
        ),
        Semantics(
          label: label,
          toggled: value,
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppTheme.uiColor : Colors.transparent,
                border: Border.all(color: value ? AppTheme.uiColor : borderColor),
              ),
              child: Align(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  color: value ? Colors.black : muteColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
