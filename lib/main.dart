import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  Locale _locale = const Locale('vi');

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_locale);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: strings.appTitle,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('vi')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B81)),
        scaffoldBackgroundColor: const Color(0xFFFFF7F9),
        cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.zero),
        useMaterial3: true,
      ),
      home: HabitHomePage(locale: _locale, onChangeLanguage: _changeLanguage),
    );
  }
}

class Habit {
  Habit({required this.id, required this.name});

  final int id;
  final String name;
}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({
    super.key,
    required this.locale,
    required this.onChangeLanguage,
  });

  final Locale locale;
  final void Function(Locale locale) onChangeLanguage;

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  int _selectedIndex = 0;
  final List<Habit> _habits = [];
  final Map<DateTime, Set<int>> _completedHabitsByDate = {};
  int _nextHabitId = 1;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _todayKey();
  }

  DateTime _dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _todayKey() {
    return _dayKey(DateTime.now());
  }

  bool _isHabitCompletedToday(int habitId) {
    final dayKey = _dayKey(_selectedDate);
    final completed = _completedHabitsByDate[dayKey];
    if (completed == null) return false;
    return completed.contains(habitId);
  }

  void _toggleHabitToday(int habitId, bool completed) {
    setState(() {
      final dayKey = _dayKey(_selectedDate);
      final set = _completedHabitsByDate[dayKey] ?? <int>{};
      if (completed) {
        set.add(habitId);
      } else {
        set.remove(habitId);
      }
      _completedHabitsByDate[dayKey] = set;
    });
  }

  Future<void> _addHabit() async {
    final strings = AppStrings(widget.locale);
    final controller = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.addHabitTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: strings.habitNameLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.of(context).pop(text);
              },
              child: Text(strings.save),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _habits.add(Habit(id: _nextHabitId++, name: result.trim()));
      });
    }
  }

  void _removeHabit(Habit habit) {
    setState(() {
      _habits.removeWhere((h) => h.id == habit.id);
      for (final key in _completedHabitsByDate.keys.toList()) {
        final set = _completedHabitsByDate[key];
        set?.remove(habit.id);
        if (set != null && set.isEmpty) {
          _completedHabitsByDate.remove(key);
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSelectedDateChanged(DateTime date) {
    setState(() {
      _selectedDate = _dayKey(date);
    });
  }

  void _onLanguageSelected(String code) {
    if (code == 'en') {
      widget.onChangeLanguage(const Locale('en'));
    } else if (code == 'vi') {
      widget.onChangeLanguage(const Locale('vi'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.locale);

    Widget body;
    String title;

    if (_selectedIndex == 0) {
      final d = _selectedDate;
      final isEnglish = widget.locale.languageCode == 'en';
      const viWeekdays = [
        'Thứ hai',
        'Thứ ba',
        'Thứ tư',
        'Thứ năm',
        'Thứ sáu',
        'Thứ bảy',
        'Chủ nhật',
      ];
      const enWeekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final weekdayName = (isEnglish
          ? enWeekdays
          : viWeekdays)[(d.weekday - 1) % 7];
      final dateText = '${d.day}/${d.month}';
      title = '$weekdayName, $dateText';
      body = TodayHabitsView(
        locale: widget.locale,
        habits: _habits,
        selectedDate: _selectedDate,
        onSelectedDateChanged: _onSelectedDateChanged,
        isHabitCompletedToday: _isHabitCompletedToday,
        onToggleHabitToday: _toggleHabitToday,
      );
    } else if (_selectedIndex == 1) {
      title = strings.allHabitsTitle;
      body = AllHabitsView(
        locale: widget.locale,
        habits: _habits,
        onRemoveHabit: _removeHabit,
      );
    } else {
      title = strings.aboutTitle;
      body = AboutGroupView(locale: widget.locale);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: _onLanguageSelected,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'en', child: Text(strings.english)),
              PopupMenuItem(value: 'vi', child: Text(strings.vietnamese)),
            ],
          ),
        ],
      ),
      body: body,
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: _addHabit,
              tooltip: strings.addHabitTooltip,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.today),
            label: strings.todayNav,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: strings.allHabitsNav,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            label: strings.aboutNav,
          ),
        ],
      ),
    );
  }
}

