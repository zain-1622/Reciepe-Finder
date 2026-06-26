class UserModel {
  final String email;
  final String name;
  final int age;
  final String gender;
  final String cuisinePreference;
  final String dietPreference;

  UserModel({
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.cuisinePreference,
    required this.dietPreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'cuisinePreference': cuisinePreference,
      'dietPreference': dietPreference,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      cuisinePreference: json['cuisinePreference'],
      dietPreference: json['dietPreference'],
    );
  }
}
