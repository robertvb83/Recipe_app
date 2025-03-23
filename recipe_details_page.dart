import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'add_ingredient_page.dart';

class RecipeDetailsPage extends StatefulWidget {
  final int recipeId;

  RecipeDetailsPage({required this.recipeId});

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  List<Map<String, dynamic>> ingredients = [];
  Set<int> checkedIngredientIds = {};
  String recipeName = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchRecipeDetails();
  }

  Future<void> fetchRecipeDetails() async {
    final db = await DBHelper.initDB();

    // Fetch recipe name
    final recipeResult = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [widget.recipeId],
      limit: 1,
    );
    if (recipeResult.isNotEmpty) {
      recipeName = recipeResult.first['name'] as String;
    }

    // Fetch ingredients
    List<Map<String, dynamic>> result = await db.query(
      'ingredients',
      where: 'recipe_id = ?',
      whereArgs: [widget.recipeId],
      orderBy: '`order`',
    );

    bool needsOrderUpdate = false;
    List<Map<String, dynamic>> mutableResult =
        result.map((ing) => Map<String, dynamic>.from(ing)).toList();

    for (int i = 0; i < mutableResult.length; i++) {
      if (mutableResult[i]['order'] == null || mutableResult[i]['order'] == 0) {
        int newOrder = i + 1;
        mutableResult[i]['order'] = newOrder;
        await DBHelper.updateIngredientOrder(mutableResult[i]['id'], newOrder);
        needsOrderUpdate = true;
      }
    }

    if (needsOrderUpdate) {
      print("Ingredient order updated for recipe ${widget.recipeId}");
    }

    setState(() {
      ingredients = mutableResult;
    });
  }

  Future<void> deleteIngredient(
    int ingredientId,
    String name,
    double weight,
    int order,
  ) async {
    await DBHelper.deleteIngredient(ingredientId);
    fetchRecipeDetails();

    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name deleted"),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "Undo",
          onPressed: () async {
            await DBHelper.insertIngredientWithOrder(
              widget.recipeId,
              name,
              weight,
              order,
            );
            fetchRecipeDetails();
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      controller.close();
    });
  }

  Future<void> editIngredient(
    int ingredientId,
    String currentName,
    double currentWeight,
  ) async {
    TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    TextEditingController weightController = TextEditingController(
      text: currentWeight.toString(),
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit Ingredient"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(labelText: "Weight"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  await DBHelper.updateIngredient(
                    ingredientId,
                    nameController.text,
                    double.tryParse(weightController.text) ?? currentWeight,
                  );
                  fetchRecipeDetails();
                  Navigator.pop(context);
                },
                child: Text("Save"),
              ),
            ],
          ),
    );
  }

  void toggleAllCheckboxes() {
    setState(() {
      if (checkedIngredientIds.length == ingredients.length) {
        checkedIngredientIds.clear();
      } else {
        checkedIngredientIds = ingredients.map((e) => e['id'] as int).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipeName),
        actions: [
          IconButton(
            icon: Icon(Icons.check_box),
            onPressed: toggleAllCheckboxes,
            tooltip: 'Check/Uncheck All',
          ),
        ],
      ),
      body:
          ingredients.isEmpty
              ? Center(child: Text("No ingredients available for this recipe."))
              : ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final ingredient = ingredients.removeAt(oldIndex);
                    ingredients.insert(newIndex, ingredient);

                    for (int i = 0; i < ingredients.length; i++) {
                      DBHelper.updateIngredientOrder(
                        ingredients[i]['id'],
                        i + 1,
                      );
                    }
                  });
                },
                children: [
                  for (var ing in ingredients)
                    Dismissible(
                      key: Key(ing['id'].toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        await deleteIngredient(
                          ing['id'],
                          ing['name'],
                          ing['weight'],
                          ing['order'],
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        key: ValueKey("ingredient_${ing['id']}"),
                        leading: Checkbox(
                          value: checkedIngredientIds.contains(ing['id']),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                checkedIngredientIds.add(ing['id']);
                              } else {
                                checkedIngredientIds.remove(ing['id']);
                              }
                            });
                          },
                        ),
                        title: Text(
                          "${ing['name']}",
                          style: TextStyle(
                            decoration:
                                checkedIngredientIds.contains(ing['id'])
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        subtitle: Text("${ing['weight']} g"),
                        onTap:
                            () => editIngredient(
                              ing['id'],
                              ing['name'],
                              ing['weight'],
                            ),
                      ),
                    ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddIngredientPage(recipeId: widget.recipeId),
            ),
          ).then((_) => fetchRecipeDetails());
        },
        child: Icon(Icons.add),
        tooltip: 'Add Ingredient',
      ),
    );
  }
}
