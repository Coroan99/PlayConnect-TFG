import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Inventario',
      description: 'Tus juegos disponibles para intercambio apareceran aqui.',
    );
  }
}
