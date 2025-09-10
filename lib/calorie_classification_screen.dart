import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bmi_screen.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

const int kDailyCalorieGoal = 2000;

// Color scheme
const Color primaryColor = Color(0xFF2C2C2C); // Dark grey
const Color secondaryColor = Color(0xFF8B0000); // Dark red
const Color accentColor = Color(0xFFD32F2F); // Lighter red for accents
const Color backgroundColor = Color(0xFF1A1A1A); // Almost black
const Color textColor = Color(0xFFE0E0E0); // Light grey text
const Color cardColor = Color(0xFF242424); // Slightly lighter dark for cards

class CalorieClassificationScreen extends StatefulWidget {
  final int calorieGoal;
  final String usdaApiKey;
  final VoidCallback? onNeedGoal;
  final Function(int)? onGoalUpdated;

  const CalorieClassificationScreen({
    super.key,
    required this.calorieGoal,
    required this.usdaApiKey,
    this.onNeedGoal,
    this.onGoalUpdated,
  });

  @override
  State<CalorieClassificationScreen> createState() => _CalorieClassificationScreenState();
}

class _CalorieClassificationScreenState extends State<CalorieClassificationScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final Map<String, TextEditingController> _foodNameControllers = {
    'Breakfast': TextEditingController(),
    'Lunch': TextEditingController(),
    'Dinner': TextEditingController(),
    'Snack': TextEditingController(),
  };
  int _totalCalories = 0;
  final List<Map<String, dynamic>> _entries = [];
  final List<Map<String, dynamic>> _removedEntries = [];
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String _currentSearchMealType = 'Breakfast';
  bool _bmiShown = false;
  bool _isShowingBmi = false;
  String _selectedServingSize = 'Standard';
  int _quantity = 1;

  // NEW: State to track if the user has ever set a goal
  bool _hasSetGoal = false;

  int _currentCalorieGoal = 2000;

  DateTime _selectedDate = DateTime.now();
  final Map<String, List<Map<String, dynamic>>> _diaryEntries = {};
  final Map<String, int> _diaryCalories = {};

  late PageController _pageController;
  double _currentPageValue = 0.0;
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _streakAnimationController;

  final Map<String, double> _servingSizes = {
    'Small': 0.7,
    'Standard': 1.0,
    'Large': 1.5,
    'Extra Large': 2.0,
  };

  final Map<String, int> _localFoodDatabase = {
    'apple': 95,
    'banana': 105,
    'potato': 163,
    'rice': 204,
    'chicken breast': 165,
    'egg': 78,
    'salad': 100,
    'bread slice': 79,
    'orange': 62,
    'beef steak': 250,
    'glass of milk': 122,
    'avocado': 234,
  };


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController(viewportFraction: 0.75);
    _pageController.addListener(() {
      if (mounted) setState(() => _currentPageValue = _pageController.page!);
    });

    _progressAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _streakAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeOut));

    _loadAllData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadCalorieGoal();
      _checkIfGoalIsSet(); // Also re-check goal status
    }
  }

  @override
  void didUpdateWidget(CalorieClassificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progressAnimationController.forward(from: 0);
  }

  Future<void> _loadAllData() async {
    await _checkIfGoalIsSet();
    await _loadCalorieGoal();
    await _loadSavedData();
    await _checkBmiStatus();
    _progressAnimationController.forward();
  }

  // NEW: Checks SharedPreferences to see if a goal has been saved
  Future<void> _checkIfGoalIsSet() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasSetGoal = prefs.containsKey('user_goal');
      });
    }
  }

  Future<void> _loadCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentCalorieGoal = prefs.getInt('finalCalorieGoal') ?? widget.calorieGoal;
      });
      _progressAnimationController.forward(from: 0.0);
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? diaryJson = prefs.getString('foodDiary');

      if (diaryJson != null) {
        final Map<String, dynamic> decodedData = json.decode(diaryJson);
        if (mounted) {
          setState(() {
            _diaryEntries.clear();
            _diaryCalories.clear();

            final Map<String, dynamic> diaryEntriesMap = decodedData['diaryEntries'] ?? {};
            diaryEntriesMap.forEach((key, value) => _diaryEntries[key] = List<Map<String, dynamic>>.from(value));

            final Map<String, dynamic> diaryCaloriesMap = decodedData['diaryCalories'] ?? {};
            diaryCaloriesMap.forEach((key, value) => _diaryCalories[key] = value as int);
          });
        }
      }
      _loadDateData();
    } catch (e) {
      print('Error loading saved data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('foodEntries');
      await prefs.remove('totalCalories');

      final String diaryJson = json.encode({'diaryEntries': _diaryEntries, 'diaryCalories': _diaryCalories});
      await prefs.setString('foodDiary', diaryJson);
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _checkBmiStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasSeenBmi = prefs.getBool('hasSeenBmi') ?? false;

      if (!hasSeenBmi && !_isShowingBmi) {
        _isShowingBmi = true;
        Future.delayed(Duration.zero, () {
          if (mounted && !_bmiShown) _showBmiScreen();
        });
      }
    } catch (e) {
      print('Error checking BMI status: $e');
    }
  }

  void _showBmiScreen() {
    if (_bmiShown) return;
    _bmiShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: BMIScreen(
            onCalorieGoalSet: (newGoal) async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasSeenBmi', true);
                await prefs.setInt('finalCalorieGoal', newGoal);
                await Future.delayed(const Duration(milliseconds: 300));

                if (mounted) Navigator.of(context).pop();
                _isShowingBmi = false;

                _loadCalorieGoal();
                widget.onGoalUpdated?.call(newGoal);
              } catch (e) {
                print('Error saving preference: $e');
                _isShowingBmi = false;
              }
            },
          ),
        ),
      ),
    ).then((_) => _isShowingBmi = false);
  }

  String _classifyFood(int calories) {
    if (calories <= 50) return "Feather Bite";
    if (calories <= 150) return "Light Snack";
    if (calories <= 300) return "Smart Choice";
    if (calories <= 500) return "Solid Meal";
    if (calories <= 700) return "Hearty Plate";
    if (calories <= 1000) return "Calorie Bomb";
    return "Mega Feast";
  }

  String _getQualitativeFeedback() {
    if (_currentCalorieGoal == 0) return "Set a goal to get started!";
    final double progress = _totalCalories / _currentCalorieGoal;
    if (progress <= 0.0) return "Empty Tank";
    if (progress < 0.4) return "Warm-Up Phase";
    if (progress < 0.75) return "Cruising Strong";
    if (progress < 1.0) return "Final Push";
    if (progress <= 1.1) return "Perfect Hit!";
    return "Overshot Gains";
  }

  Future<void> _searchUSDAFood(String query, String mealType, {VoidCallback? onStateChanged}) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults.clear();
      _currentSearchMealType = mealType;
    });
    onStateChanged?.call();

    try {
      final response = await http.get(Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search?query=$query&api_key=${widget.usdaApiKey}&pageSize=10'));
      if (!mounted) return;

      List<Map<String, dynamic>> finalResults = [];
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> foods = data['foods'] ?? [];

        for (final food in foods) {
          final calories = _extractCalories(food['foodNutrients'] ?? []);
          if (calories > 0) {
            finalResults.add({'name': food['description'] ?? 'Unknown Food', 'calories': calories, 'classification': _classifyFood(calories), 'dataType': 'USDA'});
          }
        }
        if (finalResults.isEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No nutritional data found for "$query"')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API Error: ${response.statusCode}')));
      }

      setState(() {
        _searchResults = finalResults;
        _isSearching = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
        setState(() => _isSearching = false);
      }
    } finally {
      if (mounted) onStateChanged?.call();
    }
  }

  int _extractCalories(List<dynamic> nutrients) {
    try {
      final calorieNutrient = nutrients.firstWhere((n) => n['nutrientId'] == 1008 || n['nutrientNumber'] == '208', orElse: () => null);
      return calorieNutrient != null ? (calorieNutrient['value'] ?? 0).round() : 0;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, dynamic>?> _showServingSizeDialog(Map<String, dynamic> foodItem) {
    _quantity = 1;
    _selectedServingSize = 'Standard';

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Serving for: ${foodItem['name']}", style: GoogleFonts.poppins(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                ..._servingSizes.entries.map((size) => RadioListTile<String>(title: Text(size.key, style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500)), value: size.key, groupValue: _selectedServingSize, onChanged: (value) => setState(() => _selectedServingSize = value!), activeColor: accentColor)).toList(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: Icon(Icons.remove_circle_outline, color: textColor), onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null)),
                    Text(_quantity.toString(), style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(icon: Icon(Icons.add_circle_outline, color: textColor), onPressed: () => setState(() => _quantity++)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final multiplier = _servingSizes[_selectedServingSize]!;
                    final baseCalories = (foodItem['calories'] * multiplier).round();
                    final totalCalories = baseCalories * _quantity;
                    final newFoodEntry = {'calories': totalCalories, 'name': foodItem['name'], 'classification': _classifyFood(totalCalories), 'mealType': _currentSearchMealType, 'timestamp': DateTime.now().millisecondsSinceEpoch, 'source': 'USDA', 'servingSize': _selectedServingSize, 'quantity': _quantity, 'baseCalories': baseCalories};
                    Navigator.pop(context, newFoodEntry);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white),
                  child: const Text('Add Food'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addFood(Map<String, dynamic> foodEntry) {
    setState(() {
      _totalCalories += foodEntry['calories'] as int;
      _entries.add(foodEntry);

      final String dateKey = _getDateKey(_selectedDate);
      if (!_diaryEntries.containsKey(dateKey)) {
        _diaryEntries[dateKey] = [];
        _diaryCalories[dateKey] = 0;
      }
      _diaryEntries[dateKey]!.add(foodEntry);
      _diaryCalories[dateKey] = _diaryCalories[dateKey]! + foodEntry['calories'] as int;

      _removedEntries.clear();
      _searchResults.clear();
      _foodNameControllers[_currentSearchMealType]?.clear();
    });
    _saveData();
  }

  void _addFoodFromLocal(String mealType, {VoidCallback? onStateChanged}) {
    final controller = _foodNameControllers[mealType]!;
    final foodName = controller.text.trim().toLowerCase();
    if (foodName.isEmpty) return;

    final calories = _localFoodDatabase[foodName];
    if (calories == null) {
      _searchUSDAFood(foodName, mealType, onStateChanged: onStateChanged);
      return;
    }
    _addFood({'calories': calories, 'name': controller.text.trim(), 'classification': _classifyFood(calories), 'mealType': mealType, 'timestamp': DateTime.now().millisecondsSinceEpoch, 'source': 'Local', 'servingSize': 'Standard', 'quantity': 1, 'baseCalories': calories});
    onStateChanged?.call();
  }

  void _removeFood(int index) {
    if (index >= 0 && index < _entries.length) {
      setState(() {
        final removed = _entries.removeAt(index);
        _removedEntries.add(removed);
        _totalCalories -= removed['calories'] as int;

        final String dateKey = _getDateKey(_selectedDate);
        if (_diaryEntries.containsKey(dateKey)) {
          _diaryEntries[dateKey]!.removeWhere((entry) => entry['timestamp'] == removed['timestamp']);
          _diaryCalories[dateKey] = _diaryCalories[dateKey]! - removed['calories'] as int;
          if (_diaryEntries[dateKey]!.isEmpty) {
            _diaryEntries.remove(dateKey);
            _diaryCalories.remove(dateKey);
          }
        }
      });
      _saveData();
    }
  }

  String _getDateKey(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loadDateData();
    });
  }

  void _loadDateData() {
    final String dateKey = _getDateKey(_selectedDate);
    setState(() {
      _entries.clear();
      _totalCalories = 0;
      if (_diaryEntries.containsKey(dateKey)) {
        _entries.addAll(_diaryEntries[dateKey]!);
        _totalCalories = _diaryCalories[dateKey] ?? 0;
      }
      _entries.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    });
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: accentColor, onPrimary: Colors.white, surface: primaryColor, onSurface: textColor), dialogBackgroundColor: backgroundColor), child: child!));
    if (picked != null && picked != _selectedDate) setState(() { _selectedDate = picked; _loadDateData(); });
  }

  List<Map<String, dynamic>> _getEntriesByMealType(String mealType) => _entries.where((entry) => entry['mealType'] == mealType).toList();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foodNameControllers.values.forEach((controller) => controller.dispose());
    _progressAnimationController.dispose();
    _streakAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // NEW: Function to handle navigation to the Goals screen
  void _navigateToGoalsScreen() async {
    await Navigator.pushNamed(context, '/goals');
    // After returning, reload data to reflect any changes
    _loadCalorieGoal();
    _checkIfGoalIsSet();
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month && _selectedDate.day == DateTime.now().day;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20), onPressed: () => _changeDate(-1)),
                  TextButton(onPressed: _showDatePicker, child: Text(isToday ? "Today" : "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w600))),
                  IconButton(icon: Icon(Icons.arrow_forward_ios, color: textColor, size: 20), onPressed: isToday ? null : () => _changeDate(1)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildTopSummarySection(),
            const SizedBox(height: 8),
            _buildMealCarouselWithNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 3), FlSpot(2.6, 2), FlSpot(4.9, 5), FlSpot(6.8, 3.1), FlSpot(8, 4), FlSpot(9.5, 3), FlSpot(11, 4)],
            isCurved: true,
            color: accentColor.withOpacity(0.3),
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [accentColor.withOpacity(0.15), accentColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }

  // MODIFIED: Added the new "Set/Change Goals" button
  Widget _buildTopSummarySection() {
    final goal = _currentCalorieGoal > 0 ? _currentCalorieGoal.toDouble() : 2000.0;
    final consumed = _totalCalories.toDouble();
    final remaining = (goal - consumed).clamp(0, goal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackgroundLineChart(),
                Center(
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) => PieChart(
                        PieChartData(startDegreeOffset: -90, sectionsSpace: 0, centerSpaceRadius: 35, sections: [
                          PieChartSectionData(value: consumed * _progressAnimation.value, color: accentColor, radius: 10, showTitle: false),
                          PieChartSectionData(value: remaining + (goal - (consumed * _progressAnimation.value)), color: Colors.grey.shade800, radius: 10, showTitle: false),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(_getQualitativeFeedback(), style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          // --- NEW BUTTON ---
          TextButton.icon(
            onPressed: _navigateToGoalsScreen,
            icon: Icon(_hasSetGoal ? Icons.edit_note : Icons.flag_outlined, color: textColor.withOpacity(0.7), size: 20),
            label: Text(
                _hasSetGoal ? "Change Goals" : "Set a Goal",
                style: GoogleFonts.poppins(color: textColor.withOpacity(0.7), fontWeight: FontWeight.w500)
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: cardColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCarouselWithNavigation() {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildMealCarousel(),
          Positioned(
            left: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _currentPageValue > 0.1 ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !(_currentPageValue > 0.1),
                child: IconButton(icon: const Icon(Icons.arrow_circle_left_rounded, color: textColor, size: 35), onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic)),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _currentPageValue < _mealTypes.length - 1.1 ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !(_currentPageValue < _mealTypes.length - 1.1),
                child: IconButton(icon: const Icon(Icons.arrow_circle_right_rounded, color: textColor, size: 35), onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCarousel() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _mealTypes.length,
      itemBuilder: (context, index) {
        final mealType = _mealTypes[index];
        double scale = 1.0;
        if (_pageController.position.haveDimensions) {
          scale = (_currentPageValue - index).abs();
          scale = (1 - (scale * 0.2)).clamp(0.8, 1.0);
        }
        return Transform.scale(scale: scale, child: _buildCarouselMealCard(mealType));
      },
    );
  }

  Widget _buildCarouselMealCard(String mealType) {
    final mealEntries = _getEntriesByMealType(mealType);
    final totalMealCalories = mealEntries.fold(0, (sum, entry) => sum + (entry['calories'] as int));
    final mealGoal = _currentCalorieGoal / 4;
    final progress = mealGoal > 0 ? (totalMealCalories / mealGoal).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => _showMealDetailSheet(mealType),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [cardColor.withOpacity(0.9), cardColor], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 12, offset: const Offset(0, 6))]),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$mealType', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      SizedBox(height: 36, width: 36, child: Stack(fit: StackFit.expand, children: [CircularProgressIndicator(value: progress, backgroundColor: Colors.grey.shade800, valueColor: const AlwaysStoppedAnimation<Color>(accentColor), strokeWidth: 4), Center(child: Icon(Icons.check, color: progress == 1.0 ? accentColor : Colors.transparent, size: 16))])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_classifyFood(totalMealCalories), style: GoogleFonts.inter(fontSize: 14, color: textColor.withOpacity(0.8))),
                  const SizedBox(height: 12),
                  if (mealEntries.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Logged Foods:", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: math.min(mealEntries.length, 3),
                            itemBuilder: (context, index) {
                              final entry = mealEntries[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Expanded(child: Text("• ${entry['name']}", style: GoogleFonts.inter(fontSize: 11, color: textColor.withOpacity(0.8)), overflow: TextOverflow.ellipsis, maxLines: 1)),
                                    Text(entry['classification'], style: GoogleFonts.inter(fontSize: 11, color: textColor.withOpacity(0.7), fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (mealEntries.length > 3)
                          Text("+ ${mealEntries.length - 3} more...", style: GoogleFonts.inter(fontSize: 11, color: textColor.withOpacity(0.6), fontStyle: FontStyle.italic)),
                      ],
                    )
                  else
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text("No food logged yet", style: GoogleFonts.inter(fontSize: 12, color: textColor.withOpacity(0.5), fontStyle: FontStyle.italic))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showMealDetailSheet(mealType),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Food', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: secondaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMealDetailSheet(String mealType) {
    _currentSearchMealType = mealType;
    _searchResults.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            void updateSheet() => setSheetState(() {});
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(color: primaryColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  child: Column(
                    children: [
                      Padding(padding: const EdgeInsets.all(16.0), child: Text(mealType, style: GoogleFonts.poppins(color: textColor, fontSize: 22, fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: _buildMealInput(mealType, onSearch: updateSheet)),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_isSearching && _currentSearchMealType == mealType)
                              const Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Center(child: CircularProgressIndicator(color: accentColor)))
                            else if (_searchResults.isNotEmpty && _currentSearchMealType == mealType)
                              _buildSearchResults(onFoodAdded: () => Navigator.pop(context)),
                            if (_getEntriesByMealType(mealType).isEmpty)
                              Padding(padding: const EdgeInsets.all(32.0), child: Text("No food logged for $mealType yet.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: textColor.withOpacity(0.5))))
                            else
                              ..._buildMealEntryItems(mealType),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMealInput(String mealType, {VoidCallback? onSearch}) {
    return Row(
      children: [
        Expanded(child: TextField(controller: _foodNameControllers[mealType], style: GoogleFonts.inter(color: textColor), decoration: InputDecoration(hintText: "Enter food name...", hintStyle: GoogleFonts.inter(color: textColor.withOpacity(0.5)), filled: true, fillColor: cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)), onSubmitted: (value) => _addFoodFromLocal(mealType, onStateChanged: onSearch))),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.search, color: accentColor), onPressed: () {
          final query = _foodNameControllers[mealType]!.text.trim();
          if (query.isNotEmpty) _searchUSDAFood(query, mealType, onStateChanged: onSearch);
        },
        ),
      ],
    );
  }

  Widget _buildSearchResults({VoidCallback? onFoodAdded}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Search Results:", style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final food = _searchResults[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(food['name'], style: GoogleFonts.inter(color: textColor)),
              subtitle: Text(food['classification'], style: GoogleFonts.inter(color: textColor.withOpacity(0.7))),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: accentColor),
                onPressed: () async {
                  final foodEntry = await _showServingSizeDialog(food);
                  if (foodEntry != null) {
                    _addFood(foodEntry);
                    onFoodAdded?.call();
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildMealEntryItems(String mealType) {
    final entries = _getEntriesByMealType(mealType);
    return entries.map((entry) {
      return Dismissible(
        key: Key(entry['timestamp'].toString()),
        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => _removeFood(_entries.indexWhere((e) => e['timestamp'] == entry['timestamp'])),
        child: Card(
          color: cardColor,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(entry['name'], style: GoogleFonts.inter(color: textColor)),
            subtitle: Text("${entry['classification']}", style: GoogleFonts.inter(color: textColor.withOpacity(0.7))),
            trailing: Text("${entry['quantity']}x ${entry['servingSize']}", style: GoogleFonts.inter(color: textColor.withOpacity(0.6), fontSize: 12)),
          ),
        ),
      );
    }).toList();
  }
}