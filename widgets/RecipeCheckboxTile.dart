import 'package:flutter/material.dart';

class RecipeCheckboxTile extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final bool initiallyChecked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  RecipeCheckboxTile({
    required this.recipe,
    required this.initiallyChecked,
    required this.onChanged,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  _RecipeCheckboxTileState createState() => _RecipeCheckboxTileState();
}

class _RecipeCheckboxTileState extends State<RecipeCheckboxTile> {
  late bool checked;

  @override
  void initState() {
    super.initState();
    checked = widget.initiallyChecked;
  }

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
          widget.recipe['name'],
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      leading: Checkbox(
        value: checked,
        onChanged: (value) {
          setState(() {
            checked = value!;
          });
          widget.onChanged(value!);
        },
      ),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }
}
