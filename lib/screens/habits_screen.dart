import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/models/habit.dart';
import 'package:mawo/theme/app_theme.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({Key? key}) : super(key: key);

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'HABITS',
              style: TextStyle(
                fontFamily: AppTheme.spaceMono,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: bgColor,
            elevation: 0,
            actions: const [],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _AddHabitButton(onTap: () => _showAddHabitModal(context, appState)),
                ),
                const SizedBox(height: 24),
                // Daily Habits
                const _SectionHeader(label: 'DAILY //'),
                const SizedBox(height: 12),
                _HabitList(
                  habits: appState.habits
                      .where((h) => h.type == 'daily')
                      .toList(),
                  appState: appState,
                  onEdit: (habit) =>
                      _showAddHabitModal(context, appState, habit: habit),
                  onDelete: (habit) => _deleteHabit(context, appState, habit),
                ),
                const SizedBox(height: 24),
                // One-time Tasks
                const _SectionHeader(label: 'ONE-TIME //'),
                const SizedBox(height: 12),
                _HabitList(
                  habits: appState.habits
                      .where((h) => h.type == 'onetime')
                      .toList(),
                  appState: appState,
                  onEdit: (habit) =>
                      _showAddHabitModal(context, appState, habit: habit),
                  onDelete: (habit) => _deleteHabit(context, appState, habit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddHabitModal(BuildContext context, AppState appState,
      {Habit? habit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHabitModal(
        appState: appState,
        habit: habit,
      ),
    );
  }

  void _deleteHabit(BuildContext context, AppState appState, Habit habit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(),
        title: Text(
          'DELETE HABIT?',
          style: TextStyle(
            fontFamily: AppTheme.spaceMono,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        content: Text(
          'Remove "${habit.name}"?',
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
              appState.deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text(
              'DELETE',
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

class _AddHabitButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddHabitButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(border: Border.all(color: AppTheme.uiColor), color: AppTheme.uiColor.withOpacity(0.08)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, color: AppTheme.uiColor, size: 18), SizedBox(width: 10), Text('TAP TO ADD HABIT', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 10, color: AppTheme.uiColor, fontWeight: FontWeight.w700, letterSpacing: 1))]),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Text(
      label,
      style: TextStyle(
        fontFamily: AppTheme.spaceMono,
        fontSize: 9,
        color: muteColor,
        letterSpacing: 0.18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HabitList extends StatelessWidget {
  final List<Habit> habits;
  final AppState appState;
  final Function(Habit) onEdit;
  final Function(Habit) onDelete;

  const _HabitList({
    Key? key,
    required this.habits,
    required this.appState,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
    final dimColor = isDark ? AppTheme.darkDim : AppTheme.lightDim;

    if (habits.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          color: surfaceColor,
        ),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Text(
                'NO HABITS YET',
                style: TextStyle(
                  fontFamily: AppTheme.spaceMono,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: muteColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '// Tap + Add to create',
                style: TextStyle(
                  fontFamily: AppTheme.spaceMono,
                  fontSize: 9,
                  color: dimColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: habits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final habit = habits[index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            color: surfaceColor,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${habit.category.toUpperCase()} · ${habit.type == 'daily' ? '${habit.goalMinutes}M/DAY' : 'ONE-TIME'}',
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 8,
                      color: muteColor,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => onEdit(habit),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                      ),
                      child: const Icon(Icons.edit, size: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onDelete(habit),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.delete, size: 13, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddHabitModal extends StatefulWidget {
  final AppState appState;
  final Habit? habit;

  const AddHabitModal({
    Key? key,
    required this.appState,
    this.habit,
  }) : super(key: key);

  @override
  State<AddHabitModal> createState() => _AddHabitModalState();
}

class _AddHabitModalState extends State<AddHabitModal> {
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late TextEditingController _timeController;

  late String _selectedType;
  late String _selectedCategory;
  late bool _notifEnabled;
  late List<int> _selectedDays;
  late bool _followupEnabled;

  @override
  void initState() {
    super.initState();

    if (widget.habit != null) {
      _nameController = TextEditingController(text: widget.habit!.name);
      _goalController = TextEditingController(
          text: widget.habit!.goalMinutes.toString());
      _selectedType = widget.habit!.type;
      _selectedCategory = widget.habit!.category;
      _notifEnabled = widget.habit!.notif?.enabled ?? false;
      _timeController = TextEditingController(
          text: _displayTime(widget.habit!.notif?.time ?? '09:00'));
      _selectedDays = widget.habit!.notif?.days ?? [0, 1, 2, 3, 4, 5, 6];
      _followupEnabled = widget.habit!.notif?.followup ?? false;
    } else {
      _nameController = TextEditingController();
      _goalController = TextEditingController(text: '30');
      _timeController = TextEditingController(text: '9:00 AM');
      _selectedType = 'daily';
      _selectedCategory = 'cognitive';
      _notifEnabled = false;
      _selectedDays = [0, 1, 2, 3, 4, 5, 6];
      _followupEnabled = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg1 : AppTheme.lightBg1;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor, width: 2)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.habit != null ? 'EDIT HABIT' : 'NEW HABIT',
                  style: const TextStyle(
                    fontFamily: AppTheme.spaceMono,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name Field
            _FormField(
              label: 'NAME //',
              child: TextField(
                controller: _nameController,
                style: const TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Reading, Exercise',
                  hintStyle: TextStyle(color: isDark ? AppTheme.darkDim : AppTheme.lightDim),
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
                ),
              ),
            ),

            // Type Toggle
            _FormField(
              label: 'TYPE //',
              child: Row(
                children: ['daily', 'onetime'].map((type) {
                  bool isSelected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? AppTheme.uiColor : borderColor,
                          ),
                          color: isSelected
                              ? AppTheme.uiColor.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Text(
                          type == 'daily' ? 'DAILY' : 'ONE-TIME',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.spaceMono,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? AppTheme.uiColor : muteColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Category
            _FormField(
              label: 'CATEGORY //',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['cognitive', 'physical', 'mental', 'custom']
                    .map((cat) {
                  bool isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppTheme.uiColor : borderColor,
                        ),
                        color: isSelected
                            ? AppTheme.uiColor.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Text(
                        cat.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTheme.spaceMono,
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected ? AppTheme.uiColor : muteColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Goal Minutes (if daily)
            if (_selectedType == 'daily') ...[
              _FormField(
                label: 'GOAL MINUTES //',
                child: TextField(
                  controller: _goalController,
                  keyboardType: TextInputType.number,
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
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            GestureDetector(
              onTap: () {
                if (_nameController.text.isEmpty) return;

                final habit = Habit(
                  id: widget.habit?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text,
                  type: _selectedType,
                  category: _selectedCategory,
                  goalMinutes: int.tryParse(_goalController.text) ?? 0,
                  // Reminders are disabled for the first reliable release.
                  notif: null,
                );

                if (widget.habit != null) {
                  widget.appState.updateHabit(widget.habit!.id, habit);
                } else {
                  widget.appState.addHabit(habit);
                }

                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.uiColor,
                child: Text(
                  widget.habit != null ? 'UPDATE HABIT' : 'CREATE HABIT',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.spaceMono,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminderTime() async {
    final initial = _parseDisplayedTime(_timeController.text) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _timeController.text = _formatStoredTime(picked));
    }
  }

  TimeOfDay? _parseDisplayedTime(String value) {
    final normalized = value.trim().toUpperCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalized);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final meridiem = match.group(3);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatStoredTime(TimeOfDay time) => _displayTime(_toStoredTimeFromTimeOfDay(time));

  String _displayTime(String stored) {
    final parts = stored.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = int.tryParse(parts.last) ?? 0;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _toStoredTime(String displayed) {
    final time = _parseDisplayedTime(displayed) ?? const TimeOfDay(hour: 9, minute: 0);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _toStoredTimeFromTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({Key? key, required this.label, required this.child})
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
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 20),
      ],
    );
  }
}
