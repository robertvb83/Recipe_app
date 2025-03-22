import 'package:flutter/material.dart';
import 'db_helper.dart';

class AddIngredientPage extends StatefulWidget {
  final int recipeId;
  AddIngredientPage({required this.recipeId});

  @override
  _AddIngredientPageState createState() => _AddIngredientPageState();
}

class _AddIngredientPageState extends State<AddIngredientPage> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();

  Future<void> addIngredient() async {
    String name = _nameController.text;
    double weight = double.tryParse(_weightController.text) ?? 0.0;

    if (name.isNotEmpty && weight > 0) {
      await DBHelper.insertIngredient(widget.recipeId, name, weight);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingredient Added')));
      Navigator.pop(context); // Go back to the previous screen after adding the ingredient
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide valid data')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Ingredient')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Ingredient Name'),
            ),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(labelText: 'Weight (g)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addIngredient,
              child: Text('Add Ingredient'),
            ),
          ],
        ),
      ),
    );
  }
}
