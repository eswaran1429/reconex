import 'package:flutter/material.dart';

/// Like [IndexedStack], but builds each child only the first time its tab is
/// shown, then keeps it alive. Avoids every tab's controller running on open —
/// so a tab's network calls or scans don't all fire at launch.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<WidgetBuilder> builders;

  const LazyIndexedStack({super.key, required this.index, required this.builders});

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _built = List<bool>.filled(widget.builders.length, false);

  @override
  Widget build(BuildContext context) {
    _built[widget.index] = true;
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.builders.length; i++)
          _built[i] ? widget.builders[i](context) : const SizedBox.shrink(),
      ],
    );
  }
}
