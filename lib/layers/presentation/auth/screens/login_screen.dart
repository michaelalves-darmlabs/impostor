import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = GetIt.I<AuthRepository>();
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Entrar com Google'),
          onPressed: () {
            authRepository.signInWithGoogle();
          },
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
