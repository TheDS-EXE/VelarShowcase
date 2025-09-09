// lib/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

// Color scheme to match the rest of the app
const Color primaryColor = Color(0xFF2C2C2C);
const Color secondaryColor = Color(0xFF8B0000);
const Color accentColor = Color(0xFFD32F2F);
const Color backgroundColor = Color(0xFF1A1A1A);
const Color textColor = Color(0xFFE0E0E0);
const Color cardColor = Color(0xFF242424);

// Helper class to handle weight data consistently across screens.
class WeightEntry {
  final double weight;
  final DateTime date;

  WeightEntry({required this.weight, required this.date});
}

// Main screen for tracking weight progress.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _weightController = TextEditingController();
  List<WeightEntry> _weightHistory = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadWeightHistory();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _loadWeightHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('weightHistory') ?? [];
    if (mounted) {
      setState(() {
        _weightHistory = history.map((entry) {
          final parts = entry.split('|');
          return WeightEntry(
              weight: double.parse(parts[0]), date: DateTime.parse(parts[1]));
        }).toList();
        if (_weightHistory.isNotEmpty) {
          _weightHistory.sort((a, b) => b.date.compareTo(a.date));
          _weightController.text = _weightHistory.first.weight.toString();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _addOrUpdateWeight() async {
    final double? weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please enter a valid weight.",
            style: GoogleFonts.inter(color: textColor)),
        backgroundColor: accentColor,
      ));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _weightHistory.removeWhere((entry) => _isSameDate(entry.date, _selectedDate));
    _weightHistory.add(WeightEntry(weight: weight, date: _selectedDate));
    _weightHistory.sort((a, b) => a.date.compareTo(b.date));

    final updatedHistory = _weightHistory
        .map((e) => '${e.weight}|${e.date.toIso8601String()}')
        .toList();
    await prefs.setStringList('weightHistory', updatedHistory);

    _animationController.reset();
    _animationController.forward();

    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Weight saved successfully!",
            style: GoogleFonts.inter(color: textColor)),
        backgroundColor: const Color(0xFF006400),
      ));
      setState(() {});
    }
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _updateWeightForSelectedDate();
    });
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      final now = DateTime.now();
      if (_selectedDate.isAfter(DateTime(now.year, now.month, now.day))) {
        _selectedDate = DateTime(now.year, now.month, now.day);
      }
      _updateWeightForSelectedDate();
    });
  }

  void _updateWeightForSelectedDate() {
    final entry = _weightHistory.firstWhere(
          (entry) => _isSameDate(entry.date, _selectedDate),
      orElse: () => WeightEntry(weight: 0, date: _selectedDate),
    );

    if (entry.weight > 0) {
      _weightController.text = entry.weight.toString();
    } else {
      _weightController.clear();
    }
  }

  Future<void> _deleteWeightEntry(WeightEntry entry) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _weightHistory.removeWhere((e) => e.date == entry.date && e.weight == entry.weight);
    });

    final updatedHistory = _weightHistory
        .map((e) => '${e.weight}|${e.date.toIso8601String()}')
        .toList();
    await prefs.setStringList('weightHistory', updatedHistory);

    _animationController.reset();
    _animationController.forward();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Entry deleted successfully!",
          style: GoogleFonts.inter(color: textColor)),
      backgroundColor: accentColor,
    ));
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HistoryDialog(
          history: _weightHistory,
          onDelete: _deleteWeightEntry,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWeightChartCard(),
          const SizedBox(height: 24),
          _buildWeightEntryCard(),
        ],
      ),
    );
  }

  Widget _buildWeightChartCard() {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Your Progress",
                      style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.history, color: textColor),
                    onPressed: _showHistoryDialog,
                    tooltip: "View Full History",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 16 / 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: accentColor))
                      : _weightHistory.length < 2
                      ? Center(
                    child: Text(
                      "Log weight for 2+ days\nto see your graph.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: textColor.withOpacity(0.6)),
                    ),
                  )
                      : AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _WeightGraphPainter(
                          weightHistory: _weightHistory,
                          animationValue: _animation.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightEntryCard() {
    final now = DateTime.now();
    final isToday = _isSameDate(_selectedDate, now);
    final isFutureDate = _selectedDate.isAfter(DateTime(now.year, now.month, now.day));

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Log Weight For",
                    style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          color: textColor.withOpacity(0.7)),
                      onPressed: _goToPreviousDay,
                    ),
                    Text(
                      isToday ? "Today" : "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios,
                          color: isFutureDate ? textColor.withOpacity(0.3) : textColor.withOpacity(0.7)),
                      onPressed: isFutureDate ? null : _goToNextDay,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(
                  color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: backgroundColor,
                hintText: "0.0",
                hintStyle: GoogleFonts.poppins(
                    color: textColor.withOpacity(0.4),
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                suffixText: "kg",
                suffixStyle: GoogleFonts.inter(
                    color: textColor.withOpacity(0.6), fontSize: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_rounded, size: 20),
              label: const Text("Save Weight"),
              onPressed: _addOrUpdateWeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightGraphPainter extends CustomPainter {
  final List<WeightEntry> weightHistory;
  final double animationValue;

  _WeightGraphPainter({
    required this.weightHistory,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weightHistory.length < 2) return;

    weightHistory.sort((a, b) => a.date.compareTo(b.date));

    // --- MODIFICATION START: Smarter logic for calculating graph labels ---

    // 1. Find the true min and max from the data.
    double minDataWeight = weightHistory.map((e) => e.weight).reduce(min);
    double maxDataWeight = weightHistory.map((e) => e.weight).reduce(max);

    // 2. Define a target for how many lines we want, to avoid clutter.
    const int maxHorizontalLines = 3;

    // 3. Calculate "nice" (rounded) top and bottom boundaries for the graph.
    double interval = 5.0; // Start with a default nice interval.
    double niceMinWeight = (minDataWeight / interval).floor() * interval;
    double niceMaxWeight = (maxDataWeight / interval).ceil() * interval;

    // 4. Dynamically increase the interval if it creates too many lines.
    // This ensures the graph is never cluttered, even with a large weight range.
    while (((niceMaxWeight - niceMinWeight) / interval).floor() > maxHorizontalLines) {
      interval *= 2; // e.g., 5kg becomes 10kg, then 20kg, etc.
    }

    // Recalculate boundaries with the potentially larger interval
    niceMinWeight = (minDataWeight / interval).floor() * interval;
    niceMaxWeight = (maxDataWeight / interval).ceil() * interval;


    // 5. Handle edge cases where all data points are very close.
    if (niceMinWeight == niceMaxWeight) {
      niceMaxWeight += interval;
    }
    double niceRange = niceMaxWeight - niceMinWeight;
    if (niceRange <= 0) niceRange = 1;

    // --- MODIFICATION END ---

    final points = <Offset>[];
    for (int i = 0; i < weightHistory.length; i++) {
      final x = size.width * (i / (weightHistory.length - 1));
      final y = size.height - ((weightHistory[i].weight - niceMinWeight) / niceRange) * size.height;
      points.add(Offset(x, y));
    }

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Use the final dynamic interval to draw the grid lines and labels.
    for (double labelValue = niceMinWeight; labelValue <= niceMaxWeight; labelValue += interval) {
      if (labelValue == niceMinWeight) continue;

      final y = size.height - ((labelValue - niceMinWeight) / niceRange) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      final textSpan = TextSpan(
        text: '${labelValue.round()}kg',
        style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - textPainter.height / 2));
    }

    if (weightHistory.length > 1) {
      final dateTextStyle = TextStyle(color: textColor.withOpacity(0.6), fontSize: 10);
      final indicesToShow = {0, weightHistory.length ~/ 2, weightHistory.length - 1}.toList();

      for (final index in indicesToShow) {
        final entry = weightHistory[index];
        final x = size.width * (index / (weightHistory.length - 1));
        final formattedDate = '${entry.date.day}/${entry.date.month}';
        final textSpan = TextSpan(text: formattedDate, style: dateTextStyle);
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        final labelX = (x - textPainter.width / 2).clamp(0.0, size.width - textPainter.width);
        textPainter.paint(canvas, Offset(labelX, size.height + 4));
      }
    }

    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) * 0.5, p1.dy);
      final controlPoint2 = Offset(p2.dx - (p2.dx - p1.dx) * 0.5, p2.dy);
      path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p2.dx, p2.dy
      );
    }

    final animatedPath = Path();
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    final animatedLength = totalLength * animationValue;

    final extractMetrics = metrics.extractPath(0, animatedLength);
    animatedPath.addPath(extractMetrics, Offset.zero);

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.5)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(animatedPath, glowPaint);
    canvas.drawPath(animatedPath, linePaint);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final pointProgress = (i / (points.length - 1)) * animationValue;

      if (pointProgress <= 1.0) {
        canvas.drawCircle(point, 5, pointPaint);
        canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeightGraphPainter oldDelegate) {
    return oldDelegate.weightHistory != weightHistory ||
        oldDelegate.animationValue != animationValue;
  }
}

