// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

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

// --- Constants ---
const double kPi = 3.1415926535897932;
const int kDailyCalorieGoal = 2000;
const int kDailyStepGoal = 10000;
const int kDailyWaterGoal = 8;
const int kDailySleepGoal = 8;

// Calorie calculation constants
const double kCaloriesPerStep = 0.04; // Approximately 40 calories per 1000 steps

// Color scheme
const Color primaryColor = Color(0xFF2C2C2C); // Dark grey
const Color secondaryColor = Color(0xFF8B0000); // Dark red
const Color accentColor = Color(0xFFD32F2F); // Lighter red for accents
const Color backgroundColor = Color(0xFF1A1A1A); // Almost black
const Color textColor = Color(0xFFE0E0E0); // Light grey text
const Color cardColor = Color(0xFF242424); // Slightly lighter dark for cards

// Colors for the circular progress indicators
const Color kCaloriesColor = Color(0xFFFF6B6B);
const Color kStepsColor = Color(0xFF4ECDC4);
const Color kWaterColor = Color(0xFF45B7D1);
const Color kSleepColor = Color(0xFF96CEB4);

// MODIFICATION: main is now async to check login status before running the app
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Check SharedPreferences for the "remember me" flag
  final prefs = await SharedPreferences.getInstance();
  final bool rememberMe = prefs.getBool('rememberMe') ?? false;

  runApp(NutritionTrackerApp(rememberMe: rememberMe));
}

class NutritionTrackerApp extends StatelessWidget {
  // MODIFICATION: Added rememberMe property to decide the initial screen
  final bool rememberMe;

