// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your external screen files
import 'bmi_screen.dart';
import 'calorie_classification_screen.dart';
import 'goals_screen.dart';
import 'login_screen.dart';
import 'progress_screen.dart';
import 'workouts_screen.dart';

// --- Constants ---
const double kPi = 3.1415926535897932;
const int kDailyCalorieGoal = 2000;
const int kDailyStepGoal = 10000;
const int kDailyWaterGoal = 8;
const int kDailySleepGoal = 8;

// Calorie calculation constants
const double kCaloriesPerStep = 0.04;

// Color scheme
const Color primaryColor = Color(0xFF2C2C2C);
const Color secondaryColor = Color(0xFF8B0000);
const Color accentColor = Color(0xFFD32F2F);
const Color backgroundColor = Color(0xFF1A1A1A);
const Color textColor = Color(0xFFE0E0E0);
const Color cardColor = Color(0xFF242424);

// Colors for the circular progress indicators
const Color kCaloriesColor = Color(0xFFFF6B6B);
const Color kStepsColor = Color(0xFF4ECDC4);
const Color kWaterColor = Color(0xFF45B7D1);
const Color kSleepColor = Color(0xFF96CEB4);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool rememberMe = prefs.getBool('rememberMe') ?? false;

  runApp(NutritionTrackerApp(rememberMe: rememberMe));
}

class NutritionTrackerApp extends StatelessWidget {
  final bool rememberMe;

  const NutritionTrackerApp({super.key, required this.rememberMe});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition & Steps Tracker',
      theme: ThemeData(
        // THIS IS THE CRITICAL FIX:
        // By setting the global scaffold background to transparent, we allow
        // the gradient in HomeScreen to be visible on all child pages.
        scaffoldBackgroundColor: Colors.transparent,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          // Important for some components to also have a transparent background
          background: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      home: rememberMe ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/bmi': (context) => BMIScreen(onCalorieGoalSet: (goal) {}),
        '/calories': (context) => CalorieClassificationScreen(
          calorieGoal: kDailyCalorieGoal,
          usdaApiKey: "QipYRkYT9VLxRdig1sui1czCNzUL59Arm4XkleFy",
        ),
        '/progress': (context) => const ProgressScreen(),
        '/goals': (context) => const GoalsScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _hoveredIndex = -1;
  final GlobalKey<_NutritionTrackerScreenState> _trackerKey =
  GlobalKey<_NutritionTrackerScreenState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      NutritionTrackerScreen(key: _trackerKey),
      CalorieClassificationScreen(
        calorieGoal: 2000,
        usdaApiKey: "QipYRkYT9VLxRdig1sui1czCNzUL59Arm4XkleFy",
      ),
      const ProgressScreen(),
      const GoalsScreen(),
      const WorkoutsScreen(),
    ];

    // This Container provides the gradient background for the entire app.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, backgroundColor],
        ),
      ),
      child: Scaffold(
        // The scaffold itself is transparent to show the container's gradient.
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildAppBarWithNavBar(),
            Expanded(
              child: pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarWithNavBar() {
    return Column(
      children: [
        AppBar(
          title: Text(
            "Velar",
            style: GoogleFonts.poppins(
              fontSize: 29,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          toolbarHeight: 60,
          iconTheme: IconThemeData(color: textColor),
        ),
        _buildSpotifyStyleNavBar(),
      ],
    );
  }

  Widget _buildSpotifyStyleNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(index: 0, icon: Icons.dashboard, label: "Home"),
          _buildNavItem(index: 1, icon: Icons.restaurant, label: "Food"),
          _buildNavItem(index: 4, icon: Icons.fitness_center, label: "Workouts"),
          _buildNavItem(index: 2, icon: Icons.bar_chart, label: "Progress"),

        ],
      ),
    );
  }

  Widget _buildNavItem(
      {required int index, required IconData icon, required String label}) {
    final isSelected = _selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            _trackerKey.currentState?.refreshData();
          }
          setState(() => _selectedIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 20 : 16,
            vertical: isSelected ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.3)
                : isHovered
                ? accentColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isSelected ? 25 : 8),
            border: isSelected
                ? Border.all(color: accentColor.withOpacity(0.5), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSelected ? 20 : 18,
                color: isSelected
                    ? accentColor
                    : isHovered
                    ? accentColor.withOpacity(0.8)
                    : textColor.withOpacity(0.8),
              ),
              if (isSelected) const SizedBox(width: 6),
              if (isSelected)
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NutritionTrackerScreen extends StatefulWidget {
  const NutritionTrackerScreen({super.key});
  @override
  State<NutritionTrackerScreen> createState() =>
      _NutritionTrackerScreenState();
}

