import 'package:flutter/material.dart';

/// Rounded card used for form sections in the Add Car wizard.
///
/// Backed by the app's [CardThemeData] (shape/color/elevation), so it always
/// matches the current Material 3 theme without hardcoded styling here.
class AddCarFormCard extends StatelessWidget {
  const AddCarFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
