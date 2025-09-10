import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Consistent styling copied from goals_screen.dart
const Color accentColor = Color(0xFFD32F2F);
const Color backgroundColor = Color(0xFF1A1A1A);
const Color cardColor = Color(0xFF242424);
const Color textColor = Color(0xFFE0E0E0);

// --- Data Models for Workouts ---
enum WorkoutType { timeBased, repBased, breathing }

class Workout {
  final String name;
  final String description;
  final String goal;
  final WorkoutType type;
  final IconData icon;

  Workout({
    required this.name,
    required this.description,
    required this.goal,
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

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  // Data structure now uses the Workout class
  final Map<String, List<Workout>> _workoutsByMood = {
    'Energetic': [
      Workout(name: 'HIIT', description: 'High-intensity interval training.', goal: '20 minutes', type: WorkoutType.timeBased, icon: Icons.whatshot),
      Workout(name: 'Running', description: 'Cardiovascular exercise for endurance.', goal: '30 minutes', type: WorkoutType.timeBased, icon: Icons.directions_run),
      Workout(name: 'Jump Rope', description: 'Full-body workout for coordination.', goal: '15 minutes', type: WorkoutType.timeBased, icon: Icons.height),
      Workout(name: 'Burpees', description: 'A full-body strength and aerobic exercise.', goal: '3 sets of 10', type: WorkoutType.repBased, icon: Icons.fitness_center),
      Workout(name: 'Mountain Climbers', description: 'A dynamic exercise for core strength.', goal: '3 sets of 45s', type: WorkoutType.timeBased, icon: Icons.landscape),
      Workout(name: 'High Knees', description: 'An intense cardio exercise.', goal: '3 sets of 45s', type: WorkoutType.timeBased, icon: Icons.sports_kabaddi),
      Workout(name: 'Cycling', description: 'Low-impact cardio for leg strength.', goal: '45 minutes', type: WorkoutType.timeBased, icon: Icons.directions_bike),
      Workout(name: 'Boxing Drills', description: 'Improves speed, power, and cardio.', goal: '20 minutes', type: WorkoutType.timeBased, icon: Icons.sports_mma),
      Workout(name: 'Kettlebell Swings', description: 'Builds power in the posterior chain.', goal: '4 sets of 15', type: WorkoutType.repBased, icon: Icons.anchor),
      Workout(name: 'Battle Ropes', description: 'A high-intensity upper body workout.', goal: '5 sets of 30s', type: WorkoutType.timeBased, icon: Icons.waves),
      Workout(name: 'Plyo Jumps', description: 'Explosive jumps to build power.', goal: '3 sets of 12', type: WorkoutType.repBased, icon: Icons.arrow_upward),
      Workout(name: 'Stair Sprints', description: 'A challenging cardio workout.', goal: '10 minutes', type: WorkoutType.timeBased, icon: Icons.show_chart),
      Workout(name: 'Dance Cardio', description: 'A fun way to get your heart rate up.', goal: '30 minutes', type: WorkoutType.timeBased, icon: Icons.music_note),
      Workout(name: 'Rowing', description: 'A full-body workout for strength and cardio.', goal: '20 minutes', type: WorkoutType.timeBased, icon: Icons.rowing),
      Workout(name: 'Jumping Jacks', description: 'A classic warm-up and cardio exercise.', goal: '3 sets of 50', type: WorkoutType.repBased, icon: Icons.star),
    ],
    'Tired': [
      Workout(name: 'Gentle Stretching', description: 'Increase flexibility and relieve tension.', goal: '15 minutes', type: WorkoutType.timeBased, icon: Icons.accessibility_new),
      Workout(name: 'Light Yoga', description: 'Poses and breathing to relax the body.', goal: '20 minutes', type: WorkoutType.timeBased, icon: Icons.spa),
      Workout(name: 'Mindful Walking', description: 'Low-impact exercise to clear your head.', goal: '30 minutes', type: WorkoutType.timeBased, icon: Icons.directions_walk),
      Workout(name: 'Foam Rolling', description: 'Myofascial release to soothe sore muscles.', goal: '10 minutes', type: WorkoutType.timeBased, icon: Icons.healing),
      Workout(name: 'Tai Chi', description: 'A gentle martial art for balance and calm.', goal: '20 minutes', type: WorkoutType.timeBased, icon: Icons.self_improvement),
      Workout(name: 'Child\'s Pose', description: 'A resting pose to stretch the back.', goal: '5 minutes', type: WorkoutType.timeBased, icon: Icons.airline_seat_recline_normal),
      Workout(name: 'Cat-Cow Stretch', description: 'Warms up the spine and relieves back pain.', goal: '3 sets of 10', type: WorkoutType.repBased, icon: Icons.pets),
      Workout(name: 'Seated Forward Bend', description: 'Stretches hamstrings and lower back.', goal: '3 sets of 30s', type: WorkoutType.timeBased, icon: Icons.airline_seat_legroom_reduced),
      Workout(name: 'Leg Swings', description: 'Dynamic stretch for hip mobility.', goal: '2 sets of 15', type: WorkoutType.repBased, icon: Icons.swap_horiz),
      Workout(name: 'Arm Circles', description: 'Warms up the shoulder joints.', goal: '2 sets of 15', type: WorkoutType.repBased, icon: Icons.track_changes),
      Workout(name: 'Neck Rolls', description: 'Relieves tension in the neck and shoulders.', goal: '10 rolls', type: WorkoutType.repBased, icon: Icons.psychology_alt),
      Workout(name: 'Deep Breathing', description: 'Calms the nervous system.', goal: '5 minutes', type: WorkoutType.breathing, icon: Icons.air),
      Workout(name: 'Ankle Rotations', description: 'Improves ankle mobility.', goal: '15 rotations', type: WorkoutType.repBased, icon: Icons.rotate_right),
      Workout(name: 'Wrist Stretches', description: 'Prevents strain from typing or lifting.', goal: '3 sets of 30s', type: WorkoutType.timeBased, icon: Icons.front_hand),
      Workout(name: 'Gentle Twists', description: 'Improves spinal mobility.', goal: '3 sets of 30s', type: WorkoutType.timeBased, icon: Icons.rotate_90_degrees_ccw),
    ],
    'Strong': [
      Workout(name: 'Pushups', description: 'Classic bodyweight chest exercise.', goal: '3 sets of 12', type: WorkoutType.repBased, icon: Icons.arrow_upward),
      Workout(name: 'Squats', description: 'Fundamental lower body exercise.', goal: '3 sets of 15', type: WorkoutType.repBased, icon: Icons.airline_seat_legroom_normal),
      Workout(name: 'Weightlifting', description: 'Build muscle with weights.', goal: '45 minutes', type: WorkoutType.timeBased, icon: Icons.fitness_center),
      Workout(name: 'Pull-ups', description: 'Builds back and bicep strength.', goal: '3 sets to failure', type: WorkoutType.repBased, icon: Icons.arrow_upward),
      Workout(name: 'Lunges', description: 'Strengthens legs and glutes individually.', goal: '3 sets of 12', type: WorkoutType.repBased, icon: Icons.directions_walk),
      Workout(name: 'Plank', description: 'A core stability and strength exercise.', goal: '3 sets of 60s', type: WorkoutType.timeBased, icon: Icons.horizontal_rule),
      Workout(name: 'Deadlifts', description: 'A full-body compound lift.', goal: '4 sets of 8', type: WorkoutType.repBased, icon: Icons.line_weight),
      Workout(name: 'Bench Press', description: 'Builds chest, shoulder, and tricep strength.', goal: '4 sets of 10', type: WorkoutType.repBased, icon: Icons.horizontal_rule),
      Workout(name: 'Overhead Press', description: 'Develops shoulder and upper body strength.', goal: '4 sets of 10', type: WorkoutType.repBased, icon: Icons.arrow_upward),
      Workout(name: 'Bicep Curls', description: 'Isolation exercise for the biceps.', goal: '3 sets of 12', type: WorkoutType.repBased, icon: Icons.sports_kabaddi),
      Workout(name: 'Tricep Dips', description: 'Uses bodyweight to target the triceps.', goal: '3 sets of 15', type: WorkoutType.repBased, icon: Icons.arrow_downward),
      Workout(name: 'Crunches', description: 'Targets the abdominal muscles.', goal: '3 sets of 20', type: WorkoutType.repBased, icon: Icons.hdr_strong),
      Workout(name: 'Leg Raises', description: 'Focuses on the lower abdominal muscles.', goal: '3 sets of 15', type: WorkoutType.repBased, icon: Icons.reorder),
      Workout(name: 'Glute Bridges', description: 'Activates and strengthens the glutes.', goal: '3 sets of 20', type: WorkoutType.repBased, icon: Icons.arrow_upward),
      Workout(name: 'Russian Twists', description: 'A core exercise for the obliques.', goal: '3 sets of 20', type: WorkoutType.repBased, icon: Icons.sync_alt),
    ],
    'Calm': [
      Workout(name: 'Box Breathing', description: 'A technique to calm the nervous system.', goal: '5 minutes', type: WorkoutType.breathing, icon: Icons.air),
      Workout(name: 'Meditation', description: 'Train attention for mental clarity.', goal: '15 minutes', type: WorkoutType.timeBased, icon: Icons.psychology),
      Workout(name: 'Balance Work', description: 'Exercises to improve stability.', goal: '10 minutes', type: WorkoutType.timeBased, icon: Icons.balance),
      Workout(name: 'Body Scan', description: 'A mindfulness meditation practice.', goal: '10 minutes', type: WorkoutType.timeBased, icon: Icons.person_search),
      Workout(name: 'Guided Imagery', description: 'Use your imagination to relax.', goal: '15 minutes', type: WorkoutType.timeBased, icon: Icons.landscape),
      Workout(name: 'Yin Yoga', description: 'Slow-paced style with long-held poses.', goal: '30 minutes', type: WorkoutType.timeBased, icon: Icons.spa),
      Workout(name: 'Restorative Poses', description: 'Gentle poses for deep relaxation.', goal: '20 minutes', type: WorkoutType.timeBased, icon: Icons.hotel),
      Workout(name: 'Seated Meditation', description: 'The classic mindfulness practice.', goal: '10 minutes', type: WorkoutType.timeBased, icon: Icons.self_improvement),
      Workout(name: 'Walking Meditation', description: 'Focus on the act of walking.', goal: '15 minutes', type: WorkoutType.timeBased, icon: Icons.directions_walk),
      Workout(name: 'Listening Meditation', description: 'Focus on sounds around you.', goal: '10 minutes', type: WorkoutType.timeBased, icon: Icons.hearing),
      Workout(name: 'Gratitude Journaling', description: 'Focus on positive aspects of your life.', goal: '5 minutes', type: WorkoutType.timeBased, icon: Icons.book),
      Workout(name: 'Mindful Tea Drinking', description: 'Focus senses on the act of drinking tea.', goal: '5 minutes', type: WorkoutType.timeBased, icon: Icons.emoji_food_beverage),
      Workout(name: 'Nature Observation', description: 'Sit and observe nature mindfully.', goal: '15 minutes', type: WorkoutType.timeBased, icon: Icons.nature_people),
      Workout(name: 'Affirmation Repetition', description: 'Repeat positive phrases to yourself.', goal: '5 minutes', type: WorkoutType.timeBased, icon: Icons.record_voice_over),
      Workout(name: 'Savasana', description: 'The final relaxation pose in yoga.', goal: '10 minutes', type: WorkoutType.timeBased, icon: Icons.airline_seat_flat),
    ],
  };

  final Map<String, IconData> _moodIcons = {
    'Energetic': Icons.bolt,
    'Strong': Icons.fitness_center,
    'Calm': Icons.self_improvement,
    'Tired': Icons.battery_saver,
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

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _checkAndShowMoodPopup();
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
    });
  }

