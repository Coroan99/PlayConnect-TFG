import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.sports_esports_outlined,
      title: 'Juegos',
      description: 'El catalogo aparecera aqui cuando conectes esta pantalla.',
    );
  }
}