class TodayHabitsView extends StatelessWidget {
  const TodayHabitsView({
    super.key,
    required this.locale,
    required this.habits,
    required this.selectedDate,
    required this.onSelectedDateChanged,
    required this.isHabitCompletedToday,
    required this.onToggleHabitToday,
  });

  final Locale locale;
  final List<Habit> habits;
  final DateTime selectedDate;
  final void Function(DateTime date) onSelectedDateChanged;
  final bool Function(int habitId) isHabitCompletedToday;
  final void Function(int habitId, bool completed) onToggleHabitToday;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(locale);
    final today = DateTime.now();
    final selected = selectedDate;
    final dateText = '${selected.day}/${selected.month}/${selected.year}';

    final weekdayNames = locale.languageCode == 'en'
        ? ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
        : ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    const int windowSize = 7;
    const int halfWindow = 3; // 3 days before and 3 days after selected
    final List<DateTime> days = List.generate(
      windowSize,
      (index) => selected.add(Duration(days: index - halfWindow)),
    );

    Widget mainContent;
    if (habits.isEmpty) {
      mainContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE0E8),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.rocket_launch,
                  size: 96,
                  color: Color(0xFFFF6B81),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              strings.noHabitsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                strings.noHabitsDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else {
      final completedCount = habits
          .where((h) => isHabitCompletedToday(h.id))
          .length;
      final totalCount = habits.length;
      final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

      mainContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.todayHeader(dateText),
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.todaySubheader,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount / $totalCount',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              itemCount: habits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final habit = habits[index];
                final completed = isHabitCompletedToday(habit.id);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    value: completed,
                    onChanged: (value) {
                      onToggleHabitToday(habit.id, value ?? false);
                    },
                    title: Text(habit.name),
                    subtitle: Text(
                      completed
                          ? strings.habitCompletedSubtitle
                          : strings.habitNotCompletedSubtitle,
                    ),
                    secondary: Icon(
                      completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: completed
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < 0) {
                // swipe left -> next day
                onSelectedDateChanged(selected.add(const Duration(days: 1)));
              } else if (velocity > 0) {
                // swipe right -> previous day
                onSelectedDateChanged(
                  selected.subtract(const Duration(days: 1)),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((date) {
                final bool isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final bool isSelected =
                    date.year == selected.year &&
                    date.month == selected.month &&
                    date.day == selected.day;
                final int weekdayIndex = date.weekday % 7;
                final String label = weekdayNames[weekdayIndex];

                final Color backgroundColor = isSelected
                    ? const Color(0xFFFF6B81)
                    : Colors.transparent;
                final Color borderColor = isSelected
                    ? const Color(0xFFFF6B81)
                    : const Color(0xFFFFC0CF);
                final Color textColor = isSelected
                    ? Colors.white
                    : (isToday ? const Color(0xFFFF6B81) : Colors.grey[800]!);

                return GestureDetector(
                  onTap: () => onSelectedDateChanged(date),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: textColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: mainContent),
      ],
    );
  }
}

class AllHabitsView extends StatelessWidget {
  const AllHabitsView({
    super.key,
    required this.locale,
    required this.habits,
    required this.onRemoveHabit,
  });

  final Locale locale;
  final List<Habit> habits;
  final void Function(Habit habit) onRemoveHabit;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(locale);

    if (habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            strings.emptyHabitsAll,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: habits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final habit = habits[index];
        return Dismissible(
          key: ValueKey(habit.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => onRemoveHabit(habit),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(habit.name),
              subtitle: Text(strings.swipeToDelete),
            ),
          ),
        );
      },
    );
  }
}

