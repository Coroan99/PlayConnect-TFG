import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _tipo = 'normal';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && previous?.errorMessage != message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Crear cuenta',
                      subtitle:
                          'Empieza a gestionar tus juegos en PlayConnect.',
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                controller: _nameController,
                                label: 'Nombre',
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                validator: _validateName,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _emailController,
                                label: 'Email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _passwordController,
                                label: 'Password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: _validatePassword,
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Mostrar password'
                                      : 'Ocultar password',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _confirmPasswordController,
                                label: 'Repetir password',
                                prefixIcon: Icons.lock_reset_outlined,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: _validateConfirmPassword,
                                onFieldSubmitted: (_) => _submit(),
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword
                                      ? 'Mostrar password'
                                      : 'Ocultar password',
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'normal',
                                    label: Text('Jugador'),
                                    icon: Icon(Icons.person_outline),
                                  ),
                                  ButtonSegment(
                                    value: 'tienda',
                                    label: Text('Tienda'),
                                    icon: Icon(Icons.storefront_outlined),
                                  ),
                                ],
                                selected: {_tipo},
                                onSelectionChanged: authState.isLoading
                                    ? null
                                    : (values) {
                                        setState(() {
                                          _tipo = values.first;
                                        });
                                      },
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                label: 'Registrarme',
                                icon: Icons.person_add_alt_1,
                                isLoading: authState.isLoading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => context.go(AppRoute.login.path),
                                child: const Text('Ya tengo cuenta'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref
        .read(authControllerProvider.notifier)
        .register(
          nombre: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          tipo: _tipo,
        );
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().length < 2) {
      return 'Introduce al menos 2 caracteres';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final isValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    if (email.isEmpty) {
      return 'El email es obligatorio';
    }

    if (!isValid) {
      return 'Introduce un email valido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'La password debe tener al menos 6 caracteres';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Las passwords no coinciden';
    }

    return null;
  }
}
