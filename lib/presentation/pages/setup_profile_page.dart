import 'package:doctorpoint/core/constants/app_colors.dart';
import 'package:doctorpoint/presentation/pages/home_page.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SetupProfileScreen extends StatefulWidget {
  final String uid;
  const SetupProfileScreen({super.key, required this.uid});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final AuthService auth = AuthService();

  String? gender;
  DateTime? birthDate;
  final addressCtrl = TextEditingController();

  bool loading = false;

  /// 📅 DATE PICKER
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      locale: const Locale('fr'),
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => birthDate = date);
    }
  }

  /// ✅ SUBMIT
  Future<void> submit() async {
    if (gender == null || birthDate == null || addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez compléter tous les champs')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await auth.completeProfile(
        uid: widget.uid,
        gender: gender!,
        birthDate: birthDate!,
        address: addressCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const HomePage(
                  userName: '',
                )),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Configurer le profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITRE
            const Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Veuillez compléter votre profil pour continuer',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 32),

            // GENRE
            DropdownButtonFormField<String>(
              initialValue: gender,
              decoration: InputDecoration(
                labelText: 'Genre',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Homme', child: Text('Homme')),
                DropdownMenuItem(value: 'Femme', child: Text('Femme')),
              ],
              onChanged: (v) => setState(() => gender = v),
            ),

            const SizedBox(height: 20),

            // DATE DE NAISSANCE
            TextFormField(
              readOnly: true,
              onTap: pickDate,
              decoration: InputDecoration(
                labelText: 'Date de naissance',
                prefixIcon: const Icon(Icons.calendar_today),
                hintText: birthDate == null
                    ? 'Choisir une date'
                    : DateFormat('dd/MM/yyyy').format(birthDate!),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ADRESSE
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(
                labelText: 'Adresse',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // BOUTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Terminer',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
