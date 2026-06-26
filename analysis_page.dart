import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AnalysisPage extends StatefulWidget {
  final List<String>? initialIngredients;
  final Map<String, double>? initialNutrients;

  const AnalysisPage({
    Key? key,
    this.initialIngredients,
    this.initialNutrients,
  }) : super(key: key);

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String selectedIngredient = '';
  String selectedDietType = '';
  String selectedFoodType = '';
  String selectedRecipe = '';
  String selectedUser = '';

  List<String> ingredients = [];
  List<String> dietTypes = [];
  List<String> foodTypes = [];
  List<String> recipes = [];
  List<String> users = [];

  Map<String, int> ingredientUsage = {};
  String mostLikedRecipe = '';
  String mostLikedFoodType = '';
  String mostCommonDietType = '';

  int usersWithSelectedDiet = 0;
  int usersWithSelectedFoodType = 0;
  int usersWhoLikedRecipe = 0;

  List<String> usersWithSameDiet = [];
  Map<String, dynamic> userPreferences = {};
  Map<String, dynamic> recipeDetails = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredients != null) {
      ingredients = widget.initialIngredients!;
    }
    _fetchAnalysisData();
  }

  Future<void> _fetchAnalysisData() async {
    setState(() => isLoading = true);
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/analysis');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          ingredients = (data['ingredients'] as List<dynamic>).cast<String>();
          dietTypes = (data['dietTypes'] as List<dynamic>).cast<String>();
          foodTypes = (data['foodTypes'] as List<dynamic>).cast<String>();
          recipes = (data['recipes'] as List<dynamic>).cast<String>();
          users = (data['users'] as List<dynamic>).cast<String>();

          ingredientUsage = (data['ingredientUsage'] as Map<String, dynamic>).cast<String, int>();
          mostLikedRecipe = data['mostLikedRecipe'];
          mostLikedFoodType = data['mostLikedFood'];
          mostCommonDietType = data['mostCommonDietType'];
        });
      } else {
        print('Failed to fetch analysis data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching analysis data: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchDietTypeStats(String dietType) async {
    setState(() => isLoading = true);
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/dietTypeStats?dietType=$dietType');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          usersWithSelectedDiet = data['userCount'];
          usersWithSameDiet = (data['users'] as List<dynamic>).cast<String>();
        });
      }
    } catch (error) {
      print('Error fetching diet type stats: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchFoodTypeStats(String foodType) async {
    setState(() => isLoading = true);
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/foodTypeStats?foodType=$foodType');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          usersWithSelectedFoodType = data['userCount'];
        });
      }
    } catch (error) {
      print('Error fetching food type stats: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRecipeStats(String recipe) async {
    setState(() => isLoading = true);
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/recipeStats?recipe=$recipe');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          usersWhoLikedRecipe = data['userCount'];
        });
      }
    } catch (error) {
      print('Error fetching recipe stats: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserPreferences(String userName) async {
    setState(() => isLoading = true);
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/userPreferences?userName=$userName');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userPreferences = {
            'recipes': (data['recipes'] as List<dynamic>).cast<String>(),
            'foodTypes': (data['foodTypes'] as List<dynamic>).cast<String>(),
            'dietTypes': (data['dietTypes'] as List<dynamic>).cast<String>(),
            'ingredients': (data['ingredients'] as List<dynamic>).cast<String>(),
          };
        });
      }
    } catch (error) {
      print('Error fetching user preferences: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRecipeDetails(String recipeName) async {
    setState(() => isLoading = true);
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/recipeDetails?recipeName=$recipeName');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recipeDetails = {
            'name': data['name'],
            'instructions': data['instructions'],
            'foodType': data['foodType'],
            'dietType': data['dietType'],
            'ingredients': (data['ingredients'] as List<dynamic>).cast<String>(),
            'calories': data['calories'],
            'protein': data['protein'],
            'carbs': data['carbohydrates'],
            'fats': data['fats'],
            'cholesterol': data['cholesterol'],
            'sugar': data['sugar'],
          };
        });
      }
    } catch (error) {
      print('Error fetching recipe details: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDropdown(String title, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          isExpanded: true,
          value: value.isNotEmpty ? value : null,
          hint: Text('Select $title'),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        ...children,
        Divider(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Analysis Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Popularity Statistics
            _buildSection('Most Popular Items', [
              ListTile(
                title: Text('Recipe:'),
                subtitle: Text(mostLikedRecipe, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('Food Type:'),
                subtitle: Text(mostLikedFoodType, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('Diet Type:'),
                subtitle: Text(mostCommonDietType, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),

            // Recipe Analysis
            _buildSection('Recipe Analysis', [
              _buildDropdown('Recipe', selectedRecipe, recipes, (value) {
                setState(() => selectedRecipe = value ?? '');
                if (value != null) {
                  _fetchRecipeStats(value);
                  _fetchRecipeDetails(value);
                }
              }),
              if (selectedRecipe.isNotEmpty) ...[
                ListTile(
                  title: Text('Liked by:'),
                  subtitle: Text('$usersWhoLikedRecipe users', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (recipeDetails.isNotEmpty) ...[
                  ListTile(
                    title: Text('Details:'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${recipeDetails['foodType']} (${recipeDetails['dietType']})'),
                        Text('Ingredients: ${recipeDetails['ingredients'].join(', ')}'),
                        Text('Calories: ${recipeDetails['calories']}'),
                        Text('Protein: ${recipeDetails['protein']}g'),
                        Text('Carbs: ${recipeDetails['carbs']}g'),
                        Text('Fats: ${recipeDetails['fats']}g'),
                      ],
                    ),
                  ),
                ],
              ],
            ]),

            // Food Type Analysis
            _buildSection('Food Type Analysis', [
              _buildDropdown('Food Type', selectedFoodType, foodTypes, (value) {
                setState(() => selectedFoodType = value ?? '');
                if (value != null) _fetchFoodTypeStats(value);
              }),
              if (selectedFoodType.isNotEmpty)
                ListTile(
                  title: Text('Preferred by:'),
                  subtitle: Text('$usersWithSelectedFoodType users', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ]),

            // Diet Type Analysis
            _buildSection('Diet Type Analysis', [
              _buildDropdown('Diet Type', selectedDietType, dietTypes, (value) {
                setState(() => selectedDietType = value ?? '');
                if (value != null) _fetchDietTypeStats(value);
              }),
              if (selectedDietType.isNotEmpty) ...[
                ListTile(
                  title: Text('Followed by:'),
                  subtitle: Text('$usersWithSelectedDiet users', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (usersWithSameDiet.isNotEmpty) ...[
                  Text('Users following this diet:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  ...usersWithSameDiet.map((user) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text('- $user'),
                  )).toList(),
                ],
              ],
            ]),

            // User Preferences
            _buildSection('User Preferences', [
              _buildDropdown('User', selectedUser, users, (value) {
                setState(() => selectedUser = value ?? '');
                if (value != null) _fetchUserPreferences(value);
              }),
              if (selectedUser.isNotEmpty && userPreferences.isNotEmpty) ...[
                ListTile(
                  title: Text('Preferred Recipes:'),
                  subtitle: Text(userPreferences['recipes'].join(', ')),
                ),
                ListTile(
                  title: Text('Preferred Food Types:'),
                  subtitle: Text(userPreferences['foodTypes'].join(', ')),
                ),
                ListTile(
                  title: Text('Preferred Diet Types:'),
                  subtitle: Text(userPreferences['dietTypes'].join(', ')),
                ),
                ListTile(
                  title: Text('Common Ingredients:'),
                  subtitle: Text(userPreferences['ingredients'].join(', ')),
                ),
              ],
            ]),

            // Ingredient Analysis
            _buildSection('Ingredient Analysis', [
              _buildDropdown('Ingredient', selectedIngredient, ingredients, (value) {
                setState(() => selectedIngredient = value ?? '');
              }),
              if (selectedIngredient.isNotEmpty && ingredientUsage.containsKey(selectedIngredient))
                ListTile(
                  title: Text('Usage:'),
                  subtitle: Text('Used in ${ingredientUsage[selectedIngredient]} recipes',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}