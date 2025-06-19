import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: context.locale,
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      underline: Container(),
      iconEnabledColor: Colors.greenAccent,
      items: [
        DropdownMenuItem(
          value: const Locale('en'),
          child: Text('English', style: TextStyle(color: Colors.white)),
        ),
        DropdownMenuItem(
          value: const Locale('vi'),
          child: Text('Tiếng Việt', style: TextStyle(color: Colors.white)),
        ),
      ],
      onChanged: (locale) {
        if (locale != null) {
          context.setLocale(locale);
        }
      },
    );
  }
}