  void _shuffleWorkouts() {
    final fullList = List<Workout>.from(_fullWorkoutList);
    fullList.shuffle();
    setState(() {
      _displayedWorkouts = fullList.take(5).toList();
    });
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
          child: Center(child: Lottie.asset('assets/complete.json', repeat: false, width: 200, height: 200)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String buttonText;
        IconData buttonIcon;
        switch (workout.type) {
          case WorkoutType.timeBased:
            buttonText = "Start Timer";
            buttonIcon = Icons.timer_outlined;
            break;
          case WorkoutType.repBased:
            buttonText = "Log Reps & Sets";
            buttonIcon = Icons.format_list_numbered;
            break;
          case WorkoutType.breathing:
            buttonText = "Begin Exercise";
            buttonIcon = Icons.air;
            break;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(workout.name, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: textColor, fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (workout.type == WorkoutType.repBased) Icon(workout.icon, size: 80, color: cardColor.withOpacity(0.5)),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(workout.goal, style: GoogleFonts.poppins(color: _moodColors[_selectedMood] ?? accentColor, fontSize: 16, fontWeight: FontWeight.bold)),
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
                    nextScreen = WorkoutTimerDialog(workout: workout, onDone: (cw) => _markWorkoutAsDone(cw));
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
                icon: Icon(buttonIcon),
                label: Text(buttonText, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showMoodSelectionPopup() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: backgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) {
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildSectionTitle("How do you feel today?"),
        const SizedBox(height: 24),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1, children: [
          _buildMoodCard('Energetic', _moodIcons['Energetic']!, _moodColors['Energetic']!),
          _buildMoodCard('Strong', _moodIcons['Strong']!, _moodColors['Strong']!),
          _buildMoodCard('Calm', _moodIcons['Calm']!, _moodColors['Calm']!),
          _buildMoodCard('Tired', _moodIcons['Tired']!, _moodColors['Tired']!),
        ]),
        const SizedBox(height: 20),
      ]));
    },
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: textColor, fontSize: 26, fontWeight: FontWeight.w600));

  Widget _buildMoodCard(String mood, IconData icon, Color color) => GestureDetector(onTap: () => _handleMoodSelection(mood), child: AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: color, width: 2), boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 42, color: color), const SizedBox(height: 12), Text(mood, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w500, fontSize: 16))])));

  Widget _buildWorkoutCard(Workout workout) {
    final bool isDone = _completedWorkoutsToday.contains(workout.name);
    final bool hasActiveTimer = workout.name == _activeWorkoutName;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1), width: 1)),
      child: ListTile(
        onTap: () async {
          if (hasActiveTimer) {
            Widget? nextScreen;
            if (workout.type == WorkoutType.timeBased) {
              nextScreen = WorkoutTimerDialog(workout: workout, onDone: (cw) => _markWorkoutAsDone(cw));
            } else if (workout.type == WorkoutType.repBased){
              nextScreen = RepLoggerDialog(workout: workout, onDone: (cw) => _markWorkoutAsDone(cw));
            } else {
              nextScreen = BreathingMinigameDialog(workout: workout, onDone: (cw) => _markWorkoutAsDone(cw), themeColor: _moodColors['Calm'] ?? Colors.blue);
            }
            await showDialog(context: context, barrierDismissible: false, builder: (_) => nextScreen!);
            await _loadActiveWorkoutState();
          } else {
            _showWorkoutDetailSheet(workout);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(workout.icon, color: accentColor.withOpacity(0.8)),
        title: Text(workout.name, style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: hasActiveTimer ? Text(_isTimerRunningInBackground ? "Running..." : "Paused", style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 12)) : null,
        trailing: isDone ? Icon(Icons.check_circle_outline, color: accentColor.withOpacity(0.7), size: 24) : (hasActiveTimer ? const Icon(Icons.timelapse, color: Colors.orangeAccent) : Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5))),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    final IconData? icon = _moodIcons[_selectedMood];
    final Color? glowColor = _moodColors[_selectedMood];
    if (icon == null || glowColor == null) return const SizedBox.shrink();
    return Center(child: Transform.translate(offset: const Offset(0, -40), child: Text(String.fromCharCode(icon.codePoint), style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 300, color: Colors.white.withOpacity(0.04), shadows: [Shadow(color: glowColor.withOpacity(0.3), blurRadius: 50.0)]))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.transparent, body: Stack(children: [
    _buildBackgroundDecoration(),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildSectionTitle("Workouts for a\n$_selectedMood Day"),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _showMoodSelectionPopup,
              icon: Icon(Icons.sync, size: 20, color: textColor.withOpacity(0.7)),
              label: Text("Change Mood", style: GoogleFonts.poppins(color: textColor.withOpacity(0.7), fontWeight: FontWeight.w500)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
            IconButton(onPressed: _shuffleWorkouts, icon: const Icon(Icons.shuffle), iconSize: 28, color: textColor.withOpacity(0.7), tooltip: "Shuffle Workouts"),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 0, bottom: 16),
            itemCount: _displayedWorkouts.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildWorkoutCard(_displayedWorkouts[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ])),
  ]));
}