class HistoryDialog extends StatelessWidget {
  final List<WeightEntry> history;
  final Function(WeightEntry) onDelete;

  const HistoryDialog({super.key, required this.history, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final reversedHistory = history.reversed.toList();

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Weight History",
                      style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reversedHistory.isEmpty
                  ? Center(
                child: Text(
                  "No entries yet.",
                  style: GoogleFonts.inter(color: textColor.withOpacity(0.7)),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: reversedHistory.length,
                itemBuilder: (context, index) {
                  final entry = reversedHistory[index];
                  final formattedDate =
                      "${entry.date.day}/${entry.date.month}/${entry.date.year}";

                  return Dismissible(
                    key: Key('${entry.date.toIso8601String()}-${entry.weight}'),
                    background: Container(
                      color: accentColor,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: cardColor,
                            title: Text("Delete Entry",
                                style: GoogleFonts.poppins(color: textColor)),
                            content: Text("Are you sure you want to delete this weight entry?",
                                style: GoogleFonts.inter(color: textColor.withOpacity(0.8))),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text("Cancel",
                                    style: GoogleFonts.inter(color: textColor)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text("Delete",
                                    style: GoogleFonts.inter(color: accentColor)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      onDelete(entry);
                    },
                    child: ClipRRect(
                      child: Container(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: const Icon(Icons.scale, color: accentColor),
                          title: Text("${entry.weight} kg",
                              style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          subtitle: Text(formattedDate,
                              style: GoogleFonts.inter(
                                  color: textColor.withOpacity(0.7))),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}