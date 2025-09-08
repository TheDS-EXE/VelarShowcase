import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Color scheme to match the progress screen
const Color primaryColor = Color(0xFF2C2C2C);
const Color secondaryColor = Color(0xFF8B0000);
const Color accentColor = Color(0xFFD32F2F);
const Color backgroundColor = Color(0xFF1A1A1A);
const Color textColor = Color(0xFFE0E0E0);
const Color cardColor = Color(0xFF242424);

class BMIScreen extends StatefulWidget {
  final Function(int) onCalorieGoalSet;
  const BMIScreen({super.key, required this.onCalorieGoalSet});

  @override
  State<BMIScreen> createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  double? _bmi;
  String _classification = "";
  int? _calorieGoal;

  void _calculateBMI() async {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid height and weight values',
              style: GoogleFonts.inter(color: textColor)),
          backgroundColor: accentColor,
        ),
      );
      return;
    }

    // Save height to shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('userHeight', height);
      print('Height saved: $height cm');
    } catch (e) {
      print('Error saving height: $e');
    }

    final bmi = weight / ((height / 100) * (height / 100));
    String classification;
    int calorieGoal;

    if (bmi < 18.5) {
      classification = "Underweight";
      calorieGoal = 2500;
    } else if (bmi < 25) {
      classification = "Normal";
      calorieGoal = 2000;
    } else if (bmi < 30) {
      classification = "Overweight";
      calorieGoal = 1800;
    } else {
      classification = "Obese";
      calorieGoal = 1500;
    }

    setState(() {
      _bmi = bmi;
      _classification = classification;
      _calorieGoal = calorieGoal;
    });

    widget.onCalorieGoalSet(calorieGoal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Card(
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.5),
            margin: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set Your Calorie Goal",
                      style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: textColor
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Calculate your BMI to get a personalized calorie goal",
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          color: textColor.withOpacity(0.7)
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: "Height (cm)",
                        labelStyle: GoogleFonts.inter(color: textColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: GoogleFonts.poppins(color: textColor, fontSize: 16),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: "Weight (kg)",
                        labelStyle: GoogleFonts.inter(color: textColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: GoogleFonts.poppins(color: textColor, fontSize: 16),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _calculateBMI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                        ),
                      ),
                      child: const SizedBox(
                        width: double.infinity,
                        child: Text("Calculate BMI & Set Goal", textAlign: TextAlign.center),
                      ),
                    ),
                    if (_bmi != null) ...[
                      const SizedBox(height: 20),
                      Divider(color: textColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text("Your BMI: ${_bmi!.toStringAsFixed(1)}",
                          style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600
                          )),
                      const SizedBox(height: 8),
                      Text("Classification: $_classification",
                          style: GoogleFonts.poppins(
                              color: _classification == "Normal" ? Colors.green : Colors.orange,
                              fontSize: 16
                          )),
                      const SizedBox(height: 8),
                      Text("Recommended Calories: $_calorieGoal kcal",
                          style: GoogleFonts.inter(
                              color: textColor.withOpacity(0.7),
                              fontSize: 16
                          )),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}