class FoodModel {
  final String name;
  final List<String> ingredients;
  final Map<String, double> nutrients; // e.g. { "protein": 20.5, "carbs": 50.2 }

  FoodModel({
    required this.name,
    required this.ingredients,
    required this.nutrients,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ingredients': ingredients,
      'nutrients': nutrients,
    };
  }

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      name: json['name'],
      ingredients: List<String>.from(json['ingredients']),
      nutrients: Map<String, double>.from(json['nutrients']),
    );
  }
}
