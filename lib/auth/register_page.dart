import 'package:flutter/material.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:doctorpoint/core/constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final AuthService auth = AuthService();
  bool loading = false;
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 90),
              const SizedBox(height: 24),

              const Text(
                'Créer un compte',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 32),

              _field(
                emailCtrl,
                'Email',
                Icons.email,
                (v) => v != null && v.contains('@')
                    ? null
                    : 'Email invalide',
              ),

              _field(
                nameCtrl,
                'Nom complet',
                Icons.person,
                (v) => v != null && v.isNotEmpty
                    ? null
                    : 'Champ requis',
              ),

              _field(
                phoneCtrl,
                'Téléphone (+221)',
                Icons.phone,
                (v) => v != null && v.length >= 7
                    ? null
                    : 'Numéro invalide',
              ),

              TextFormField(
                controller: passCtrl,
                obscureText: hidePassword,
                validator: (v) {
                  if (v == null || v.length < 8) {
                    return 'Minimum 8 caractères';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(v)) {
                    return 'Ajouter une majuscule';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(v)) {
                    return 'Ajouter un chiffre';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => hidePassword = !hidePassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() => loading = true);
                          try {
                            final user = await auth.register(
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text.trim(),
                              fullName: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Erreur lors de l’inscription'),
                              ),
                            );
                          }
                          setState(() => loading = false);
                        },
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Créer un compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String? Function(String?) validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
