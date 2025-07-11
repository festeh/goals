import 'package:flutter/material.dart';

class LongPressFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Function(String) onMenuItemSelected;

  const LongPressFab({
    super.key,
    required this.onPressed,
    required this.onMenuItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(button.size.bottomRight(Offset.zero),
                ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        );
        final result = await showMenu<String>(
          context: context,
          position: position,
          items: [
            const PopupMenuItem<String>(
              value: 'Text AI',
              child: Text('Text AI'),
            ),
            const PopupMenuItem<String>(
              value: 'Voice AI',
              child: Text('Voice AI'),
            ),
          ],
        );

        if (result != null) {
          onMenuItemSelected(result);
        }
      },
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
