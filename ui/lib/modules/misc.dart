import 'package:flutter/material.dart';
import 'package:material_symbols_icons/iconname_to_unicode_map.dart';

Container buildStyledIcon(BuildContext context, Color color, IconData? icon) {
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: color,
    ),
    child: icon != null ? Icon(icon, size: 24) : null,
  );
}

IconData? symbolFromName(String? name) {
  final codepoint =
      materialSymbolsIconNameToUnicodeMap[name]; // verify exact map name after import
  if (codepoint == null) return null;
  return IconData(
    codepoint,
    fontFamily: 'MaterialSymbolsOutlined', // or Rounded / Sharp
    fontPackage: 'material_symbols_icons',
  );
}