class _NutritionTrackerScreenState extends State<NutritionTrackerScreen>
    with TickerProviderStateMixin {
  int caloriesConsumed = 0;
  int stepsTaken = 0;
  int waterIntake = 0;
  int sleepHours = 0;
  int _calorieGoal = 2000;

  int _mostSteps = 0;
  int _mostCaloriesBurned = 0;
  int _mostWater = 0;
  String _stepsDate = "";
  String _caloriesDate = "";
  String _waterDate = "";

  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<String, bool> _activityHistory = {};

  String _currentDateKey = "";
  String _stepsKey = "";
  String _waterKey = "";
  String _sleepKey = "";

  late AnimationController _energyController;
  late Animation<double> _energyAnimation;

  @override
  void initState() {
    super.initState();
    _initializeDailyData();
    _loadDailyData();
    _loadPersonalBests();
    _loadStreakData();

    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _energyAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _energyController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _energyController.dispose();
    super.dispose();
  }

  void _initializeDailyData() {
    final now = DateTime.now();
    _currentDateKey = _formatDateKey(now);
    _stepsKey = 'steps_$_currentDateKey';
    _waterKey = 'water_$_currentDateKey';
    _sleepKey = 'sleep_$_currentDateKey';
  }

  void refreshData() {
    _initializeDailyData();
    _loadDailyData();
    _loadPersonalBests();
    _loadStreakData();
  }

  int _calculateCaloriesBurned() {
    return (stepsTaken * kCaloriesPerStep).round();
  }

  String _getCalorieBurnFeedback(int caloriesBurned) {
    if (caloriesBurned <= 0) return "-";
    if (caloriesBurned < 100) return "Getting Started";
    if (caloriesBurned < 200) return "Nice Work";
    if (caloriesBurned < 400) return "Good Effort";
    if (caloriesBurned < 600) return "Strong Push";
    if (caloriesBurned < 800) return "Great Job";
    if (caloriesBurned < 1000) return "Serious Grind";
    return "Walking Legend";
  }

  String _getStepLevelFeedback(int steps) {
    if (steps <= 0) return "-";
    if (steps < 2000) return "Rest Day";
    if (steps < 4000) return "Light Move";
    if (steps < 6000) return "Getting Active";
    if (steps < 8000) return "On Track";
    if (steps < 10000) return "Strong Day";
    if (steps < 15000) return "Step Master";
    return "Endurance Beast";
  }

  String _getWaterLevelFeedback(int water) {
    if (water <= 0) return "-";
    if (water < 3) return "Thirsty";
    if (water < 6) return "Getting There";
    if (water < 8) return "Good Job";
    return "Hydration Pro";
  }

  String _getSleepQualityFeedback(int hours) {
    if (hours <= 0) return "No Sleep";
    if (hours < 4) return "Poor Rest";
    if (hours < 6) return "Light Sleep";
    if (hours < 7) return "Fair Rest";
    if (hours < 8) return "Good Sleep";
    if (hours < 9) return "Great Rest";
    return "Perfect Sleep";
  }

  Color _getSleepQualityColor(int hours) {
    if (hours <= 0) return Colors.grey;
    if (hours < 4) return Colors.red;
    if (hours < 6) return Colors.orange;
    if (hours < 7) return Colors.yellow;
    if (hours < 8) return Colors.lightGreen;
    if (hours < 9) return Colors.green;
    return Colors.teal;
  }

  void _loadDailyData() async {
    final prefs = await SharedPreferences.getInstance();

    final String? diaryJson = prefs.getString('foodDiary');
    int todayCalories = 0;
    if (diaryJson != null) {
      try {
        final Map<String, dynamic> decodedData = json.decode(diaryJson);
        final Map<String, dynamic> diaryCaloriesMap =
            decodedData['diaryCalories'] ?? {};
        final String todayKey = _formatDateKey(DateTime.now());
        if (diaryCaloriesMap.containsKey(todayKey)) {
          todayCalories = diaryCaloriesMap[todayKey] as int;
        }
      } catch (e) {
        print('Error loading calorie diary data: $e');
        todayCalories = prefs.getInt('totalCalories') ?? 0;
      }
    } else {
      todayCalories = prefs.getInt('totalCalories') ?? 0;
    }

    setState(() {
      caloriesConsumed = todayCalories;
      _calorieGoal = prefs.getInt('finalCalorieGoal') ?? 2000;
      stepsTaken = prefs.getInt(_stepsKey) ?? 0;
      waterIntake = prefs.getInt(_waterKey) ?? 0;
      sleepHours = prefs.getInt(_sleepKey) ?? 0;
    });
  }

  Future<void> _loadPersonalBests() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mostSteps = prefs.getInt('mostSteps') ?? 0;
      _mostCaloriesBurned = prefs.getInt('mostCaloriesBurned') ?? 0;
      _mostWater = prefs.getInt('mostWater') ?? 0;
      _stepsDate = prefs.getString('stepsDate') ?? "";
      _caloriesDate = prefs.getString('caloriesDate') ?? "";
      _waterDate = prefs.getString('waterDate') ?? "";
    });
  }

  void _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final activityHistoryString = prefs.getString('activityHistory') ?? '{}';
    final Map<String, dynamic> historyMap =
    Map<String, dynamic>.from(json.decode(activityHistoryString));
    _activityHistory =
        historyMap.map((key, value) => MapEntry(key, value as bool));

    int currentStreak = 0;
    DateTime currentDate = DateTime.now();

    while (true) {
      final dateKey = _formatDateKey(currentDate);
      if (_activityHistory[dateKey] == true) {
        currentStreak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    setState(() {
      _currentStreak = currentStreak;
      _longestStreak = prefs.getInt('longestStreak') ?? currentStreak;
    });
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _saveDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepsKey, stepsTaken);
    await prefs.setInt(_waterKey, waterIntake);
    await prefs.setInt(_sleepKey, sleepHours);

    final now = DateTime.now();
    final todayFormatted = "${now.month}/${now.day}";

    if (stepsTaken > _mostSteps) {
      await prefs.setInt('mostSteps', stepsTaken);
      await prefs.setString('stepsDate', todayFormatted);
    }

    final int caloriesBurned = _calculateCaloriesBurned();
    if (caloriesBurned > _mostCaloriesBurned) {
      await prefs.setInt('mostCaloriesBurned', caloriesBurned);
      await prefs.setString('caloriesDate', todayFormatted);
    }

    if (waterIntake > _mostWater) {
      await prefs.setInt('mostWater', waterIntake);
      await prefs.setString('waterDate', todayFormatted);
    }

    final todayKey = _formatDateKey(DateTime.now());
    _activityHistory[todayKey] = true;
    await prefs.setString('activityHistory', json.encode(_activityHistory));

    _loadStreakData();
  }

  void _navigateToGoalsScreen() async {
    await Navigator.pushNamed(context, '/goals');
    refreshData();
  }

  void _navigateToCaloriesScreen() async {
    await Navigator.pushNamed(context, '/calories');
    refreshData();
  }

  void _navigateToProgressScreen() async {
    await Navigator.pushNamed(context, '/progress');
    refreshData();
  }

  void _addWater() async {
    setState(() {
      waterIntake += 1;
    });
    await _saveDailyData();
    await _loadPersonalBests();
  }

  void _logSleep(int hours) {
    setState(() {
      sleepHours = hours;
    });
    _saveDailyData();
  }

  void _addSteps(int newSteps) async {
    if (newSteps > 0) {
      setState(() {
        stepsTaken += newSteps;
      });
      await _saveDailyData();
      await _loadPersonalBests();
    }
  }

  void _showAddStepsDialog() {
    showDialog(
      context: context,
      builder: (context) => UltraSleekStepsDialog(onStepsLogged: _addSteps),
    );
  }

  String _classifyCalories(int caloriesConsumed, int calorieGoal) {
    if (calorieGoal == 0) return "Set a goal to get started!";
    final double progress = caloriesConsumed / calorieGoal;

    if (progress <= 0.0) return "Empty Tank";
    if (progress < 0.4) return "Warm-Up Phase";
    if (progress < 0.75) return "Cruising Strong";
    if (progress < 1.0) return "Final Push";
    if (progress <= 1.1) return "Perfect Hit!";
    return "Overshot Gains";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        child: Column(
          children: [
            _buildDailySummaryCard(),
            const SizedBox(height: 30),
            _buildPersonalBestShowcase(),
            const SizedBox(height: 30),
            _buildStreakHeatmap(),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Quick Actions",
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.restaurant,
                        label: "Log Food",
                        onTap: _navigateToCaloriesScreen,
                      ),
                      _buildActionButton(
                        icon: Icons.fitness_center,
                        label: "Progress",
                        onTap: _navigateToProgressScreen,
                      ),
                      _buildActionButton(
                        icon: Icons.flag,
                        label: "Goals",
                        onTap: _navigateToGoalsScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard() {
    final String stepFeedback = _getStepLevelFeedback(stepsTaken);
    final String sleepFeedback = _getSleepQualityFeedback(sleepHours);
    final Color sleepColor = _getSleepQualityColor(sleepHours);
    final String caloriesFeedback = _classifyCalories(caloriesConsumed, _calorieGoal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("Today's Summary",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBarChart(
                icon: Icons.local_fire_department_outlined,
                color: kCaloriesColor,
                label: "Calories",
                currentValue: caloriesConsumed,
                goalValue: _calorieGoal,
                displayText: caloriesFeedback,
                onTap: _navigateToCaloriesScreen,
              ),
              _buildMetricBarChart(
                icon: Icons.run_circle_outlined,
                color: kStepsColor,
                label: "Steps",
                currentValue: stepsTaken,
                goalValue: kDailyStepGoal,
                displayText: stepFeedback,
                onTap: _showAddStepsDialog,
              ),
              _buildMetricBarChart(
                icon: Icons.water_drop_outlined,
                color: kWaterColor,
                label: "Water",
                currentValue: waterIntake,
                goalValue: kDailyWaterGoal,
                displayText: "$waterIntake Cups",
                onTap: _addWater,
              ),
              _buildMetricBarChart(
                icon: Icons.bedtime_outlined,
                color: sleepColor,
                label: "Sleep",
                currentValue: sleepHours,
                goalValue: kDailySleepGoal,
                displayText: sleepFeedback,
                onTap: () => _showSleepDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBarChart({
    required IconData icon,
    required Color color,
    required String label,
    required int currentValue,
    required int goalValue,
    required String displayText,
    required VoidCallback onTap,
  }) {
    final double progress =
    goalValue > 0 ? (currentValue / goalValue).clamp(0.0, 1.0) : 0.0;
    const double totalHeight = 150.0;
    final double barHeight = totalHeight * progress;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: totalHeight,
            width: 50,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 12.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  child: Icon(icon,
                      size: 20, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 30,
            alignment: Alignment.bottomCenter,
            child: Text(
              displayText,
              style: GoogleFonts.inter(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: textColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.7),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: textColor.withOpacity(0.9),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UltraSleekSleepDialog(onSleepLogged: _logSleep),
    );
  }

  Widget _buildStreakHeatmap() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final startingWeekday = (firstDayOfMonth.weekday == DateTime.sunday)
        ? 7
        : firstDayOfMonth.weekday;

    final List<String> dayHeaders = [
      "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Activity Streak",
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              Text("$_currentStreak days",
                  style: GoogleFonts.inter(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text("Longest: $_longestStreak days",
              style: GoogleFonts.inter(
                  color: textColor.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayHeaders
                .map((day) => Text(day,
                style: GoogleFonts.inter(
                    color: textColor.withOpacity(0.5), fontSize: 12)))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: daysInMonth + startingWeekday - 1,
            itemBuilder: (context, index) {
              if (index < startingWeekday - 1) {
                return Container();
              }

              final day = index - (startingWeekday - 1) + 1;
              if (day > daysInMonth) return Container();

              final date = DateTime(now.year, now.month, day);
              final dateKey = _formatDateKey(date);
              final isActive = _activityHistory[dateKey] == true;
              final isToday = day == now.day &&
                  date.month == now.month &&
                  date.year == now.year;

              return Container(
                decoration: BoxDecoration(
                  color: isActive ? accentColor : cardColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(color: accentColor, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    "$day",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isActive
                          ? Colors.white
                          : textColor.withOpacity(0.5),
                      fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text("Active days",
                  style: GoogleFonts.inter(color: textColor, fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text("Today",
                  style: GoogleFonts.inter(color: textColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestShowcase() {
    final double stepsProgress = (_mostSteps == 0 && stepsTaken > 0)
        ? 1.0
        : (_mostSteps > 0 ? stepsTaken / _mostSteps : 0.0);
    final int caloriesBurned = _calculateCaloriesBurned();
    final double caloriesBurnedProgress =
    (_mostCaloriesBurned == 0 && caloriesBurned > 0)
        ? 1.0
        : (_mostCaloriesBurned > 0
        ? caloriesBurned / _mostCaloriesBurned
        : 0.0);
    final double waterProgress = (_mostWater == 0 && waterIntake > 0)
        ? 1.0
        : (_mostWater > 0 ? waterIntake / _mostWater : 0.0);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "  Chasing Records",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.0),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            PersonalBestCircle(
              progress: stepsProgress,
              icon: Icons.run_circle_outlined,
              label: "Steps PR",
              gradientColors: const [accentColor, secondaryColor],
            ),
            PersonalBestCircle(
              progress: caloriesBurnedProgress,
              icon: Icons.local_fire_department_outlined,
              label: "Burn PR",
              gradientColors: const [accentColor, secondaryColor],
            ),
            PersonalBestCircle(
              progress: waterProgress,
              icon: Icons.water_drop_outlined,
              label: "Water PR",
              gradientColors: const [accentColor, secondaryColor],
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildActionButton(
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 24, color: accentColor),
          style: IconButton.styleFrom(
            backgroundColor: accentColor.withOpacity(0.2),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.inter(color: textColor, fontSize: 11)),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PersonalBestCircle extends StatefulWidget {
  final double progress;
  final IconData icon;
  final String label;
  final List<Color> gradientColors;

  const PersonalBestCircle({
    super.key,
    required this.progress,
    required this.icon,
    required this.label,
    required this.gradientColors,
  });

  @override
  State<PersonalBestCircle> createState() => _PersonalBestCircleState();
}

class _PersonalBestCircleState extends State<PersonalBestCircle>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _goldTransitionController;
  late Animation<double> _goldTransitionAnimation;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.progress.clamp(0.0, 1.5))
            .animate(
          CurvedAnimation(
              parent: _progressController, curve: Curves.easeInOutCubic),
        );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _goldTransitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _goldTransitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _goldTransitionController, curve: Curves.easeIn),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _progressController.forward();
    _handleAnimations(widget.progress);
  }

  @override
  void didUpdateWidget(PersonalBestCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
          begin: _progressAnimation.value,
          end: widget.progress.clamp(0.0, 1.5))
          .animate(
        CurvedAnimation(
            parent: _progressController, curve: Curves.easeInOutCubic),
      );
      _progressController.forward(from: 0);
      _handleAnimations(widget.progress);
    }
  }

  void _handleAnimations(double progress) {
    if (progress >= 1.0) {
      _pulseController.stop();
      if (!_goldTransitionController.isAnimating) {
        _goldTransitionController.forward(from: 0);
      }
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat();
      }
    } else if (progress >= 0.9) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      _goldTransitionController.reset();
      _shimmerController.stop();
    } else {
      _pulseController.stop();
      _goldTransitionController.reset();
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _goldTransitionController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _progressAnimation,
          _pulseAnimation,
          _goldTransitionAnimation,
          _shimmerAnimation,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: _PersonalBestPainter(
              progress: _progressAnimation.value,
              pulseValue: _pulseAnimation.value,
              goldTransitionValue: _goldTransitionAnimation.value,
              shimmerValue: _shimmerAnimation.value,
              gradientColors: widget.gradientColors,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white.withOpacity(0.9),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PersonalBestPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final double goldTransitionValue;
  final double shimmerValue;
  final List<Color> gradientColors;

  _PersonalBestPainter({
    required this.progress,
    required this.pulseValue,
    required this.goldTransitionValue,
    required this.shimmerValue,
    required this.gradientColors,
  });

  static const List<Color> _goldColors = [
    Color(0xFFFBB829), // Amber
    Color(0xFFFFF7AD), // Champagne
    Color(0xFFE2A03F), // Rich Gold
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress < 1.0) {
      if (progress >= 0.9) {
        final glowPaint = Paint()
          ..color = gradientColors.first
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 2
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * pulseValue);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          2 * pi * progress,
          false,
          glowPaint,
        );
      }

      final seamlessGradientColors = [...gradientColors, gradientColors.first];
      final colorStops = List.generate(seamlessGradientColors.length, (i) => i / (seamlessGradientColors.length - 1));

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.sweep(
          center,
          seamlessGradientColors,
          colorStops,
          TileMode.clamp,
          -pi / 2,
          -pi / 2 + (2 * pi),
        );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    } else {
      final List<Color> seamlessGold = [
        _goldColors[0],
        _goldColors[1],
        _goldColors[2],
        _goldColors[0],
      ];

      final List<Color> currentRingColors = List.generate(
        seamlessGold.length,
            (i) => Color.lerp(gradientColors[i % gradientColors.length], seamlessGold[i], goldTransitionValue)!,
      );

      final goldGlowPaint = Paint()
        ..color = currentRingColors.first.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius, goldGlowPaint);

      final goldRingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.sweep(
          center,
          currentRingColors,
          List.generate(currentRingColors.length, (index) => index / (currentRingColors.length - 1)),
        );
      canvas.drawCircle(center, radius, goldRingPaint);

      final shimmerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1.0
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.sweep(
          center,
          [Colors.transparent, Colors.white.withOpacity(0.8), Colors.transparent],
          [0.0, 0.1, 0.2],
          TileMode.clamp,
          shimmerValue,
          shimmerValue + (pi / 2),
        );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi,
        false,
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PersonalBestPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        pulseValue != oldDelegate.pulseValue ||
        goldTransitionValue != oldDelegate.goldTransitionValue ||
        shimmerValue != oldDelegate.shimmerValue;
  }
}


class UltraSleekSleepDialog extends StatefulWidget {
  final ValueChanged<int> onSleepLogged;
  const UltraSleekSleepDialog({super.key, required this.onSleepLogged});
  @override
  State<UltraSleekSleepDialog> createState() => _UltraSleekSleepDialogState();
}

class _UltraSleekSleepDialogState extends State<UltraSleekSleepDialog>
    with TickerProviderStateMixin {
  int _selectedHours = 8;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleController = AnimationController(duration: const Duration(milliseconds: 350), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30, spreadRadius: 0, offset: const Offset(0, 10))]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        children: [
                          const Icon(Icons.bedtime_outlined, color: Color(0xFF007AFF), size: 32),
                          const SizedBox(height: 12),
                          Text("Sleep Duration", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Text("How many hours did you sleep?", style: GoogleFonts.inter(fontSize: 15, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 60,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(color: const Color(0xFF007AFF).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3), width: 1)),
                          ),
                          ListWheelScrollView.useDelegate(
                            itemExtent: 60,
                            perspective: 0.003,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() => _selectedHours = index + 1);
                              HapticFeedback.selectionClick();
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 12,
                              builder: (context, index) {
                                final hour = index + 1;
                                final isSelected = _selectedHours == hour;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(hour.toString(), style: GoogleFonts.inter(fontSize: isSelected ? 34 : 24, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : Colors.white.withOpacity(0.4), height: 1.0)),
                                        const SizedBox(width: 8),
                                        Text(hour == 1 ? "hour" : "hours", style: GoogleFonts.inter(fontSize: isSelected ? 16 : 14, fontWeight: FontWeight.w400, color: isSelected ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.3))),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: _getSleepQualityColor(_selectedHours).withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: _getSleepQualityColor(_selectedHours).withOpacity(0.4), width: 1)),
                            child: Text(_getSleepQualityFeedback(_selectedHours), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _getSleepQualityColor(_selectedHours))),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(child: TextButton(onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); }, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Cancel", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))))),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton(onPressed: () { HapticFeedback.mediumImpact(); widget.onSleepLogged(_selectedHours); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text("Log Sleep", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getSleepQualityFeedback(int hours) {
    if (hours <= 0) return "No Sleep";
    if (hours < 4) return "Poor Rest";
    if (hours < 6) return "Light Sleep";
    if (hours < 7) return "Fair Rest";
    if (hours < 8) return "Good Sleep";
    if (hours < 9) return "Great Rest";
    return "Perfect Sleep";
  }

  Color _getSleepQualityColor(int hours) {
    if (hours <= 0) return Colors.grey;
    if (hours < 4) return const Color(0xFFFF453A);
    if (hours < 6) return const Color(0xFFFF9F0A);
    if (hours < 7) return const Color(0xFFFFD60A);
    if (hours < 8) return const Color(0xFF30D158);
    if (hours < 9) return const Color(0xFF00C7BE);
    return const Color(0xFF007AFF);
  }
}

class UltraSleekStepsDialog extends StatefulWidget {
  final ValueChanged<int> onStepsLogged;
  const UltraSleekStepsDialog({super.key, required this.onStepsLogged});
  @override
  State<UltraSleekStepsDialog> createState() => _UltraSleekStepsDialogState();
}

class _UltraSleekStepsDialogState extends State<UltraSleekStepsDialog>
    with TickerProviderStateMixin {
  int _selectedMinutes = 30;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final int _stepsPerMinute = 100;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleController = AnimationController(duration: const Duration(milliseconds: 350), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _getWalkIntensityFeedback(int minutes) {
    if (minutes <= 0) return "No Activity";
    if (minutes < 15) return "Quick Stroll";
    if (minutes < 30) return "Light Walk";
    if (minutes < 60) return "Moderate Pace";
    if (minutes < 90) return "Brisk Walk";
    if (minutes < 120) return "Long Trek";
    return "Power Walk";
  }

  Color _getWalkIntensityColor(int minutes) {
    if (minutes <= 0) return Colors.grey;
    if (minutes < 15) return const Color(0xFF5AC8FA);
    if (minutes < 30) return const Color(0xFF00C7BE);
    if (minutes < 60) return const Color(0xFF30D158);
    if (minutes < 90) return const Color(0xFFFF9F0A);
    if (minutes < 120) return const Color(0xFFFF453A);
    return const Color(0xFFBF5AF2);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = kStepsColor;
    final int calculatedSteps = _selectedMinutes * _stepsPerMinute;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30)]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        children: [
                          Icon(Icons.timer_outlined, color: accent, size: 32),
                          const SizedBox(height: 12),
                          Text("Activity Duration", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text("How many minutes did you walk?", style: GoogleFonts.inter(fontSize: 15, color: Colors.white.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    Container(
                      height: 180,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 60,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.3), width: 1)),
                          ),
                          ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(initialItem: _selectedMinutes -1),
                            itemExtent: 60,
                            perspective: 0.003,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() => _selectedMinutes = index + 1);
                              HapticFeedback.selectionClick();
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 180,
                              builder: (context, index) {
                                final minute = index + 1;
                                final isSelected = _selectedMinutes == minute;
                                return Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(minute.toString(), style: GoogleFonts.inter(fontSize: isSelected ? 34 : 24, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : Colors.white.withOpacity(0.4))),
                                      const SizedBox(width: 8),
                                      Text("min", style: GoogleFonts.inter(fontSize: isSelected ? 16 : 14, fontWeight: FontWeight.w400, color: isSelected ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.3))),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: _getWalkIntensityColor(_selectedMinutes).withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: _getWalkIntensityColor(_selectedMinutes).withOpacity(0.4), width: 1)),
                            child: Text("${_getWalkIntensityFeedback(_selectedMinutes)}  •  ~$calculatedSteps steps", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _getWalkIntensityColor(_selectedMinutes))),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))))),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton(onPressed: () { HapticFeedback.mediumImpact(); widget.onStepsLogged(calculatedSteps); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black.withOpacity(0.7), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: Text("Log Activity", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}