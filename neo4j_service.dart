import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class Neo4jService {
  late final String uri;
  late final String username;
  late final String password;

  Neo4jService() {
    uri = dotenv.env['neo4j+s://a499e317.databases.neo4j.io'] ??
        (throw Exception('Missing NEO4J_URI in .env file'));
    username = dotenv.env['neo4j'] ??
        (throw Exception('Missing NEO4J_USERNAME in .env file'));
    password = dotenv.env['mwymoG_VQf9X3QoAcwW5_MQ_OUYiOISowEp3Xl76D0M'] ??
        (throw Exception('Missing NEO4J_PASSWORD in .env file'));
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization':
    'Basic ${base64Encode(utf8.encode('$username:$password'))}',
  };

  Future<bool> verifyUser(String email, String password) async {
    final body = {
      "statements": [
        {
          "statement":
          "MATCH (u:User {email: \$email, password: \$password}) RETURN u",
          "parameters": {"email": email, "password": password}
        }
      ]
    };

    final response = await http.post(
      Uri.parse('$uri/db/neo4j/tx/commit'),
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    final result = data['results'][0]['data'];
    return result.isNotEmpty;
  }
}
