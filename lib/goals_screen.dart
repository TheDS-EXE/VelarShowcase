import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math; // Needed for animations

// Color scheme to match the rest of the app
const Color primaryColor = Color(0xFF2C2C2C);
const Color secondaryColor = Color(0xFF8B0000);
const Color accentColor = Color(0xFFD32F2F);
const Color backgroundColor = Color(0xFF1A1A1A);
const Color textColor = Color(0xFFE0E0E0);
const Color cardColor = Color(0xFF242424);
// New color for the female selection glow
const Color femaleGlowColor = Color(0xFF98224D);


// Helper class to handle weight data consistently across screens.
class WeightEntry {
  final double weight;
  final DateTime date;

  WeightEntry({required this.weight, required this.date});
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

// MODIFIED: Added TickerProviderStateMixin for animations
class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
  // State variables for all user settings (LOGIC UNCHANGED)
  String? _selectedGoal;
  String? _selectedGender;
  String? _selectedActivityLevel;
  int _currentAge = 25;
  int _currentHeight = 170;
  int _currentWeight = 70;

  // Options for selection (LOGIC UNCHANGED)
  final List<String> _goals = ["Lose Weight", "Maintain Weight", "Gain Muscle"];
  final Set<String> _genders = {"Male", "Female"};
  final List<String> _activityLevels = [
    "Sedentary (little or no exercise)",
    "Lightly Active (light exercise/sports 1-3 days/week)",
    "Moderately Active (moderate exercise/sports 3-5 days/week)",
    "Very Active (hard exercise/sports 6-7 days a week)",
    "Super Active (very hard exercise & physical job)",
  ];

  // NEW: Animation controller for the pulsing CTA button
  late AnimationController _buttonPulseController;

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // LOGIC UNCHANGED

