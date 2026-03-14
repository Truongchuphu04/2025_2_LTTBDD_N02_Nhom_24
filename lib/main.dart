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
  Locale _locale = const Locale('en');

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
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

  DateTime _todayKey() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isHabitCompletedToday(int habitId) {
    final today = _todayKey();
    final completed = _completedHabitsByDate[today];
    if (completed == null) return false;
    return completed.contains(habitId);
  }

  void _toggleHabitToday(int habitId, bool completed) {
    setState(() {
      final today = _todayKey();
      final set = _completedHabitsByDate[today] ?? <int>{};
      if (completed) {
        set.add(habitId);
      } else {
        set.remove(habitId);
      }
      _completedHabitsByDate[today] = set;
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
      title = strings.todayTitle;
      body = TodayHabitsView(
        locale: widget.locale,
        habits: _habits,
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
    required this.isHabitCompletedToday,
    required this.onToggleHabitToday,
  });

  final Locale locale;
  final List<Habit> habits;
  final bool Function(int habitId) isHabitCompletedToday;
  final void Function(int habitId, bool completed) onToggleHabitToday;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(locale);
    final today = DateTime.now();
    final dateText = '${today.day}/${today.month}/${today.year}';

    if (habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            strings.emptyHabitsToday,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.todayHeader(dateText),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                strings.todaySubheader,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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
                elevation: 2,
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
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.flag),
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

  String get className => _isEnglish ? 'Class: LTTBDD N0x' : 'Lớp: LTTBDD N0x';

  String get membersTitle => _isEnglish ? 'Members' : 'Thành viên';

  String get projectDescriptionTitle =>
      _isEnglish ? 'Project description' : 'Mô tả đề tài';

  String get projectDescription => _isEnglish
      ? 'A simple habit tracker application that allows users to create daily habits, tick them as completed for the current day, and review all habits. Data is stored temporarily in memory for demonstration and testing.'
      : 'Ứng dụng quản lý thói quen đơn giản, cho phép người dùng tạo các thói quen hàng ngày, đánh dấu hoàn thành trong ngày và xem danh sách tất cả thói quen. Dữ liệu được lưu tạm trong bộ nhớ để phục vụ minh họa và kiểm thử.';

  List<GroupMember> get members => _isEnglish
      ? [
          GroupMember(name: 'Student 1 - ID', role: 'UI & navigation'),
          GroupMember(name: 'Student 2 - ID', role: 'Habit logic'),
          GroupMember(name: 'Student 3 - ID', role: 'Testing & report'),
        ]
      : [
          GroupMember(
            name: 'Sinh viên 1 - MSSV',
            role: 'Giao diện & điều hướng',
          ),
          GroupMember(
            name: 'Sinh viên 2 - MSSV',
            role: 'Xử lý logic thói quen',
          ),
          GroupMember(name: 'Sinh viên 3 - MSSV', role: 'Kiểm thử & báo cáo'),
        ];
}

class GroupMember {
  GroupMember({required this.name, required this.role});

  final String name;
  final String role;
}
