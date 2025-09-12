import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:replog_icons/replog_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Consistent styling for the new theme
const Color accentColor = Color(0xFFE53935); // A brighter, more energetic red
const Color backgroundColor = Color(0xFF000000); // True black for high contrast
const Color cardColor = Color(0xFF1A1A1A); // Very dark grey for cards
const Color textColor = Color(0xFFFFFFFF); // Pure white for text
const Color mutedTextColor = Color(0xFF8A8A8A); // Muted grey for subtitles

// --- Data Models for Workouts ---
enum WorkoutType { timeBased, repBased, breathing }

class Workout {
  final String name;
  final String description;
  final String goal;
  final String subtitle;
  final WorkoutType type;
  final IconData icon;

  Workout({
    required this.name,
    required this.description,
    required this.goal,
    required this.subtitle,
    required this.type,
    required this.icon,
  });
}
// --- End of Data Models ---


class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> with TickerProviderStateMixin {
  // Workouts curated based on hypertrophy principles
  final Map<String, List<Workout>> _workoutsByMood = {
    'Energetic': [
      Workout(name: 'Barbell Squats', description: 'The king of leg exercises for overall mass.', goal: '3 sets of 8-12', subtitle: '3 sets • Strength', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Romanian Deadlifts', description: 'Targets hamstrings and glutes with a hip hinge.', goal: '3 sets of 10-15', subtitle: '3 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.weightHanging),
      Workout(name: 'Leg Press', description: 'A stable alternative to squats for quad volume.', goal: '4 sets of 12-20', subtitle: '4 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Bench Press', description: 'Builds the chest, shoulders, and triceps.', goal: '3 sets of 8-12', subtitle: '3 sets • Strength', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Pull-Ups', description: 'Develops back width and bicep strength.', goal: '3 sets to failure', subtitle: '3 sets • Bodyweight', type: WorkoutType.repBased, icon: FontAwesomeIcons.person),
      Workout(name: 'Overhead Press', description: 'Builds strong and broad shoulders.', goal: '3 sets of 8-12', subtitle: '3 sets • Strength', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Bent Over Rows', description: 'Develops back thickness and pulling strength.', goal: '3 sets of 10-15', subtitle: '3 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.weightHanging),
      Workout(name: 'Incline Dumbbell Press', description: 'Emphasizes the upper chest for a fuller look.', goal: '3 sets of 10-15', subtitle: '3 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'HIIT Sprints', description: 'High-intensity cardio to boost metabolism.', goal: '8 rounds of 30s', subtitle: '15 min • Cardio', type: WorkoutType.timeBased, icon: FontAwesomeIcons.personRunning),
      Workout(name: 'Dumbbell Lunges', description: 'Unilateral exercise for leg stability and growth.', goal: '3 sets of 12-15', subtitle: '3 sets • Stability', type: WorkoutType.repBased, icon: FontAwesomeIcons.personWalking),
      Workout(name: 'Lat Pulldowns', description: 'A stable alternative to pull-ups.', goal: '3 sets of 12-20', subtitle: '3 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Skull Crushers', description: 'An isolation exercise for tricep mass.', goal: '3 sets of 12-20', subtitle: '3 sets • Isolation', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Bicep Curls', description: 'The classic exercise for building bicep peaks.', goal: '3 sets of 12-20', subtitle: '3 sets • Isolation', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Lateral Raises', description: 'Builds the side delts for shoulder width.', goal: '4 sets of 15-25', subtitle: '4 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Calf Raises', description: 'Targets the gastrocnemius for calf growth.', goal: '4 sets of 15-25', subtitle: '4 sets • Isolation', type: WorkoutType.repBased, icon: FontAwesomeIcons.personWalking),
    ],
    'Strong': [
      Workout(name: 'Deadlifts', description: 'A full-body lift for maximum strength.', goal: '3 sets of 5-8', subtitle: '3 sets • Strength', type: WorkoutType.repBased, icon: FontAwesomeIcons.weightHanging),
      Workout(name: 'Heavy Squats', description: 'Focus on strength with lower reps.', goal: '4 sets of 5-8', subtitle: '4 sets • Strength', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Heavy Bench Press', description: 'Build raw pressing power.', goal: '4 sets of 5-8', subtitle: '4 sets • Strength', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Weighted Pull-Ups', description: 'Adds intensity to the classic pull-up.', goal: '4 sets of 5-8', subtitle: '4 sets • Strength', type: WorkoutType.repBased, icon: FontAwesomeIcons.person),
      Workout(name: 'Push Press', description: 'An explosive overhead pressing movement.', goal: '3 sets of 5-8', subtitle: '3 sets • Power', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Leg Curls', description: 'Isolates the hamstrings for hypertrophy.', goal: '3 sets of 12-20', subtitle: '3 sets • Isolation', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Seated Cable Rows', description: 'A stable exercise for back thickness.', goal: '3 sets of 12-20', subtitle: '3 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Dumbbell Shoulder Press', description: 'Builds stable and strong shoulders.', goal: '3 sets of 10-15', subtitle: '3 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.dumbbell),
      Workout(name: 'Bulgarian Split Squats', description: 'A challenging unilateral leg exercise.', goal: '3 sets of 10-15', subtitle: '3 sets • Stability', type: WorkoutType.repBased, icon: FontAwesomeIcons.personWalking),
      Workout(name: 'T-Bar Rows', description: 'Targets the mid-back for thickness.', goal: '3 sets of 10-15', subtitle: '3 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.weightHanging),
      Workout(name: 'Face Pulls', description: 'Crucial for rear delt and rotator cuff health.', goal: '4 sets of 20-30', subtitle: '4 sets • Health', type: WorkoutType.repBased, icon: FontAwesomeIcons.solidFaceGrin),
      Workout(name: 'Hip Thrusts', description: 'The best exercise for direct glute work.', goal: '4 sets of 10-15', subtitle: '4 sets • Hypertrophy', type: WorkoutType.repBased, icon: FontAwesomeIcons.weightHanging),
      Workout(name: 'Farmer\'s Walk', description: 'Builds immense grip strength and core stability.', goal: '3 sets of 30s', subtitle: '30 sec • Strength', type: WorkoutType.timeBased, icon: FontAwesomeIcons.personWalking),
      Workout(name: 'Ab Wheel Rollouts', description: 'An advanced exercise for a strong core.', goal: '3 sets of 10-15', subtitle: '3 sets • Core', type: WorkoutType.repBased, icon: FontAwesomeIcons.gear),
      Workout(name: 'Shrugs', description: 'Directly targets the traps.', goal: '4 sets of 15-20', subtitle: '4 sets • Isolation', type: WorkoutType.repBased, icon: FontAwesomeIcons.person),
    ],
    'Tired': [
      Workout(name: 'Foam Rolling', description: 'Soothes sore muscles and aids recovery.', goal: '10 minutes', subtitle: '10 min • Recovery', type: WorkoutType.timeBased, icon: FontAwesomeIcons.circle),
      Workout(name: 'Mobility Drills', description: 'Active movements to improve joint range.', goal: '15 minutes', subtitle: '15 min • Mobility', type: WorkoutType.timeBased, icon: FontAwesomeIcons.arrowsRotate),
      Workout(name: 'Light Technique Work', description: 'Practice form on a main lift with very light weight.', goal: '5 sets of 5', subtitle: '5 sets • Technique', type: WorkoutType.repBased, icon: FontAwesomeIcons.feather),
      Workout(name: 'Mindful Walking', description: 'Low-impact cardio to promote blood flow.', goal: '30 minutes', subtitle: '30 min • Cardio', type: WorkoutType.timeBased, icon: FontAwesomeIcons.personWalking),
      Workout(name: 'Band Pull-Aparts', description: 'Strengthens the rear delts and upper back.', goal: '3 sets of 25-30', subtitle: '3 sets • Health', type: WorkoutType.repBased, icon: FontAwesomeIcons.gripLines),
      Workout(name: 'Dead Hangs', description: 'Decompresses the spine and improves grip.', goal: '3 sets of 30s', subtitle: '30 sec • Health', type: WorkoutType.timeBased, icon: FontAwesomeIcons.hand),
      Workout(name: 'Wall Slides', description: 'Improves shoulder mobility and posture.', goal: '3 sets of 15-20', subtitle: '3 sets • Mobility', type: WorkoutType.repBased, icon: FontAwesomeIcons.person),
      Workout(name: 'Glute Bridges', description: 'Activates the glutes without heavy load.', goal: '3 sets of 20-25', subtitle: '3 sets • Activation', type: WorkoutType.repBased, icon: FontAwesomeIcons.arrowUp),
      Workout(name: 'Bird-Dog', description: 'Enhances core stability and balance.', goal: '3 sets of 15-20', subtitle: '3 sets • Stability', type: WorkoutType.repBased, icon: FontAwesomeIcons.dog),
      Workout(name: 'Cat-Cow Stretch', description: 'Increases spinal flexibility.', goal: '3 sets of 15-20', subtitle: '3 sets • Mobility', type: WorkoutType.repBased, icon: FontAwesomeIcons.cat),
      Workout(name: 'Light Sled Drags', description: 'Active recovery that is easy on the joints.', goal: '10 minutes', subtitle: '10 min • Recovery', type: WorkoutType.timeBased, icon: FontAwesomeIcons.sleigh),
      Workout(name: 'Light Yoga', description: 'Gentle poses to relax body and mind.', goal: '20 minutes', subtitle: '20 min • Flexibility', type: WorkoutType.timeBased, icon: FontAwesomeIcons.spa),
      Workout(name: 'Couch Stretch', description: 'Opens up tight hip flexors.', goal: '3 sets of 60s', subtitle: '60 sec • Flexibility', type: WorkoutType.timeBased, icon: FontAwesomeIcons.couch),
      Workout(name: 'Pigeon Pose', description: 'A deep stretch for the glutes and hips.', goal: '3 sets of 60s', subtitle: '60 sec • Flexibility', type: WorkoutType.timeBased, icon: FontAwesomeIcons.dove),
      Workout(name: 'Gentle Swimming', description: 'Full-body, no-impact active recovery.', goal: '20 minutes', subtitle: '20 min • Cardio', type: WorkoutType.timeBased, icon: FontAwesomeIcons.personSwimming),
    ],
    'Calm': [
      Workout(name: 'Box Breathing', description: 'A technique to calm the nervous system.', goal: '5 minutes', subtitle: '5 min • Relaxation', type: WorkoutType.breathing, icon: FontAwesomeIcons.wind),
      Workout(name: 'Walking Meditation', description: 'Mindful movement to focus the mind.', goal: '15 minutes', subtitle: '15 min • Mindfulness', type: WorkoutType.timeBased, icon: FontAwesomeIcons.personWalking),
      Workout(name: 'Body Scan Meditation', description: 'Bring awareness to each part of your body.', goal: '10 minutes', subtitle: '10 min • Mindfulness', type: WorkoutType.timeBased, icon: FontAwesomeIcons.bed),
      Workout(name: 'Yin Yoga', description: 'Slow-paced style with long-held poses.', goal: '30 minutes', subtitle: '30 min • Flexibility', type: WorkoutType.timeBased, icon: FontAwesomeIcons.spa),
      Workout(name: 'Tai Chi Forms', description: 'A moving meditation for balance.', goal: '20 minutes', subtitle: '20 min • Balance', type: WorkoutType.timeBased, icon: FontAwesomeIcons.person),
      Workout(name: 'Seated Meditation', description: 'Classic mindfulness practice.', goal: '15 minutes', subtitle: '15 min • Mindfulness', type: WorkoutType.timeBased, icon: FontAwesomeIcons.person),
      Workout(name: 'Child\'s Pose', description: 'A restorative pose to relax and stretch.', goal: '5 minutes', subtitle: '5 min • Flexibility', type: WorkoutType.timeBased, icon: FontAwesomeIcons.child),
      Workout(name: 'Legs Up The Wall', description: 'A passive, restorative pose.', goal: '10 minutes', subtitle: '10 min • Recovery', type: WorkoutType.timeBased, icon: FontAwesomeIcons.person),
      Workout(name: 'Mindful Stretching', description: 'Focus on the sensation of each stretch.', goal: '15 minutes', subtitle: '15 min • Flexibility', type: WorkoutType.timeBased, icon: FontAwesomeIcons.person),
      Workout(name: 'Nature Sounds', description: 'Listen to calming sounds of nature.', goal: '10 minutes', subtitle: '10 min • Relaxation', type: WorkoutType.timeBased, icon: FontAwesomeIcons.tree),
      Workout(name: 'Guided Relaxation', description: 'Follow a guided meditation for relaxation.', goal: '15 minutes', subtitle: '15 min • Mindfulness', type: WorkoutType.timeBased, icon: FontAwesomeIcons.headphones),
      Workout(name: 'Diaphragmatic Breathing', description: 'Deep belly breathing to reduce stress.', goal: '5 minutes', subtitle: '5 min • Relaxation', type: WorkoutType.breathing, icon: FontAwesomeIcons.wind),
      Workout(name: 'Light Rowing', description: 'A rhythmic, meditative cardio exercise.', goal: '15 minutes', subtitle: '15 min • Cardio', type: WorkoutType.timeBased, icon: FontAwesomeIcons.person),
      Workout(name: 'Savasana', description: 'The final relaxation pose in yoga.', goal: '10 minutes', subtitle: '10 min • Recovery', type: WorkoutType.timeBased, icon: FontAwesomeIcons.bed),
      Workout(name: 'Mindful Doodling', description: 'A creative way to focus and de-stress.', goal: '10 minutes', subtitle: '10 min • Mindfulness', type: WorkoutType.timeBased, icon: FontAwesomeIcons.pencil),
    ],
  };

  final Map<String, IconData> _moodIcons = {
    'Energetic': FontAwesomeIcons.boltLightning,
    'Strong': FontAwesomeIcons.dumbbell,
    'Calm': FontAwesomeIcons.spa,
    'Tired': FontAwesomeIcons.bed,
  };

  final Map<String, Color> _moodColors = {
    'Energetic': Colors.orange,
    'Strong': Colors.redAccent,
    'Calm': Colors.blue,
    'Tired': Colors.green,
  };

  List<Workout> _fullWorkoutList = [];
  List<Workout> _displayedWorkouts = [];
  String _selectedMood = 'Energetic';
  Set<String> _completedWorkoutsToday = {};
  String? _activeWorkoutName;
  bool _isTimerRunningInBackground = false;
  var _listKey = const ValueKey<int>(0);
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;
  late AnimationController _headerAnimController;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _loadSavedState();
    _checkAndShowMoodPopup();
    _pageController.addListener(() {
      if (mounted && _pageController.page != null) {
        if (_pageController.page!.round() != _currentPage) {
          setState(() {
            _currentPage = _pageController.page!.round();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    await _loadCompletedWorkoutsToday();
    await _loadActiveWorkoutState();
  }

  Future<void> _loadCompletedWorkoutsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'completedWorkouts_${_formatDate(DateTime.now())}';
    final completed = prefs.getStringList(key) ?? [];
    if (mounted) setState(() => _completedWorkoutsToday = completed.toSet());
  }

  Future<void> _loadActiveWorkoutState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _activeWorkoutName = prefs.getString('activeWorkoutName');
        _isTimerRunningInBackground = prefs.getBool('isTimerRunning') ?? false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _checkAndShowMoodPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _formatDate(DateTime.now());
    final lastShownDate = prefs.getString('lastMoodPopupDate');

    if (lastShownDate != today) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMoodSelectionPopup();
      });
    } else {
      final lastMood = prefs.getString('lastSelectedMood') ?? 'Energetic';
      _updateWorkoutsForMood(lastMood);
    }
  }

  Future<void> _handleMoodSelection(String mood) async {
    _updateWorkoutsForMood(mood);
    final prefs = await SharedPreferences.getInstance();
    final today = _formatDate(DateTime.now());
    await prefs.setString('lastMoodPopupDate', today);
    await prefs.setString('lastSelectedMood', mood);
    if (mounted) Navigator.pop(context);
  }

  void _updateWorkoutsForMood(String mood) {
    final fullList = _workoutsByMood[mood] ?? [];
    setState(() {
      _selectedMood = mood;
      _fullWorkoutList = fullList;
      _displayedWorkouts = fullList.take(5).toList();
      _listKey = ValueKey<int>(_listKey.value + 1);
      _headerAnimController.forward(from: 0);
    });

    // Reset to the first page to ensure a consistent state
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _shuffleWorkouts() {
    final fullList = List<Workout>.from(_fullWorkoutList);
    fullList.shuffle();
    setState(() {
      _displayedWorkouts = fullList.take(5).toList();
      _listKey = ValueKey<int>(_listKey.value + 1);
    });

    // Reset to the first page to ensure a consistent state
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _showCompletionAnimation() {
    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(child: Lottie.asset('images/complete.json', repeat: false, width: 200, height: 200)),
        );
      },
    );
  }

  Future<void> _markWorkoutAsDone(Workout workout) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'completedWorkouts_${_formatDate(DateTime.now())}';
    final completedToday = prefs.getStringList(key) ?? [];

    if (!completedToday.contains(workout.name)) {
      completedToday.add(workout.name);
      await prefs.setStringList(key, completedToday);
      setState(() => _completedWorkoutsToday.add(workout.name));
    }

    if (_activeWorkoutName == workout.name) {
      await prefs.remove('activeWorkoutName');
      await prefs.remove('isTimerRunning');
      await _loadActiveWorkoutState();
    }

    if (mounted) _showCompletionAnimation();
  }

  void _showWorkoutDetailSheet(Workout workout) {
    final Color currentMoodColor = _moodColors[_selectedMood] ?? accentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(workout.name, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: textColor, fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (workout.type == WorkoutType.repBased)
                Center(child: FaIcon(workout.icon, size: 80, color: mutedTextColor)),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(workout.goal, style: GoogleFonts.poppins(color: currentMoodColor, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Text(workout.description, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: textColor.withOpacity(0.7), fontSize: 15, height: 1.5)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  Widget? nextScreen;
                  if (workout.type == WorkoutType.timeBased) {
                    nextScreen = WorkoutTimerDialog(
                      workout: workout,
                      onDone: (cw) => _markWorkoutAsDone(cw),
                      themeColor: currentMoodColor, // Pass the mood color
                    );
                  } else if (workout.type == WorkoutType.repBased) {
                    nextScreen = RepLoggerDialog(workout: workout, onDone: (cw) => _markWorkoutAsDone(cw));
                  } else if (workout.type == WorkoutType.breathing) {
                    nextScreen = BreathingMinigameDialog(workout: workout, onDone: (cw) => _markWorkoutAsDone(cw), themeColor: _moodColors['Calm'] ?? Colors.blue);
                  }

                  if (nextScreen != null) {
                    await showDialog(context: context, barrierDismissible: false, builder: (_) => nextScreen!);
                    await _loadActiveWorkoutState();
                  }
                },
                icon: FaIcon(workout.icon, size: 18),
                label: Text(workout.type == WorkoutType.timeBased ? "Start Timer" : "Log Reps & Sets", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoodSelectionPopup() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.black.withOpacity(0.5), builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildSectionTitle("How do you feel today?"),
          const SizedBox(height: 24),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1, children: [
            _buildMoodCard('Energetic', _moodIcons['Energetic']!, _moodColors['Energetic']!),
            _buildMoodCard('Strong', _moodIcons['Strong']!, _moodColors['Strong']!),
            _buildMoodCard('Calm', _moodIcons['Calm']!, _moodColors['Calm']!),
            _buildMoodCard('Tired', _moodIcons['Tired']!, _moodColors['Tired']!),
          ]),
          const SizedBox(height: 20),
        ])),
      );
    },
    );
  }

  Widget _buildSectionTitle(String title, {bool withIcon = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: textColor, fontSize: 26, fontWeight: FontWeight.w600)),
        if (withIcon) ...[
          const SizedBox(width: 8),
          FaIcon(FontAwesomeIcons.fire, color: _moodColors[_selectedMood] ?? accentColor, size: 24),
        ]
      ],
    );
  }

  Widget _buildMoodCard(String mood, IconData icon, Color color) => GestureDetector(onTap: () => _handleMoodSelection(mood), child: AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color, width: 2), boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [FaIcon(icon, size: 42, color: color), const SizedBox(height: 12), Text(mood, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w500, fontSize: 16))])));

  Widget _buildWorkoutCard(Workout workout, int index) {
    final bool isDone = _completedWorkoutsToday.contains(workout.name);
    final bool isSelected = index == _currentPage;
    final Color currentMoodColor = _moodColors[_selectedMood] ?? accentColor;

    return GestureDetector(
      onTap: () => _showWorkoutDetailSheet(workout),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [cardColor, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: currentMoodColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FaIcon(_moodIcons[_selectedMood]!, color: textColor, size: 36),
                      AnimatedCompletionRing(isCompleted: isDone, color: currentMoodColor),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentMoodColor.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: FaIcon(
                          workout.icon,
                          size: 110,
                          color: currentMoodColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  Text(workout.name, style: GoogleFonts.poppins(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(workout.subtitle, style: GoogleFonts.poppins(color: mutedTextColor, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final Color currentMoodColor = _moodColors[_selectedMood] ?? accentColor;

    return Scaffold(backgroundColor: Colors.transparent, body: Stack(children: [
      ...List.generate(10, (index) => GlowParticle(key: UniqueKey(), color: currentMoodColor)),
      SafeArea(
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _buildSectionTitle("Workouts for a $_selectedMood Day"),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _showMoodSelectionPopup,
                icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 18, color: mutedTextColor),
                label: Text("Change Mood", style: GoogleFonts.poppins(color: mutedTextColor, fontWeight: FontWeight.w500)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(width: 16),
              // --- MODIFIED BUTTON ---
              TextButton.icon(
                onPressed: _shuffleWorkouts,
                icon: const FaIcon(FontAwesomeIcons.shuffle, size: 18, color: mutedTextColor),
                label: Text("Shuffle", style: GoogleFonts.poppins(color: mutedTextColor, fontWeight: FontWeight.w500)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimationLimiter(
              key: _listKey, // Key is now on the AnimationLimiter
              child: PageView.builder(
                controller: _pageController,
                itemCount: _displayedWorkouts.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildWorkoutCard(_displayedWorkouts[index], index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                color: _currentPage == 0 ? mutedTextColor : textColor,
                onPressed: _currentPage == 0
                    ? null
                    : () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowRight),
                color: _currentPage >= _displayedWorkouts.length - 1 ? mutedTextColor : textColor,
                onPressed: _currentPage >= _displayedWorkouts.length - 1
                    ? null
                    : () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
        ])),
      )
    ]));
  }
}

// ... All Dialog Widgets are below ...
class WorkoutTimerDialog extends StatefulWidget {
  final Workout workout;
  final Function(Workout) onDone;
  final Color themeColor;

  const WorkoutTimerDialog({
    super.key,
    required this.workout,
    required this.onDone,
    required this.themeColor,
  });
  @override
  State<WorkoutTimerDialog> createState() => _WorkoutTimerDialogState();
}

class _WorkoutTimerDialogState extends State<WorkoutTimerDialog> with WidgetsBindingObserver {
  Timer? _timer;
  late Duration _duration;
  late Duration _initialDuration;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialDuration = _parseDuration(widget.workout.goal);
    _duration = _initialDuration;
    _loadProgressAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isRunning) _saveProgress();
    }
  }

  String _formatDate(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<void> _loadProgressAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _formatDate(DateTime.now());
    final durationKey = 'timerProgress_${widget.workout.name}_$dateKey';
    final startTimeKey = 'timerStartTime_${widget.workout.name}_$dateKey';
    final runningKey = 'isTimerRunning';

    final savedSeconds = prefs.getInt(durationKey);
    final startTimeString = prefs.getString(startTimeKey);
    final wasRunning = prefs.getBool(runningKey) ?? false;

    if (mounted) {
      Duration newDuration = _initialDuration;
      if (savedSeconds != null) {
        if (wasRunning && startTimeString != null) {
          final startTime = DateTime.parse(startTimeString);
          final elapsed = DateTime.now().difference(startTime);
          final remaining = Duration(seconds: savedSeconds) - elapsed;
          newDuration = remaining.isNegative ? Duration.zero : remaining;
        } else {
          newDuration = Duration(seconds: savedSeconds);
        }
      }
      setState(() {
        _duration = newDuration;
        if (wasRunning && !_duration.isNegative && _duration != Duration.zero) {
          _toggleTimer(start: true);
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _formatDate(DateTime.now());
    final durationKey = 'timerProgress_${widget.workout.name}_$dateKey';
    final startTimeKey = 'timerStartTime_${widget.workout.name}_$dateKey';

    await prefs.setInt(durationKey, _duration.inSeconds);
    await prefs.setBool('isTimerRunning', _isRunning);
    if (_isRunning) {
      await prefs.setString(startTimeKey, DateTime.now().toIso8601String());
    } else {
      await prefs.remove(startTimeKey);
    }
    await prefs.setString('activeWorkoutName', widget.workout.name);
  }

  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _formatDate(DateTime.now());
    await prefs.remove('timerProgress_${widget.workout.name}_$dateKey');
    await prefs.remove('timerStartTime_${widget.workout.name}_$dateKey');
    await prefs.remove('isTimerRunning');
    await prefs.remove('activeWorkoutName');
  }

  Duration _parseDuration(String goal) {
    try {
      final minutes = int.parse(goal.split(' ')[0]);
      return Duration(minutes: minutes);
    } catch (e) {
      return const Duration(minutes: 1);
    }
  }

  void _toggleTimer({bool start = false}) {
    if (_isRunning && !start) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_duration.inSeconds > 0) {
          setState(() => _duration -= const Duration(seconds: 1));
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _clearProgress();
          widget.onDone(widget.workout);
          Navigator.pop(context);
        }
      });
      setState(() => _isRunning = true);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final progress = _initialDuration.inSeconds > 0 ? 1 - (_duration.inSeconds / _initialDuration.inSeconds) : 0.0;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const FaIcon(FontAwesomeIcons.xmark, color: textColor),
                onPressed: () async {
                  _timer?.cancel();
                  await _saveProgress();
                  Navigator.pop(context);
                },
              ),
            ),
            Text(widget.workout.name, style: GoogleFonts.poppins(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              width: 200, height: 200,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(value: 1.0, strokeWidth: 12, color: backgroundColor),
                  CircularProgressIndicator(
                    value: progress.isNaN || progress.isInfinite ? 0 : progress,
                    strokeWidth: 12,
                    color: widget.themeColor, // Use the passed mood color
                    strokeCap: StrokeCap.butt,
                  ),
                  Center(child: Text(_formatDuration(_duration), style: GoogleFonts.poppins(color: textColor, fontSize: 48, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            IconButton(onPressed: _toggleTimer, icon: FaIcon(_isRunning ? FontAwesomeIcons.circlePause : FontAwesomeIcons.circlePlay, color: textColor, size: 60)),
          ],
        ),
      ),
    );
  }
}

class RepLoggerDialog extends StatefulWidget {
  final Workout workout;
  final Function(Workout) onDone;

  const RepLoggerDialog({super.key, required this.workout, required this.onDone});

  @override
  State<RepLoggerDialog> createState() => _RepLoggerDialogState();
}

class _RepLoggerDialogState extends State<RepLoggerDialog> {
  int _targetSets = 0;
  int _completedSets = 0;

  @override
  void initState() {
    super.initState();
    _parseGoal();
    _loadProgressAndInitialize();
  }

  void _parseGoal() {
    try {
      final parts = widget.workout.goal.toLowerCase().split(' sets');
      _targetSets = int.parse(parts[0]);
    } catch (e) {
      _targetSets = 3;
    }
  }

  String _formatDate(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<void> _loadProgressAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'repProgress_${widget.workout.name}_${_formatDate(DateTime.now())}';
    final savedSets = prefs.getInt(key) ?? 0;
    if (mounted) {
      setState(() {
        _completedSets = savedSets;
      });
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'repProgress_${widget.workout.name}_${_formatDate(DateTime.now())}';
    await prefs.setInt(key, _completedSets);
    await prefs.setString('activeWorkoutName', widget.workout.name);
    await prefs.setBool('isTimerRunning', false);
  }

  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'repProgress_${widget.workout.name}_${_formatDate(DateTime.now())}';
    await prefs.remove(key);
    await prefs.remove('activeWorkoutName');
    await prefs.remove('isTimerRunning');
  }

  void _logSet() {
    if (_completedSets < _targetSets) {
      setState(() {
        _completedSets++;
        if (_completedSets >= _targetSets) {
          _clearProgress();
          widget.onDone(widget.workout);
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentSet = _completedSets + 1;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: FaIcon(FontAwesomeIcons.xmark, color: textColor.withOpacity(0.7)),
                onPressed: () async {
                  await _saveProgress();
                  Navigator.pop(context);
                },
              ),
            ),
            Text(widget.workout.name, style: GoogleFonts.poppins(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text("Set $currentSet of $_targetSets", style: GoogleFonts.poppins(color: textColor.withOpacity(0.8), fontSize: 28, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text("Goal: ${widget.workout.goal}", style: GoogleFonts.poppins(color: accentColor, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _logSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Complete Set $currentSet", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class BreathingMinigameDialog extends StatefulWidget {
  final Workout workout;
  final Function(Workout) onDone;
  final Color themeColor;

  const BreathingMinigameDialog({super.key, required this.workout, required this.onDone, required this.themeColor});

  @override
  State<BreathingMinigameDialog> createState() => _BreathingMinigameDialogState();
}

class _BreathingMinigameDialogState extends State<BreathingMinigameDialog> with TickerProviderStateMixin {
  late Timer _mainTimer;
  late Duration _totalDuration;
  late AnimationController _breathingController;

  String _instruction = "Get Ready...";
  double _circleSize = 150.0;
  late Color _animatedColor;

  @override
  void initState() {
    super.initState();
    _animatedColor = widget.themeColor;
    _totalDuration = _parseDuration(widget.workout.goal);

    _mainTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_totalDuration.inSeconds > 0) {
        if (mounted) setState(() => _totalDuration -= const Duration(seconds: 1));
      } else {
        _mainTimer.cancel();
        _breathingController.stop();
        if (mounted) setState(() => _instruction = "Done!");
        widget.onDone(widget.workout);
        Navigator.pop(context);
      }
    });

    _breathingController = AnimationController(vsync: this, duration: const Duration(seconds: 16));
    _breathingController.addListener(() {
      final value = _breathingController.value;
      if (mounted) {
        setState(() {
          if (value < 0.25) {
            _instruction = "Breathe In...";
            _circleSize = 150 + (value * 4 * 100);
            _animatedColor = widget.themeColor;
          } else if (value < 0.5) {
            _instruction = "Hold";
            _circleSize = 250;
            _animatedColor = widget.themeColor;
          } else if (value < 0.75) {
            _instruction = "Breathe Out...";
            _circleSize = 250 - ((value - 0.5) * 4 * 100);
            _animatedColor = widget.themeColor.withOpacity(0.5);
          } else {
            _instruction = "Hold";
            _circleSize = 150;
            _animatedColor = widget.themeColor.withOpacity(0.5);
          }
        });
      }
    });
    _breathingController.repeat();
  }

  Duration _parseDuration(String goal) {
    try {
      final minutes = int.parse(goal.split(' ')[0]);
      return Duration(minutes: minutes);
    } catch (e) {
      return const Duration(minutes: 1);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _mainTimer.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: FaIcon(FontAwesomeIcons.xmark, color: textColor.withOpacity(0.7)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Text(widget.workout.name, style: GoogleFonts.poppins(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              height: 280,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: _circleSize,
                  height: _circleSize,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _animatedColor.withOpacity(0.2),
                      border: Border.all(color: _animatedColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _animatedColor.withOpacity(0.5),
                          blurRadius: 25.0,
                          spreadRadius: 5.0,
                        )
                      ]
                  ),
                  child: Center(
                    child: Text(
                      _instruction,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(_formatDuration(_totalDuration), style: GoogleFonts.poppins(color: textColor, fontSize: 32, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class AnimatedCompletionRing extends StatefulWidget {
  final bool isCompleted;
  final Color color;
  const AnimatedCompletionRing({super.key, required this.isCompleted, required this.color});

  @override
  State<AnimatedCompletionRing> createState() => _AnimatedCompletionRingState();
}

class _AnimatedCompletionRingState extends State<AnimatedCompletionRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.isCompleted) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCompletionRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: _CompletionRingPainter(progress: _animation.value, color: widget.color),
          ),
        );
      },
    );
  }
}

class _CompletionRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CompletionRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = mutedTextColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.butt
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.3), color],
        startAngle: -pi / 2,
        endAngle: 2 * pi,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    if (progress > 0.99) {
      final tickPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

      final path = Path();
      path.moveTo(center.dx - radius * 0.4, center.dy);
      path.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.3);
      path.lineTo(center.dx + radius * 0.4, center.dy - radius * 0.3);

      canvas.drawPath(path, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}

class GlowParticle extends StatefulWidget {
  final Color color;
  const GlowParticle({super.key, required this.color});

  @override
  State<GlowParticle> createState() => _GlowParticleState();
}

class _GlowParticleState extends State<GlowParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double x, y, size, opacity;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _resetParticle();
    _controller = AnimationController(
      duration: Duration(seconds: _random.nextInt(5) + 5),
      vsync: this,
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _resetParticle();
          _controller.forward(from: 0);
        }
      });

    Future.delayed(Duration(milliseconds: _random.nextInt(5000)), () {
      if(mounted) {
        _controller.forward();
      }
    });
  }

  void _resetParticle() {
    x = _random.nextDouble();
    y = 1.1;
    size = _random.nextDouble() * 4 + 1;
    opacity = _random.nextDouble() * 0.3 + 0.1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double currentY = y - (_controller.value * 1.2);
    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: currentY * MediaQuery.of(context).size.height,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(opacity * 0.5),
              blurRadius: size * 2,
              spreadRadius: size,
            ),
          ],
        ),
      ),
    );
  }
}