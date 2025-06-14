// lib/widgets/logo.dart
import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final Color textColor =
        Theme.of(context).colorScheme.onSurface; // Get onSurface color

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlutterLogo(size: isSmallScreen ? 70 : 170),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Welcome to Flutter!",
            textAlign: TextAlign.center,
            style: isSmallScreen
                ? Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: textColor) // Apply textColor here
                : Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: textColor), // Apply textColor here
          ),
        )
      ],
    );
  }
}
