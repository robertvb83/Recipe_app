import 'package:flutter/material.dart';

class RecipeCheckboxTile extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final bool initiallyChecked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  RecipeCheckboxTile({
    Key? key, // <-- Add this line
    required this.recipe,
    required this.initiallyChecked,
    required this.onChanged,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key); // <-- And pass it here

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          recipe['name'],
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      leading: Checkbox(
        value: initiallyChecked,
        onChanged: (checked) => onChanged(checked ?? false),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
