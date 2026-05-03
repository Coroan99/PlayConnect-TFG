import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/constants/spanish_cities.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/spanish_city_field.dart';
import '../../../auth/domain/usuario.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  String? _hydratedUserId;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileControllerProvider, (previous, next) {
      final message = next.errorMessage;

      if (message != null && previous?.errorMessage != message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final usuario = ref.watch(authControllerProvider).usuario;
    final profileState = ref.watch(profileControllerProvider);

    if (usuario == null) {
      return const SizedBox.shrink();
    }

    _hydrateCity(usuario);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Perfil',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Nombre'),
                subtitle: Text(usuario.nombre),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(usuario.email),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Tipo de cuenta'),
                subtitle: Text(usuario.tipoLabel),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Ciudad'),
                subtitle: Text(
                  usuario.ciudad ?? 'Sin configurar · Córdoba por defecto',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mercado local',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu ciudad se usara como preferencia inicial en Mercado. Si la dejas vacia, PlayConnect usara Córdoba como fallback.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SpanishCityField(
                    controller: _cityController,
                    label: 'Ciudad (España)',
                    enabled: !profileState.isSaving,
                    validator: _validateCity,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Guardar ciudad',
                    icon: Icons.save_outlined,
                    isLoading: profileState.isSaving,
                    onPressed: () => _submit(usuario.id),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _hydrateCity(Usuario usuario) {
    if (_hydratedUserId == usuario.id &&
        _cityController.text.trim() == (usuario.ciudad ?? '').trim()) {
      return;
    }

    _hydratedUserId = usuario.id;
    _cityController.text = usuario.ciudad ?? '';
  }

  Future<void> _submit(String usuarioId) async {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final usuario = await ref
        .read(profileControllerProvider.notifier)
        .saveCity(
          usuarioId: usuarioId,
          ciudad: canonicalizeSpanishCity(_cityController.text),
        );

    if (!mounted || usuario == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            usuario.ciudad == null
                ? 'Ciudad eliminada. Mercado usara Córdoba por defecto.'
                : 'Ciudad actualizada a ${usuario.ciudad}.',
          ),
        ),
      );
  }

  String? _validateCity(String? value) {
    final normalized = (value ?? '').trim();

    if (normalized.isEmpty) {
      return null;
    }

    if (canonicalizeSpanishCity(normalized) == null) {
      return 'Selecciona una ciudad española valida';
    }

    return null;
  }
}
