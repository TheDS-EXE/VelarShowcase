// lib/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math; // Needed for animations
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For more icons

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

class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
  // State variables for all user settings
  String? _selectedGoal;
  String? _selectedGender;
  String? _selectedActivityLevel;
  int _currentAge = 25;
  int _currentHeight = 170;

  int _goalWeight = 70;
  int _currentWeightForCalc = 70;


  // Options for selection
  final List<String> _goals = ["Lose Weight", "Maintain Weight", "Gain Muscle"];
  final Set<String> _genders = {"Male", "Female"};
  final List<String> _activityLevels = [
    "Sedentary (little or no exercise)",
    "Lightly Active (light exercise/sports 1-3 days/week)",
    "Moderately Active (moderate exercise/sports 3-5 days/week)",
    "Very Active (hard exercise/sports 6-7 days a week)",
    "Super Active (very hard exercise & physical job)",
  ];

  final Map<String, IconData> _activityIcons = {
    "Sedentary (little or no exercise)": FontAwesomeIcons.couch,
    "Lightly Active (light exercise/sports 1-3 days/week)": FontAwesomeIcons.personWalking,
    "Moderately Active (moderate exercise/sports 3-5 days/week)": FontAwesomeIcons.personRunning,
    "Very Active (hard exercise/sports 6-7 days a week)": FontAwesomeIcons.dumbbell,
    "Super Active (very hard exercise & physical job)": FontAwesomeIcons.fire,
  };

  late AnimationController _buttonPulseController;

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _buttonPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    int loadedCurrentWeight = 70;

    // Load the user's actual current weight from their history for calculations
    final weightHistory = prefs.getStringList('weightHistory') ?? [];
    if (weightHistory.isNotEmpty) {
      final entries = weightHistory.map((entry) {
        final parts = entry.split('|');
        return WeightEntry(weight: double.parse(parts[0]), date: DateTime.parse(parts[1]));
      }).toList();
      entries.sort((a, b) => b.date.compareTo(a.date));
      loadedCurrentWeight = entries.first.weight.round();
    }

    setState(() {
      _currentWeightForCalc = loadedCurrentWeight;

      _selectedGoal = prefs.getString("user_goal");
      _selectedGender = prefs.getString("user_gender");
      _selectedActivityLevel = prefs.getString("user_activity_level");
      _currentAge = prefs.getInt("user_age") ?? 25;
      _currentHeight = prefs.getInt("userHeight") ?? 170;

      // Load the goal weight, defaulting to their current weight if not set
      _goalWeight = prefs.getInt("user_goal_weight") ?? loadedCurrentWeight;
    });
  }

  Future<void> _calculateAndSaveCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final gender = _selectedGender ?? 'Male';
    final age = _currentAge;
    final height = _currentHeight;
    final weight = _currentWeightForCalc.toDouble();
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

    // CORRECTED: This function no longer reads from or writes to 'weightHistory'.
    // It only saves the profile and goal settings.
    await Future.wait([
      if (_selectedGoal != null) prefs.setString("user_goal", _selectedGoal!),
      if (_selectedGender != null) prefs.setString("user_gender", _selectedGender!),
      if (_selectedActivityLevel != null) prefs.setString("user_activity_level", _selectedActivityLevel!),
      prefs.setInt("user_age", _currentAge),
      prefs.setInt("userHeight", _currentHeight),
      prefs.setInt("user_goal_weight", _goalWeight), // Save the goal weight
    ]);

    await _calculateAndSaveCalorieGoal();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your profile and goals have been updated!", style: GoogleFonts.inter(color: textColor)),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Your Goals & Profile',
          style: GoogleFonts.poppins(color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle("What's Your Goal?"),
            const SizedBox(height: 16),
            _buildGoalSelection(),
            const SizedBox(height: 32),

            _buildSectionTitle("Select Your Gender"),
            const SizedBox(height: 16),
            _buildGenderSelection(),
            const SizedBox(height: 32),

            _buildSectionTitle("Tell Us About Yourself"),
            const SizedBox(height: 24),
            _buildStatSlider(
              title: "Age",
              value: _currentAge,
              minValue: 10,
              maxValue: 100,
              onChanged: (value) {
                setState(() => _currentAge = value);
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
              },
            ),
            const SizedBox(height: 20),
            _buildStatSlider(
              title: "Goal Weight",
              value: _goalWeight,
              minValue: 30,
              maxValue: 200,
              suffix: " kg",
              onChanged: (value) => setState(() => _goalWeight = value),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle("Activity Level"),
            const SizedBox(height: 16),
            _buildActivityLevelSelection(),
            const SizedBox(height: 50),

            _buildContinueButton(),
          ],
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
                goal.split(' ').join('\n'),
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
                    '$value',
                    key: ValueKey<int>(value),
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

  Widget _buildActivityLevelSelection() {
    return Column(
      children: _activityLevels.map((level) {
        bool isSelected = _selectedActivityLevel == level;
        return _buildActivityCard(level, _activityIcons[level]!, isSelected);
      }).toList(),
    );
  }

  Widget _buildActivityCard(String level, IconData icon, bool isSelected) {
    final parts = level.split(' (');
    final title = parts[0];
    final subtitle = parts.length > 1 ? '(${parts[1]}' : '';

    return GestureDetector(
      onTap: () {
        setState(() => _selectedActivityLevel = level);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ] : [],
        ),
        child: Row(
          children: [
            FaIcon(icon, color: isSelected ? accentColor : textColor.withOpacity(0.7), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isSelected ? accentColor : textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: textColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: accentColor, size: 24),
          ],
        ),
      ),
    );
  }

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
          "Save Profile & Goals",
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