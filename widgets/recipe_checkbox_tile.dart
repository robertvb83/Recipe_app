import 'package:flutter/material.dart';

class RecipeCheckboxTile extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final bool initiallyChecked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RecipeCheckboxTile({
    Key? key,
    required this.recipe,
    required this.initiallyChecked,
    required this.onChanged,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: initiallyChecked,
        onChanged: (checked) => onChanged(checked ?? false),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
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
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
