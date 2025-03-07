Color _generatePrimaryColor() {
    int charCode =
        widget.className.isNotEmpty ? widget.className.codeUnitAt(0) : 65;
    return HSLColor.fromAHSL(
      1.0,
      (charCode % 360).toDouble(),
      0.7,
      0.8,
    ).toColor();
  }