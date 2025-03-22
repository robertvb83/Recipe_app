import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static const _databaseName = 'recipes.db';
  static const _databaseVersion = 2;

  static Database? _database;

  // Initialize and open database
  static Future<Database> initDB() async {
    if (_database != null) return _database!;

    _database = await openDatabase(
      join(await getDatabasesPath(), _databaseName),
      version: _databaseVersion,
      onCreate: (db, version) async {
        // Recipes Table
        await db.execute(''' 
          CREATE TABLE recipes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          );
        ''');

        // Ingredients Table (fixed 'order' keyword)
        await db.execute(''' 
          CREATE TABLE ingredients(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recipe_id INTEGER,
            name TEXT,
            weight REAL,
            `order` INTEGER,
            FOREIGN KEY(recipe_id) REFERENCES recipes(id)
          );
        ''');

        // Shopping List Table
        await db.execute(''' 
          CREATE TABLE shopping_list(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            weight REAL
          );
        ''');

        // Insert default Pancake recipe
        int pancakeId = await db.insert('recipes', {'name': 'Pancakes'});
        await db.insert('ingredients', {
          'recipe_id': pancakeId,
          'name': 'Flour',
          'weight': 200.0,
          'order': 1,
        });
        await db.insert('ingredients', {
          'recipe_id': pancakeId,
          'name': 'Milk',
          'weight': 300.0,
          'order': 2,
        });
        await db.insert('ingredients', {
          'recipe_id': pancakeId,
          'name': 'Eggs',
          'weight': 2.0,
          'order': 3,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE ingredients ADD COLUMN `order` INTEGER DEFAULT 0',
          );
          await db.rawUpdate(
            'UPDATE ingredients SET `order` = 0 WHERE `order` IS NULL',
          );
        }
      },
    );
    return _database!;
  }

  // Insert a new recipe
  static Future<int> insertRecipe(String name) async {
    final db = await initDB();
    return await db.insert('recipes', {'name': name});
  }

  // Insert a new ingredient (default order = 0)
  static Future<void> insertIngredient(
    int recipeId,
    String name,
    double weight,
  ) async {
    final db = await initDB();
    await db.insert('ingredients', {
      'recipe_id': recipeId,
      'name': name,
      'weight': weight,
      'order': 0,
    });
  }

  // Insert ingredient with explicit order
  static Future<void> insertIngredientWithOrder(
    int recipeId,
    String name,
    double weight,
    int order,
  ) async {
    final db = await initDB();
    await db.insert('ingredients', {
      'recipe_id': recipeId,
      'name': name,
      'weight': weight,
      'order': order,
    });
  }

  // Delete a recipe and its ingredients
  static Future<void> deleteRecipe(int id) async {
    final db = await initDB();
    await db.delete('ingredients', where: 'recipe_id = ?', whereArgs: [id]);
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // Delete a single ingredient
  static Future<void> deleteIngredient(int id) async {
    final db = await initDB();
    await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
  }

  // Fetch all recipes sorted by name
  static Future<List<Map<String, dynamic>>> fetchRecipes() async {
    final db = await initDB();
    return await db.query('recipes', orderBy: 'name ASC');
  }

  // Fetch ingredients for a specific recipe ordered by 'order'
  static Future<List<Map<String, dynamic>>> fetchIngredients(
    int recipeId,
  ) async {
    final db = await initDB();
    return await db.query(
      'ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: '`order`',
    );
  }

  // Update recipe name
  static Future<void> updateRecipe(int id, String name) async {
    final db = await initDB();
    await db.update(
      'recipes',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update ingredient's name and weight
  static Future<void> updateIngredient(
    int id,
    String name,
    double weight,
  ) async {
    final db = await initDB();
    await db.update(
      'ingredients',
      {'name': name, 'weight': weight},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update ingredient order
  static Future<void> updateIngredientOrder(
    int ingredientId,
    int newOrder,
  ) async {
    final db = await initDB();
    await db.update(
      'ingredients',
      {'order': newOrder},
      where: 'id = ?',
      whereArgs: [ingredientId],
    );
  }
}
