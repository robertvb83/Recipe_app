import 'package:flutter/material.dart';
import 'package:recipe_app/recipe_list_page.dart'; // Import RecipeListPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: RecipeListPage(), // Set RecipeListPage as the home page
    );
  }
}
