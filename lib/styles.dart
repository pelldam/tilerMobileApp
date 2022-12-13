import 'package:flutter/material.dart';

class TileStyles {
  static final double tileWidth = 350;
  static final double tileHeight = 350;
  static final double tileWidthRatio = 0.85;
  static final double borderRadius = 12;
  static final double inputWidthFactor = 0.85;
  static Color borderColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color activeColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color disabledColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledTextColor = HSLColor.fromAHSL(1, 0, 0, 0.7).toColor();
  static Color enabledTextColor = Colors.black87;
  static Color primaryColor = Color(0xffE5E5E5);
  static Color textFieldTextColor = Color(0xff1F1F1F).withOpacity(0.4);
  static TextStyle fullScreenTextFieldStyle = TextStyle(
      color: Color.fromRGBO(31, 31, 31, 1),
      fontSize: 20,
      fontWeight: FontWeight.w500);
}