  const NutritionTrackerApp({super.key, required this.rememberMe});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrition & Steps Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      // MODIFICATION: Show HomeScreen if remembered, otherwise show LoginScreen
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
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, backgroundColor],
        ),
      ),
      child: Scaffold(
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
          _buildNavItem(index: 2, icon: Icons.bar_chart, label: "Progress"),
          _buildNavItem(index: 3, icon: Icons.flag, label: "Goals"),
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

  // MODIFICATION: This function now reads calorie data from the detailed food diary
  void _loadDailyData() async {
    final prefs = await SharedPreferences.getInstance();

    // New logic for loading calories from the food diary
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
        // Fallback to the old key in case of a JSON error
        print('Error loading calorie diary data: $e');
        todayCalories = prefs.getInt('totalCalories') ?? 0;
      }
    } else {
      // Fallback if the diary doesn't exist yet
      todayCalories = prefs.getInt('totalCalories') ?? 0;
    }

    setState(() {
      caloriesConsumed = todayCalories; // Set the correctly loaded calories
      _calorieGoal = prefs.getInt('finalCalorieGoal') ?? 2000;
      stepsTaken = prefs.getInt(_stepsKey) ?? 0;
      waterIntake = prefs.getInt(_waterKey) ?? 0;
      sleepHours = prefs.getInt(_sleepKey) ?? 0;
    });
  }

  void _loadPersonalBests() async {
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

  // MODIFICATION: Removed saving to 'totalCalories' to prevent data conflicts.
  // The food screen is now the single source of truth for calorie data.
  void _saveDailyData() async {
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

  void _addWater() {
    setState(() {
      waterIntake += 1;
    });
    _saveDailyData();
    _loadPersonalBests();
  }

  void _logSleep(int hours) {
    setState(() {
      sleepHours = hours;
    });
    _saveDailyData();
  }

  void _addSteps() async {
    final TextEditingController stepsController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text("Log Steps",
            style: GoogleFonts.poppins(color: textColor)),
        content: TextField(
          controller: stepsController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textColor),
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Enter steps taken",
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: textColor.withOpacity(0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            Text("Cancel", style: GoogleFonts.inter(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              final int? newSteps = int.tryParse(stepsController.text);
              if (newSteps != null && newSteps > 0) {
                setState(() {
                  stepsTaken += newSteps;
                });
                _saveDailyData();
                _loadPersonalBests();
              }
              Navigator.pop(context);
            },
            child: Text("Log", style: GoogleFonts.inter(color: accentColor)),
          ),
        ],
      ),
    );
  }

  // ADDED: Function to classify calories remaining like the calorie classification screen
  String _classifyCaloriesRemaining(int caloriesConsumed, int calorieGoal) {
    final int caloriesRemaining = calorieGoal - caloriesConsumed;

    if (caloriesRemaining <= 0) return "Overshot Gains";
    if (caloriesRemaining <= 50) return "Final Push";
    if (caloriesRemaining <= 150) return "Cruising Strong";
    if (caloriesRemaining <= 300) return "Warm-Up Phase";
    if (caloriesRemaining <= 500) return "Getting Started";
    if (caloriesRemaining <= 700) return "Empty Tank";
    return "Set a Goal!";
  }

  @override
  Widget build(BuildContext context) {
    final String calorieBurnFeedback =
    _getCalorieBurnFeedback(_mostCaloriesBurned);
    final String stepBestFeedback = _getStepLevelFeedback(_mostSteps);
    final String waterBestFeedback = _getWaterLevelFeedback(_mostWater);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        child: Column(
          children: [
            _buildDailySummaryCard(),
            const SizedBox(height: 30),
            _buildStreakHeatmap(),
            const SizedBox(height: 16),
            _buildPersonalBestShowcase(
              stepBestFeedback,
              calorieBurnFeedback,
              waterBestFeedback,
            ),
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
    // MODIFIED: Use classification instead of numbers for calories
    final String caloriesFeedback =
    _classifyCaloriesRemaining(caloriesConsumed, _calorieGoal);

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
                displayText:
                caloriesFeedback, // MODIFIED: Use classification instead of numbers
                onTap: _navigateToCaloriesScreen,
              ),
              _buildMetricBarChart(
                icon: Icons.directions_walk,
                color: kStepsColor,
                label: "Steps",
                currentValue: stepsTaken,
                goalValue: kDailyStepGoal,
                displayText: stepFeedback,
                onTap: _addSteps,
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
          const SizedBox(height: 8),
          Text(
            displayText,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: textColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          // --- MODIFICATION START ---
          // Replaced IconButton with a custom GestureDetector to fix RenderFlex error
          // and apply a circular background with a glow effect.
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
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
                label == "Calories" ? Icons.restaurant_outlined : Icons.add,
                color: textColor.withOpacity(0.9),
                size: 20,
              ),
            ),
          ),
          // --- MODIFICATION END ---
        ],
      ),
    );
  }

  // --- MODIFICATION START ---
  // Replaced the simple timer dialog with the new circular sleep clock dialog.
  void _showSleepDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          CircularSleepLoggerDialog(onSleepLogged: _logSleep),
    );
  }
  // --- MODIFICATION END ---

  Widget _buildStreakHeatmap() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final startingWeekday = (firstDayOfMonth.weekday == DateTime.sunday)
        ? 7
        : firstDayOfMonth.weekday;

    final List<String> dayHeaders = [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
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

  Widget _buildPersonalBestShowcase(
      String stepBestFeedback,
      String calorieBurnFeedback,
      String waterBestFeedback,
      ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Personal Bests",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPersonalBestItem(
                icon: Icons.directions_walk,
                value: stepBestFeedback,
                label: "Most Steps",
                date: _stepsDate,
              ),
              _buildPersonalBestItem(
                icon: Icons.local_fire_department,
                value: calorieBurnFeedback,
                label: "Calories Burned",
                date: _caloriesDate,
              ),
              _buildPersonalBestItem(
                icon: Icons.water_drop,
                value: waterBestFeedback,
                label: "Water Intake",
                date: _waterDate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestItem({
    required IconData icon,
    required String value,
    required String label,
    required String date,
  }) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2),
        Text(label,
            style: GoogleFonts.inter(
                color: textColor.withOpacity(0.7), fontSize: 10)),
        if (date.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(date,
              style: GoogleFonts.inter(color: accentColor, fontSize: 10)),
        ],
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

// --- MODIFICATION START ---
// The old SleepLoggerDialog has been replaced with the new CircularSleepLoggerDialog and its painter.

class CircularSleepLoggerDialog extends StatefulWidget {
  final ValueChanged<int> onSleepLogged;

  const CircularSleepLoggerDialog({super.key, required this.onSleepLogged});

  @override
  State<CircularSleepLoggerDialog> createState() =>
      _CircularSleepLoggerDialogState();
}

class _CircularSleepLoggerDialogState extends State<CircularSleepLoggerDialog> {
  // Angles in radians. 0 is 6 AM, PI/2 is 12 PM, etc.
  double _startAngle = 4.71239; // 10 PM
  double _endAngle = 0; // 6 AM

  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;

  TimeOfDay get _startTime => _angleToTime(_startAngle);
  TimeOfDay get _endTime => _angleToTime(_endAngle);

  Duration get _sleepDuration {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes >= startMinutes) {
      return Duration(minutes: endMinutes - startMinutes);
    } else {
      // Crosses midnight
      return Duration(minutes: (24 * 60 - startMinutes) + endMinutes);
    }
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final Offset touchPosition = details.localPosition - center;
    final double touchAngle = _getAngle(touchPosition);

    // Check if the touch is near the start handle
    final double startHandleAngle = _startAngle;
    final double distanceToStart = _angleDistance(touchAngle, startHandleAngle);
    if (distanceToStart < 0.2) {
      _isDraggingStart = true;
      return;
    }

    // Check if the touch is near the end handle
    final double endHandleAngle = _endAngle;
    final double distanceToEnd = _angleDistance(touchAngle, endHandleAngle);
    if (distanceToEnd < 0.2) {
      _isDraggingEnd = true;
      return;
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Offset touchPosition = details.localPosition - center;
    final double newAngle = _getAngle(touchPosition);

    if (_isDraggingStart) {
      setState(() {
        _startAngle = newAngle;
      });
    } else if (_isDraggingEnd) {
      setState(() {
        _endAngle = newAngle;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isDraggingStart = false;
    _isDraggingEnd = false;
  }

  double _getAngle(Offset position) {
    double angle = atan2(position.dy, position.dx);
    // Convert to 0 to 2π range
    if (angle < 0) angle += 2 * pi;
    return angle;
  }

  double _angleDistance(double a, double b) {
    double diff = (a - b).abs();
    return min(diff, 2 * pi - diff);
  }

  TimeOfDay _angleToTime(double angle) {
    // Convert angle to 24-hour time
    // 0 radians = 6:00 AM (6*60=360 minutes)
    // 2π radians = 24 hours (1440 minutes)
    const int minutesInDay = 24 * 60;
    const double minutesPerRadian = minutesInDay / (2 * pi);

    // Offset by 6 hours (360 minutes) so 0 radians = 6 AM
    double minutes = (angle * minutesPerRadian + 6 * 60) % minutesInDay;
    int hour = (minutes ~/ 60) % 24;
    int minute = (minutes % 60).round();

    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        height: 400,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Log Your Sleep",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onPanStart: (details) => _onPanStart(details, size),
                    onPanUpdate: (details) => _onPanUpdate(details, size),
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      size: size,
                      painter: SleepClockPainter(
                        startAngle: _startAngle,
                        endAngle: _endAngle,
                        isDraggingStart: _isDraggingStart,
                        isDraggingEnd: _isDraggingEnd,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Sleep Duration: ${_sleepDuration.inHours}h ${_sleepDuration.inMinutes.remainder(60)}m",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(color: textColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onSleepLogged(_sleepDuration.inHours);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                  ),
                  child: Text(
                    "Log Sleep",
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SleepClockPainter extends CustomPainter {
  final double startAngle;
  final double endAngle;
  final bool isDraggingStart;
  final bool isDraggingEnd;

  SleepClockPainter({
    required this.startAngle,
    required this.endAngle,
    required this.isDraggingStart,
    required this.isDraggingEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Draw clock background
    final clockPaint = Paint()
      ..color = Colors.grey.shade800.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, clockPaint);

    // Draw sleep arc
    final sleepPaint = Paint()
      ..color = kSleepColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Calculate the sleep arc
    final double sleepStartAngle = startAngle;
    double sleepSweepAngle = endAngle - startAngle;
    if (sleepSweepAngle < 0) sleepSweepAngle += 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sleepStartAngle,
      sleepSweepAngle,
      false,
      sleepPaint,
    );

    // Draw clock markers
    final markerPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 12; i++) {
      final double angle = i * pi / 6;
      final Offset start = Offset(
        center.dx + (radius - 15) * cos(angle),
        center.dy + (radius - 15) * sin(angle),
      );
      final Offset end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(start, end, markerPaint);
    }

    // Draw time labels
    const List<String> labels = ["6", "9", "12", "3"];
    const List<double> labelAngles = [0, pi / 2, pi, 3 * pi / 2];
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
    );

    for (int i = 0; i < labels.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final double angle = labelAngles[i];
      final Offset position = Offset(
        center.dx + (radius - 30) * cos(angle) - textPainter.width / 2,
        center.dy + (radius - 30) * sin(angle) - textPainter.height / 2,
      );

      canvas.save();
      canvas.translate(position.dx, position.dy);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Draw start and end handles
    final startHandlePaint = Paint()
      ..color = isDraggingStart ? Colors.white : kSleepColor
      ..style = PaintingStyle.fill;

    final endHandlePaint = Paint()
      ..color = isDraggingEnd ? Colors.white : kSleepColor
      ..style = PaintingStyle.fill;

    final Offset startHandlePos = Offset(
      center.dx + radius * cos(startAngle),
      center.dy + radius * sin(startAngle),
    );

    final Offset endHandlePos = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );

    canvas.drawCircle(startHandlePos, 12, startHandlePaint);
    canvas.drawCircle(endHandlePos, 12, endHandlePaint);
  }

  @override
  bool shouldRepaint(covariant SleepClockPainter oldDelegate) {
    return startAngle != oldDelegate.startAngle ||
        endAngle != oldDelegate.endAngle ||
        isDraggingStart != oldDelegate.isDraggingStart ||
        isDraggingEnd != oldDelegate.isDraggingEnd;
  }
}
// --- MODIFICATION END ---