class WorkoutTimerDialog extends StatefulWidget {
  final Workout workout;
  final Function(Workout) onDone;
  const WorkoutTimerDialog({super.key, required this.workout, required this.onDone});
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
    final bool isTimerFinished = _duration.inSeconds == 0;

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
                icon: Icon(Icons.close, color: textColor.withOpacity(0.7)),
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
                  CircularProgressIndicator(value: progress.isNaN || progress.isInfinite ? 0 : progress, strokeWidth: 12, color: accentColor, strokeCap: StrokeCap.round),
                  Center(child: Text(_formatDuration(_duration), style: GoogleFonts.poppins(color: textColor, fontSize: 48, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isTimerFinished)
              IconButton(onPressed: _toggleTimer, icon: Icon(_isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled, color: textColor, size: 60)),
            if (isTimerFinished)
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isTimerFinished ? () async {
                await _clearProgress();
                widget.onDone(widget.workout);
                Navigator.pop(context);
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: accentColor.withOpacity(0.8), foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.withOpacity(0.2), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text("Finish Workout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinished = _completedSets >= _targetSets;
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
                icon: Icon(Icons.close, color: textColor.withOpacity(0.7)),
                onPressed: () async {
                  await _saveProgress();
                  Navigator.pop(context);
                },
              ),
            ),
            Text(widget.workout.name, style: GoogleFonts.poppins(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (!isFinished)
              Text("Set $currentSet of $_targetSets", style: GoogleFonts.poppins(color: textColor.withOpacity(0.8), fontSize: 28, fontWeight: FontWeight.w600)),
            if (isFinished)
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
            const SizedBox(height: 16),
            Text("Goal: ${widget.workout.goal}", style: GoogleFonts.poppins(color: accentColor, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isFinished ? () async {
                await _clearProgress();
                widget.onDone(widget.workout);
                Navigator.pop(context);
              } : _logSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isFinished ? "Finish Workout" : "Complete Set $currentSet", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
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
      }
    });

    _breathingController = AnimationController(vsync: this, duration: const Duration(seconds: 16));
    _breathingController.addListener(() {
      final value = _breathingController.value;
      if (mounted) {
        setState(() {
          if (value < 0.25) { // Inhale
            _instruction = "Breathe In...";
            _circleSize = 150 + (value * 4 * 100);
            _animatedColor = widget.themeColor;
          } else if (value < 0.5) { // Hold Full
            _instruction = "Hold";
            _circleSize = 250;
            _animatedColor = widget.themeColor;
          } else if (value < 0.75) { // Exhale
            _instruction = "Breathe Out...";
            _circleSize = 250 - ((value - 0.5) * 4 * 100);
            _animatedColor = widget.themeColor.withOpacity(0.5);
          } else { // Hold Empty
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
    bool isFinished = _totalDuration.inSeconds == 0;
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
                icon: Icon(Icons.close, color: textColor.withOpacity(0.7)),
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
            ElevatedButton(
              onPressed: isFinished ? () {
                widget.onDone(widget.workout);
                Navigator.pop(context);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withOpacity(0.8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Finish", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}