import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecommendationPage extends StatefulWidget {
  final List<String> selectedIngredients;
  final Map<String, double> nutrients;
  final String? foodType;
  final String? dietType;
  final String? userEmail;

  const RecommendationPage({
    Key? key,
    required this.selectedIngredients,
    required this.nutrients,
    this.foodType,
    this.dietType,
    this.userEmail,
  }) : super(key: key);

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  late Future<List<Map<String, dynamic>>> _recommendationsFuture;
  bool _isLoading = true;
  String _error = '';
  int _relationsCreated = 0;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _fetchRecommendations();
  }

  Future<List<Map<String, dynamic>>> _fetchRecommendations() async {
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/recommendations');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ingredients': widget.selectedIngredients,
          'nutrients': widget.nutrients,
          'foodType': widget.foodType,
          'dietType': widget.dietType,
          'userEmail': widget.userEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _relationsCreated = data['relationsCreated'] ?? 0;
        });
        return List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
      } else {
        throw Exception('Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      return [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation['name'] ?? 'Unnamed Recipe',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 8),
            if (recommendation['reason'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  recommendation['reason'],
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            if (recommendation['instructions'] != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    'Instructions',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        recommendation['instructions'],
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (recommendation['foodType'] != null)
                  Chip(
                    label: Text(recommendation['foodType']),
                    backgroundColor: Color(0xFF6C63FF).withOpacity(0.2),
                    labelStyle: TextStyle(color: Color(0xFF6C63FF)),
                  ),
                if (recommendation['dietType'] != null)
                  Chip(
                    label: Text(recommendation['dietType']),
                    backgroundColor: Colors.green[100],
                    labelStyle: TextStyle(color: Colors.green[800]),
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (recommendation.containsKey('nutrients'))
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutritional Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildNutritionRow('Calories', recommendation['nutrients']['calories'], 'kcal'),
                    _buildNutritionRow('Protein', recommendation['nutrients']['protein'], 'g'),
                    _buildNutritionRow('Carbs', recommendation['nutrients']['carbs'], 'g'),
                    _buildNutritionRow('Fats', recommendation['nutrients']['fats'], 'g'),
                    if (recommendation['nutrients']['cholesterol'] != null)
                      _buildNutritionRow('Cholesterol', recommendation['nutrients']['cholesterol'], 'mg'),
                    if (recommendation['nutrients']['sugar'] != null)
                      _buildNutritionRow('Sugar', recommendation['nutrients']['sugar'], 'g'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, dynamic value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A',
            style: TextStyle(color: Color(0xFF3D3D3D)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Recommended Recipes',
          style: TextStyle(color: Color(0xFF3D3D3D)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF6C63FF)),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
        ),
      )
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),
            Text(
              'Error loading recommendations',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fastfood,
                    size: 48,
                    color: Color(0xFF6C63FF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No recommendations found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                  if (_relationsCreated > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'We found $_relationsCreated matching recipes in our database',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildRecommendationCard(snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}