class AboutGroupView extends StatelessWidget {
  const AboutGroupView({super.key, required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(locale);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.groups, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.groupName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.className,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            strings.membersTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...strings.members.map(
            (member) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(member.name),
              subtitle: Text(member.role),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            strings.projectDescriptionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            strings.projectDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get _isEnglish => locale.languageCode == 'en';

  String get appTitle => _isEnglish ? 'Habit Tracker' : 'Quản lý thói quen';

  String get todayTitle => _isEnglish ? 'Today' : 'Hôm nay';

  String get allHabitsTitle => _isEnglish ? 'All Habits' : 'Tất cả thói quen';

  String get aboutTitle => _isEnglish ? 'About the group' : 'Thông tin nhóm';

  String get todayNav => _isEnglish ? 'Today' : 'Hôm nay';

  String get allHabitsNav => _isEnglish ? 'Habits' : 'Thói quen';

  String get aboutNav => _isEnglish ? 'About' : 'Nhóm';

  String get english => 'English';

  String get vietnamese => 'Tiếng Việt';

  String todayHeader(String dateText) =>
      _isEnglish ? 'Today · $dateText' : 'Hôm nay · $dateText';

  String get todaySubheader => _isEnglish
      ? 'Tick the habits you have completed today.'
      : 'Đánh dấu các thói quen bạn đã hoàn thành hôm nay.';

  String get emptyHabitsToday => _isEnglish
      ? 'No habits yet. Please add some habits in the "All Habits" tab.'
      : 'Chưa có thói quen nào. Hãy thêm thói quen ở tab "Tất cả thói quen".';

  String get emptyHabitsAll => _isEnglish
      ? 'No habits yet. Tap the + button to add your first habit.'
      : 'Chưa có thói quen nào. Nhấn nút + để thêm thói quen đầu tiên.';

  String get noHabitsTitle => _isEnglish ? 'No Habits' : 'Chưa có thói quen';

  String get noHabitsDescription => _isEnglish
      ? 'Tap the "+" button to add your first habit.'
      : 'Nhấn nút "+" để thêm thói quen đầu tiên của bạn.';

  String get habitCompletedSubtitle =>
      _isEnglish ? 'Completed for today' : 'Đã hoàn thành hôm nay';

  String get habitNotCompletedSubtitle =>
      _isEnglish ? 'Not yet completed today' : 'Chưa hoàn thành hôm nay';

  String get addHabitTitle => _isEnglish ? 'New habit' : 'Thói quen mới';

  String get habitNameLabel => _isEnglish ? 'Habit name' : 'Tên thói quen';

  String get cancel => _isEnglish ? 'Cancel' : 'Hủy';

  String get save => _isEnglish ? 'Save' : 'Lưu';

  String get addHabitTooltip => _isEnglish ? 'Add habit' : 'Thêm thói quen';

  String get swipeToDelete => _isEnglish
      ? 'Swipe left to remove this habit.'
      : 'Vuốt sang trái để xóa thói quen này.';

  String get groupName =>
      _isEnglish ? 'Group: Habit Tracker' : 'Nhóm: Quản lý thói quen';

  String get className => _isEnglish ? 'Class: LTTBDD N02' : 'Lớp: LTTBDD N02';

  String get membersTitle => _isEnglish ? 'Members' : 'Thành viên';

  String get projectDescriptionTitle =>
      _isEnglish ? 'Project description' : 'Mô tả đề tài';

  String get projectDescription => _isEnglish
      ? 'A simple habit tracker application that allows users to create daily habits, tick them as completed for the current day, and review all habits. Data is stored temporarily in memory for demonstration and testing.'
      : 'Ứng dụng quản lý thói quen đơn giản, cho phép người dùng tạo các thói quen hàng ngày, đánh dấu hoàn thành trong ngày và xem danh sách tất cả thói quen. Dữ liệu được lưu tạm trong bộ nhớ để phục vụ minh họa và kiểm thử.';

  List<GroupMember> get members => _isEnglish
      ? [
          GroupMember(
            name: 'Chu Phu Truong - 22010081',
            role: 'UI & navigation',
          ),
        ]
      : [
          GroupMember(
            name: 'Chu Phú Trường - 22010081',
            role: 'Giao diện & điều hướng',
          ),
        ];
}

class GroupMember {
  GroupMember({required this.name, required this.role});

  final String name;
  final String role;
}
