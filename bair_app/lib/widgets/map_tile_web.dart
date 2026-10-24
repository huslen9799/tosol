import 'package:flutter/material.dart';

Widget mapTile(String url, VoidCallback onError) => Image.network(
  url,
  fit: BoxFit.fill,
  errorBuilder: (_, error, stack) {
    onError();
    return ColoredBox(color: Color(0xFFEEF4FB));
  },
);
