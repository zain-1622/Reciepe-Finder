import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'recommendation_page.dart';

class FoodFilterPage extends StatefulWidget {
  @override
  _FoodFilterPageState createState() => _FoodFilterPageState();
}

class _FoodFilterPageState extends State<FoodFilterPage> {
  final _formKey = GlobalKey<FormState>();
  List<String> allIngredients = [];
  List<String> selectedIngredients = [];
  List<String> foodTypeOptions = [];
  List<String> dietOptions = [];
  String? selectedFoodType;
  String? selectedDiet;
  List<dynamic> recipes = [];
  bool isLoading = false;
  String? errorMessage;

  final Color primaryColor = Color(0xFF6C63FF); // Theme Color

  Map<String, Map<String, dynamic>> nutrientData = {
    'calories': {'values': <double>[], 'unit': 'kcal', 'selected': null},
    'protein': {'values': <double>[], 'unit': 'g', 'selected': null},
    'carbohydrates': {'values': <double>[], 'unit': 'g', 'selected': null},
    'fats': {'values': <double>[], 'unit': 'g', 'selected': null},
    'cholesterol': {'values': <double>[], 'unit': 'mg', 'selected': null},
    'sugar': {'values': <double>[], 'unit': 'g', 'selected': null},
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchIngredients(),
      _fetchNutrientValues(),
      _fetchFoodTypes(),
      _fetchDietOptions(),
    ]);
  }

  Future<void> _fetchIngredients() async {
    await _fetchList('/api/ingredients', (data) {
      allIngredients = data.cast<String>();
    });
  }

  Future<void> _fetchFoodTypes() async {
    await _fetchList('/api/foodTypes', (data) {
      foodTypeOptions = data.cast<String>();
    });
  }

  Future<void> _fetchDietOptions() async {
    await _fetchList('/api/dietTypes', (data) {
      dietOptions = data.cast<String>();
    });
  }

  Future<void> _fetchNutrientValues() async {
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/nutrientValues');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nutrientData.forEach((key, _) {
            nutrientData[key]!['values'] = (data[key] as List).map<double>((e) => e.toDouble()).toList()..sort();
          });
        });
      }
    } catch (error) {
      setState(() => errorMessage = 'Failed to fetch nutrient values.');
    }
  }

  Future<void> _fetchList(String endpoint, Function(List<dynamic>) onSuccess) async {
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000$endpoint');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => onSuccess(data));
      }
    } catch (error) {
      setState(() => errorMessage = 'Error fetching data: $error');
    }
  }

  Future<void> _filterRecipes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      recipes = [];
      errorMessage = null;
    });

    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/filterRecipes');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ingredients': selectedIngredients,
          'calories': nutrientData['calories']!['selected'],
          'protein': nutrientData['protein']!['selected'],
          'carbs': nutrientData['carbohydrates']!['selected'],
          'fats': nutrientData['fats']!['selected'],
          'cholesterol': nutrientData['cholesterol']!['selected'],
          'sugar': nutrientData['sugar']!['selected'],
          'foodType': selectedFoodType,
          'dietType': selectedDiet,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          recipes = data;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch recipes.';
        });
      }
    } catch (error) {
      setState(() => errorMessage = 'Server error: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToRecommendationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationPage(
          selectedIngredients: selectedIngredients,
          nutrients: {
            'calories': nutrientData['calories']!['selected'] ?? 0,
            'protein': nutrientData['protein']!['selected'] ?? 0,
            'carbohydrates': nutrientData['carbohydrates']!['selected'] ?? 0,
            'fats': nutrientData['fats']!['selected'] ?? 0,
            'cholesterol': nutrientData['cholesterol']!['selected'] ?? 0,
            'sugar': nutrientData['sugar']!['selected'] ?? 0,
          },
          foodType: selectedFoodType,
          dietType: selectedDiet,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildChipList() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: allIngredients.map((ingredient) {
        final selected = selectedIngredients.contains(ingredient);
        return FilterChip(
          label: Text(ingredient),
          selected: selected,
          onSelected: (isSelected) {
            setState(() {
              if (isSelected) {
                selectedIngredients.add(ingredient);
              } else {
                selectedIngredients.remove(ingredient);
              }
            });
          },
          selectedColor: primaryColor.withOpacity(0.3),
          backgroundColor: Colors.grey[200],
        );
      }).toList(),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedItem,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: selectedItem,
      items: [
        DropdownMenuItem<T>(value: null, child: Text('Any')),
        ...items.map<DropdownMenuItem<T>>(
              (item) => DropdownMenuItem<T>(value: item, child: Text(item.toString())),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],  // Background color for dropdown
        labelStyle: TextStyle(color: Color(0xFF6C63FF)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildNutrientFilter(String name) {
    final data = nutrientData[name.toLowerCase()]!;
    return DropdownButtonFormField<double>(
      decoration: InputDecoration(
        labelText: 'Max ${name.capitalize()} (${data['unit']})',
        filled: true,
        fillColor: Colors.grey[200],  // Background color for nutrient filters
        labelStyle: TextStyle(color: Color(0xFF6C63FF)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      value: data['selected'],
      items: [
        DropdownMenuItem<double>(value: null, child: Text('No limit')),
        ...((data['values'] as List<double>).map<DropdownMenuItem<double>>(
              (value) => DropdownMenuItem<double>(
            value: value,
            child: Text('${value.toStringAsFixed(1)} ${data['unit']}'),
          ),
        ).toList()),
      ],
      onChanged: (value) => setState(() => data['selected'] = value),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe['name'] ?? 'Unnamed', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (recipe['foodType'] != null)
                  Chip(label: Text(recipe['foodType']), backgroundColor: primaryColor.withOpacity(0.2)),
                if (recipe['dietType'] != null)
                  Chip(label: Text(recipe['dietType']), backgroundColor: primaryColor.withOpacity(0.2)),
              ],
            ),
            SizedBox(height: 12),
            if (recipe['instructions'] != null) ...[
              Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(recipe['instructions']),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Recipe Finder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Ingredients'),
              if (allIngredients.isEmpty)
                Center(child: CircularProgressIndicator(color: primaryColor))
              else
                _buildChipList(),

              _buildSectionTitle('Food Preferences'),
              _buildDropdown(
                label: 'Preferred Food Type',
                items: foodTypeOptions,
                selectedItem: selectedFoodType,
                onChanged: (val) => setState(() => selectedFoodType = val),
              ),
              SizedBox(height: 8),
              _buildDropdown(
                label: 'Diet Type',
                items: dietOptions,
                selectedItem: selectedDiet,
                onChanged: (val) => setState(() => selectedDiet = val),
              ),

              _buildSectionTitle('Nutrition Filters'),
              ...['Calories', 'Protein', 'Carbohydrates', 'Fats', 'Cholesterol', 'Sugar']
                  .map((nutrient) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildNutrientFilter(nutrient),
              ))
                  .toList(),

              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _filterRecipes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Find Recipes', style: TextStyle(fontWeight: FontWeight.bold ,color: Colors.white,)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _navigateToRecommendationPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6C63FF),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Get Recommendations', style: TextStyle(fontWeight: FontWeight.bold ,color: Colors.white,)),
                    ),
                  ),
                ],
              ),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red))),
                ),

              if (recipes.isNotEmpty)
                ...recipes.map((r) => _buildRecipeCard(r)).toList()
              else if (!isLoading && selectedIngredients.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Select some ingredients or set filters to find recipes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}