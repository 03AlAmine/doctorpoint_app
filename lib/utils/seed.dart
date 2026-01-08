// lib/utils/seed.dart
import 'package:doctorpoint/services/auth_service.dart';
Future<void> runSeed() async {
  final authService = AuthService();

  await authService.createAdmin(
    email: 'admin@gmail.com',
    password: 'Admin123',
    fullName: 'Administrateur',
    phone: '+33 1 23 45 67 91',
    permissions: ['all'],
  );
}
