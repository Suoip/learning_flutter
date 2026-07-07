import 'package:flutter/material.dart';

Widget calculatorNormalButton(
  String text, {
  required VoidCallback onPressed,
  Color fillColor = Colors.white,
  Color textColor = Colors.black,
}) {
  return SizedBox(
    width: 78,
    height: 78,
    child: RawMaterialButton(
      onPressed: onPressed,
      fillColor: fillColor,
      shape: const CircleBorder(),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 34,
          color: textColor,
        ),
      ),
    ),
  );
}

Widget calculatorWideButton(
  String text, {
  required VoidCallback onPressed,
  Color fillColor = Colors.white,
  Color textColor = Colors.black,
}) {
  return SizedBox(
    width: 168,
    height: 78,
    child: RawMaterialButton(
      onPressed: onPressed,
      fillColor: fillColor,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 34,
              color: textColor,
            ),
          ),
        ),
      ),
    ),
  );
}
