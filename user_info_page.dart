import 'package:flutter/material.dart';
import 'food_filter_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserInfoPage extends StatefulWidget {
  final String email;

  const UserInfoPage({Key? key, required this.email}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  String? selectedGender;
  String? selectedFoodType;
  String? selectedDiet;
  bool _isLoading = false;

  List<String> genders = ['Male', 'Female', 'Other'];
  List<String> foodTypeOptions = [];
  List<String> dietOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchFoodTypes();
    _fetchDietOptions();
  }

  Future<void> _fetchFoodTypes() async {
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/foodTypes');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          foodTypeOptions = data.cast<String>();
        });
      }
    } catch (error) {
      print('Error fetching food types: $error');
    }
  }

  Future<void> _fetchDietOptions() async {
    final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
    final url = Uri.parse('http://$ipAddress:3000/api/dietTypes');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          dietOptions = data.cast<String>();
        });
      }
    } catch (error) {
      print('Error fetching diet options: $error');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final ipAddress = dotenv.env['API_IP'] ?? 'localhost';
      final url = Uri.parse('http://$ipAddress:3000/api/updateUserInfo');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
            'name': nameController.text,
            'age': ageController.text,
            'gender': selectedGender,
            'foodType': selectedFoodType,
            'dietType': selectedDiet,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User information updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FoodFilterPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update user information'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to the server'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: TextStyle(color: Color(0xFF3D3D3D)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF6C63FF)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                margin: EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.account_circle, size: 60, color: Color(0xFF6C63FF)),
                    SizedBox(height: 16),
                    Text(
                      "Tell us about yourself",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "We'll use this to personalize your experience",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Name Field
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration('Full Name', Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Age Field
              TextFormField(
                controller: ageController,
                decoration: _inputDecoration('Age', Icons.cake),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Gender Dropdown
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: _inputDecoration('Gender', Icons.people),
                  items: genders.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGender = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),

              // Food Type Dropdown
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedFoodType,
                  decoration: _inputDecoration('Preferred Food Type', Icons.fastfood),
                  items: foodTypeOptions.map((String foodType) {
                    return DropdownMenuItem<String>(
                      value: foodType,
                      child: Text(foodType),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFoodType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a food type';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),

              // Diet Type Dropdown
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedDiet,
                  decoration: _inputDecoration('Diet Type', Icons.restaurant),
                  items: dietOptions.map((String diet) {
                    return DropdownMenuItem<String>(
                      value: diet,
                      child: Text(diet),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDiet = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a diet type';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: Color(0xFF6C63FF).withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    "SAVE PROFILE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Color(0xFF6C63FF)),
      prefixIcon: Icon(icon, color: Color(0xFF6C63FF)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
      ),
    );
  }
}
