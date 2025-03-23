import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'recipe_details_page.dart';
import 'shopping_list_page.dart';
import 'widgets/recipe_checkbox_tile.dart';

class RecipeListPage extends StatefulWidget {
  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  Set<int> selectedRecipes = {};
  Map<int, double> recipeMultipliers = {}; // New: track multipliers per recipe
  List<Map<String, dynamic>> recipes = [];
  late Future<List<Map<String, dynamic>>> recipesFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    recipesFuture = DBHelper.fetchRecipes();
  }

  void toggleSelection(int recipeId) {
    setState(() {
      if (selectedRecipes.contains(recipeId)) {
        selectedRecipes.remove(recipeId);
      } else {
        selectedRecipes.add(recipeId);
      }
    });
  }

  void toggleSelectAll() {
    setState(() {
      if (selectedRecipes.length == recipes.length) {
        selectedRecipes.clear();
      } else {
        selectedRecipes = recipes.map((recipe) => recipe['id'] as int).toSet();
      }
    });
  }

  void generateShoppingList() async {
    final db = await DBHelper.initDB();
    Map<String, double> shoppingList = {};

    for (int recipeId in selectedRecipes) {
      double multiplier = recipeMultipliers[recipeId] ?? 1.0;

      List<Map<String, dynamic>> ingredients = await db.query(
        'ingredients',
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
      );

      for (var ingredient in ingredients) {
        String name = ingredient['name'];
        double weight = ingredient['weight'] * multiplier;

        shoppingList[name] = (shoppingList[name] ?? 0) + weight;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListPage(shoppingList: shoppingList),
      ),
    );
  }

  Future<void> deleteRecipe(int id, String name) async {
    final db = await DBHelper.initDB();

    List<Map<String, dynamic>> ingredients = await db.query(
      'ingredients',
      where: 'recipe_id = ?',
      whereArgs: [id],
    );

    await DBHelper.deleteRecipe(id);

    setState(() {
      recipesFuture = DBHelper.fetchRecipes();
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name deleted"),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "Undo",
          onPressed: () async {
            int restoredId = await db.insert('recipes', {'name': name});
            for (var ingredient in ingredients) {
              await db.insert('ingredients', {
                'recipe_id': restoredId,
                'name': ingredient['name'],
                'weight': ingredient['weight'],
                'order': ingredient['order'],
              });
            }
            setState(() {
              recipesFuture = DBHelper.fetchRecipes();
            });
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) controller.close();
    });
  }

  Future<void> importRecipes(String filePath) async {
    try {
      final file = File(filePath);
      String contents = await file.readAsString();

      Map<String, dynamic> jsonData = jsonDecode(contents);
      List<dynamic> recipesData = jsonData['recipes'];

      final db = await DBHelper.initDB();

      for (var recipe in recipesData) {
        String recipeName = recipe['name'];

        var existingRecipe = await db.query(
          'recipes',
          where: 'name = ?',
          whereArgs: [recipeName],
        );

        int recipeId;
        if (existingRecipe.isNotEmpty) {
          recipeId = existingRecipe.first['id'] as int;
        } else {
          recipeId = await DBHelper.insertRecipe(recipeName);
        }

        var maxOrderResult = await db.rawQuery(
          'SELECT MAX(`order`) as max_order FROM ingredients WHERE recipe_id = ?',
          [recipeId],
        );
        int order = (maxOrderResult.first['max_order'] as int?) ?? 0;

        for (var ingredient in recipe['ingredients']) {
          String ingredientName = ingredient['name'];
          double ingredientWeight =
              (ingredient['weight'] is int)
                  ? (ingredient['weight'] as int).toDouble()
                  : ingredient['weight'].toDouble();

          var existingIngredient = await db.query(
            'ingredients',
            where: 'recipe_id = ? AND name = ?',
            whereArgs: [recipeId, ingredientName],
          );

          if (existingIngredient.isEmpty) {
            await db.insert('ingredients', {
              'recipe_id': recipeId,
              'name': ingredientName,
              'weight': ingredientWeight,
              'order': order++,
            });
          }
        }
      }

      setState(() {
        recipesFuture = DBHelper.fetchRecipes();
      });
    } catch (e) {
      print("Error importing recipes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe List'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Reset All Multipliers',
            onPressed: () {
              setState(() {
                recipeMultipliers.clear(); // Reset all to default (1x)
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.select_all),
            onPressed: toggleSelectAll,
            tooltip: 'Select/Unselect All',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              TextEditingController nameController = TextEditingController();
              await showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text("Add Recipe"),
                      content: TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: "Recipe Name"),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            int recipeId = await DBHelper.insertRecipe(
                              nameController.text,
                            );
                            Navigator.pop(context);
                            setState(() {
                              recipesFuture = DBHelper.fetchRecipes();
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        RecipeDetailsPage(recipeId: recipeId),
                              ),
                            );
                          },
                          child: Text("Save"),
                        ),
                      ],
                    ),
              );
            },
            tooltip: 'Add Recipe',
          ),
          IconButton(
            icon: Icon(Icons.import_export),
            onPressed: () async {
              final filePath = await FilePicker.platform.pickFiles();
              if (filePath != null && filePath.files.isNotEmpty) {
                importRecipes(filePath.files.single.path!);
              }
            },
            tooltip: 'Import Recipes',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text("No recipes available"));

          recipes = snapshot.data!;

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Robot.webp'),
                fit: BoxFit.cover,
              ),
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                var recipe = recipes[index];
                int recipeId = recipe['id'];
                double multiplier = recipeMultipliers[recipeId] ?? 1.0;

                return Dismissible(
                  key: ValueKey(recipeId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => deleteRecipe(recipeId, recipe['name']),
                  child: Row(
                    children: [
                      Expanded(
                        child: RecipeCheckboxTile(
                          key: ValueKey(recipeId),
                          recipe: recipe,
                          initiallyChecked: selectedRecipes.contains(recipeId),
                          onChanged: (checked) => toggleSelection(recipeId),
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          RecipeDetailsPage(recipeId: recipeId),
                                ),
                              ),
                          onLongPress: () async {
                            TextEditingController nameController =
                                TextEditingController(text: recipe['name']);
                            await showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: Text("Edit Recipe"),
                                    content: TextField(
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        labelText: "Recipe Name",
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await DBHelper.updateRecipe(
                                            recipeId,
                                            nameController.text,
                                          );
                                          Navigator.pop(context);
                                          setState(() {
                                            recipesFuture =
                                                DBHelper.fetchRecipes();
                                          });
                                        },
                                        child: Text("Save"),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: DropdownButton<double>(
                          value: multiplier,
                          style: TextStyle(
                            color:
                                Colors.pink, // 💗 Sets color for selected item
                            fontWeight: FontWeight.bold,
                          ),
                          dropdownColor:
                              Colors.white, // optional: dropdown background
                          onChanged: (value) {
                            setState(() {
                              recipeMultipliers[recipeId] = value!;
                            });
                          },
                          items:
                              [1.0, 2.0, 3.0, 4.0, 5.0]
                                  .map(
                                    (val) => DropdownMenuItem<double>(
                                      value: val,
                                      child: Text(
                                        "${val.toInt()}x",
                                        style: TextStyle(
                                          color: Colors.pink,
                                        ), // 💗 Sets color in dropdown menu
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: selectedRecipes.isNotEmpty ? generateShoppingList : null,
          icon: Icon(Icons.shopping_cart),
          label: Text("Generate Shopping List"),
        ),
      ),
    );
  }
}
