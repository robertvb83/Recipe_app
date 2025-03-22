import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShoppingListPage extends StatefulWidget {
  final Map<String, double> shoppingList;

  ShoppingListPage({required this.shoppingList});

  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  Set<String> shoppedItems = {};

  void copyShoppingListToClipboard() {
    var sortedShoppingList =
        widget.shoppingList.entries
            .where((item) => !shoppedItems.contains(item.key))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    String clipboardContent = sortedShoppingList
        .map((item) => "${item.key}: ${item.value} g")
        .join('\n');

    Clipboard.setData(ClipboardData(text: clipboardContent));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Shopping list copied to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    var sortedShoppingList =
        widget.shoppingList.entries.toList()..sort((a, b) {
          bool aShopped = shoppedItems.contains(a.key);
          bool bShopped = shoppedItems.contains(b.key);

          if (aShopped && !bShopped) return 1; // move checked items down
          if (!aShopped && bShopped) return -1;

          // If both same status, sort by weight descending
          return b.value.compareTo(a.value);
        });

    return Scaffold(
      appBar: AppBar(
        title: Text("Shopping List"),
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: copyShoppingListToClipboard,
            tooltip: "Copy to Clipboard",
          ),
        ],
      ),
      body:
          sortedShoppingList.isEmpty
              ? Center(child: Text("No ingredients selected."))
              : ListView.builder(
                itemCount: sortedShoppingList.length,
                itemBuilder: (context, index) {
                  String ingredient = sortedShoppingList[index].key;
                  double amount = sortedShoppingList[index].value;
                  bool isShopped = shoppedItems.contains(ingredient);

                  return ListTile(
                    leading: Checkbox(
                      value: isShopped,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            shoppedItems.add(ingredient);
                          } else {
                            shoppedItems.remove(ingredient);
                          }
                        });
                      },
                    ),
                    title: Text(
                      ingredient,
                      style: TextStyle(
                        decoration:
                            isShopped ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text("$amount g"),
                  );
                },
              ),
    );
  }
}
