import 'dart:convert';
import 'package:http/http.dart' as http;

class USDAService {
  final String apiKey = "QipYRkYT9VLxRdig1sui1czCNzUL59Arm4XkleFy"; // Replace with your USDA key

  Future<Map<String, dynamic>?> searchFood(String query) async {
    final url = Uri.parse(
      "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$apiKey&query=$query",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["foods"] != null && data["foods"].isNotEmpty) {
        final food = data["foods"][0]; // Best match
        return {
          "name": food["description"],
          "calories": _getNutrient(food, "Energy"),
          "protein": _getNutrient(food, "Protein"),
          "fat": _getNutrient(food, "Total lipid (fat)"),
          "carbs": _getNutrient(food, "Carbohydrate, by difference"),
        };
      }
    }
    return null;
  }

  double _getNutrient(Map food, String nutrientName) {
    final nutrients = food["foodNutrients"] ?? [];
    final match = nutrients.firstWhere(
          (n) => n["nutrientName"] == nutrientName,
      orElse: () => {"value": 0.0},
    );
    return (match["value"] as num).toDouble();
  }
}