    // NEW: Initialize animation controller
    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // NEW: Dispose animation controller
    _buttonPulseController.dispose();
    super.dispose();
  }

  // ALL OF THE FOLLOWING DATA HANDLING METHODS ARE UNCHANGED
  // --- START OF UNCHANGED LOGIC ---
  Future<void> _saveString(String key, String? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedGoal = prefs.getString("user_goal");
      _selectedGender = prefs.getString("user_gender");
      _selectedActivityLevel = prefs.getString("user_activity_level");
      _currentAge = prefs.getInt("user_age") ?? 25;
      _currentHeight = prefs.getInt("userHeight") ?? 170;

      final weightHistory = prefs.getStringList('weightHistory') ?? [];
      if (weightHistory.isNotEmpty) {
        final entries = weightHistory.map((entry) {
          final parts = entry.split('|');
          return WeightEntry(weight: double.parse(parts[0]), date: DateTime.parse(parts[1]));
        }).toList();
        entries.sort((a, b) => b.date.compareTo(a.date));
        _currentWeight = entries.first.weight.round();
      } else {
        _currentWeight = 70;
      }
    });
  }

  Future<void> _calculateAndSaveCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final gender = _selectedGender ?? 'Male';
    final age = _currentAge;
    final height = _currentHeight;
    final weight = _currentWeight.toDouble();
    final activityLevel = _selectedActivityLevel ?? "Sedentary (little or no exercise)";
    final goal = _selectedGoal ?? "Maintain Weight";

    double bmr;
    if (gender == 'Male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    double activityMultiplier;
    if (activityLevel.startsWith("Sedentary")) {
      activityMultiplier = 1.2;
    } else if (activityLevel.startsWith("Lightly")) {
      activityMultiplier = 1.375;
    } else if (activityLevel.startsWith("Moderately")) {
      activityMultiplier = 1.55;
    } else if (activityLevel.startsWith("Very")) {
      activityMultiplier = 1.725;
    } else {
      activityMultiplier = 1.9;
    }
    final double tdee = bmr * activityMultiplier;

    double finalCalorieTarget;
    switch (goal) {
      case "Lose Weight":
        finalCalorieTarget = tdee - 500;
        break;
      case "Gain Muscle":
        finalCalorieTarget = tdee + 300;
        break;
      case "Maintain Weight":
      default:
        finalCalorieTarget = tdee;
        break;
    }

    int calculatedGoal = finalCalorieTarget.clamp(1200, 5000).round();
    await prefs.setInt('finalCalorieGoal', calculatedGoal);
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final weightHistory = prefs.getStringList('weightHistory') ?? [];
    List<WeightEntry> entries = weightHistory.map((entry) {
      final parts = entry.split('|');
      return WeightEntry(weight: double.parse(parts[0]), date: DateTime.parse(parts[1]));
    }).toList();

    final today = DateTime.now();
    final todayEntryIndex = entries.indexWhere((e) => _isSameDate(e.date, today));

    if (todayEntryIndex != -1) {
      entries[todayEntryIndex] = WeightEntry(weight: _currentWeight.toDouble(), date: entries[todayEntryIndex].date);
    } else {
      entries.add(WeightEntry(weight: _currentWeight.toDouble(), date: today));
    }

    entries.sort((a, b) => a.date.compareTo(b.date));
    final updatedHistory = entries.map((entry) => '${entry.weight}|${entry.date.toIso8601String()}').toList();
    await prefs.setStringList('weightHistory', updatedHistory);

    await Future.wait([
      if (_selectedGoal != null) prefs.setString("user_goal", _selectedGoal!),
      if (_selectedGender != null) prefs.setString("user_gender", _selectedGender!),
      if (_selectedActivityLevel != null) prefs.setString("user_activity_level", _selectedActivityLevel!),
      prefs.setInt("user_age", _currentAge),
      prefs.setInt("userHeight", _currentHeight),
    ]);

    await _calculateAndSaveCalorieGoal();

    if (mounted) {
      setState(() {
        _currentWeight = _currentWeight;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your profile has been updated!", style: GoogleFonts.inter(color: textColor)),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  // --- END OF UNCHANGED LOGIC ---


  // --- START OF NEW UI CODE ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // REMOVED AppBar for a minimal, premium look
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Fitness Goal Section ---
              _buildSectionTitle("What's Your Goal?"),
              const SizedBox(height: 16),
              _buildGoalSelection(),
              const SizedBox(height: 32),

              // --- Gender Section ---
              _buildSectionTitle("Select Your Gender"),
              const SizedBox(height: 16),
              _buildGenderSelection(),
              const SizedBox(height: 32),

              // --- Stats Section ---
              _buildSectionTitle("Tell Us About Yourself"),
              const SizedBox(height: 24),
              _buildStatSlider(
                title: "Age",
                value: _currentAge,
                minValue: 10,
                maxValue: 100,
                onChanged: (value) {
                  setState(() => _currentAge = value);
                  _saveInt("user_age", value);
                },
              ),
              const SizedBox(height: 20),
              _buildStatSlider(
                title: "Height",
                value: _currentHeight,
                minValue: 100,
                maxValue: 250,
                suffix: " cm",
                onChanged: (value) {
                  setState(() => _currentHeight = value);
                  _saveInt("userHeight", value);
                },
              ),
              const SizedBox(height: 20),
              _buildStatSlider(
                title: "Current Weight",
                value: _currentWeight,
                minValue: 30,
                maxValue: 200,
                suffix: " kg",
                onChanged: (value) => setState(() => _currentWeight = value),
              ),
              const SizedBox(height: 50),

              // --- Continue Button ---
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: textColor,
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // NEW: Replaces radio buttons with large, interactive cards
  Widget _buildGoalSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGoalCard("Lose Weight", Icons.whatshot, _selectedGoal == "Lose Weight"),
        _buildGoalCard("Maintain Weight", Icons.bolt, _selectedGoal == "Maintain Weight"),
        _buildGoalCard("Gain Muscle", Icons.fitness_center, _selectedGoal == "Gain Muscle"),
      ],
    );
  }

  Widget _buildGoalCard(String goal, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedGoal = goal);
          _saveString("user_goal", goal);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: accentColor.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: isSelected ? accentColor : textColor.withOpacity(0.7)),
              const SizedBox(height: 12),
              Text(
                goal.split(' ').join('\n'), // Split text into two lines
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: isSelected ? accentColor : textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Replaces segmented buttons with animated gender silhouettes
  Widget _buildGenderSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGenderAvatar("Male", Icons.male, _selectedGender == "Male"),
        const SizedBox(width: 30),
        _buildGenderAvatar("Female", Icons.female, _selectedGender == "Female"),
      ],
    );
  }

  Widget _buildGenderAvatar(String gender, IconData icon, bool isSelected) {
    final List<Color> glowColors = gender == "Male"
        ? [accentColor, accentColor.withOpacity(0.1)]
        : [femaleGlowColor, femaleGlowColor.withOpacity(0.1)];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedGender = gender);
        _saveString("user_gender", gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cardColor,
          border: Border.all(
            color: isSelected ? (gender == "Male" ? accentColor : femaleGlowColor) : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: glowColors[0].withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ]
              : [],
        ),
        child: Icon(icon, size: 50, color: isSelected ? glowColors[0] : textColor.withOpacity(0.7)),
      ),
    );
  }

  // NEW: Replaces +/- inputs with a modern, animated slider component
  Widget _buildStatSlider({
    required String title,
    required int value,
    required int minValue,
    required int maxValue,
    String suffix = "",
    required Function(int) onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.poppins(color: textColor, fontSize: 18, fontWeight: FontWeight.w500)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    '${value}',
                    key: ValueKey<int>(value), // Important for AnimatedSwitcher to detect change
                    style: GoogleFonts.poppins(color: textColor, fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
                if (suffix.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(suffix, style: GoogleFonts.poppins(color: textColor.withOpacity(0.6), fontSize: 14)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: cardColor,
            trackHeight: 6.0,
            thumbColor: accentColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
            overlayColor: accentColor.withOpacity(0.24),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
          ),
          child: Slider(
            value: value.toDouble(),
            min: minValue.toDouble(),
            max: maxValue.toDouble(),
            onChanged: (double newValue) {
              onChanged(newValue.round());
            },
          ),
        ),
      ],
    );
  }

  // NEW: Replaces the basic button with a large, glowing, pulsing CTA
  Widget _buildContinueButton() {
    return AnimatedBuilder(
      animation: _buttonPulseController,
      builder: (context, child) {
        final double glowAmount = 5.0 + (_buttonPulseController.value * 10.0);
        return GestureDetector(
          onTap: _saveProfileData,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: glowAmount,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Center(
        child: Text(
          "Save Goals",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}