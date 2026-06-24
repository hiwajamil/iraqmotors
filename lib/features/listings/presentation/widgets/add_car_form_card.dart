import 'package:flutter/material.dart';

import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';

/// White rounded card used for form sections in the Add Car wizard.
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AddCarTheme.cardDecoration(),
      child: child,
    );
  }
}
