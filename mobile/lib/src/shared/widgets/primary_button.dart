import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    if (isLoading) {
      return FilledButton(
        onPressed: null,
        child: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (icon != null) {
      return FilledButton.icon(
        onPressed: effectiveOnPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return FilledButton(onPressed: effectiveOnPressed, child: Text(label));
  }
}
