import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class DoctorSettingsPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorSettingsPage({super.key, required this.doctor});

  @override
  State<DoctorSettingsPage> createState() => _DoctorSettingsPageState();
}

class _DoctorSettingsPageState extends State<DoctorSettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  final List<Map<String, dynamic>> _workingHours = [
    {'day': 'Lundi', 'start': '09:00', 'end': '17:00', 'enabled': true},
    {'day': 'Mardi', 'start': '09:00', 'end': '17:00', 'enabled': true},
    {'day': 'Mercredi', 'start': '09:00', 'end': '17:00', 'enabled': true},
    {'day': 'Jeudi', 'start': '09:00', 'end': '17:00', 'enabled': true},
    {'day': 'Vendredi', 'start': '09:00', 'end': '17:00', 'enabled': true},
    {'day': 'Samedi', 'start': 'Fermé', 'end': 'Fermé', 'enabled': false},
    {'day': 'Dimanche', 'start': 'Fermé', 'end': 'Fermé', 'enabled': false},
  ];

  void _updateWorkingHours(int index) {
    showDialog(
      context: context,
      builder: (context) {
        TimeOfDay? startTime;
        TimeOfDay? endTime;
        bool isEnabled = _workingHours[index]['enabled'];

        if (isEnabled && _workingHours[index]['start'] != 'Fermé') {
          final startParts = _workingHours[index]['start'].split(':');
          final endParts = _workingHours[index]['end'].split(':');
          startTime = TimeOfDay(
              hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
          endTime = TimeOfDay(
              hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Horaires du ${_workingHours[index]['day']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: Text(isEnabled ? 'Ouvert' : 'Fermé'),
                    value: isEnabled,
                    onChanged: (value) {
                      setState(() {
                        isEnabled = value;
                        if (value) {
                          startTime = const TimeOfDay(hour: 9, minute: 0);
                          endTime = const TimeOfDay(hour: 17, minute: 0);
                        }
                      });
                    },
                  ),
                  if (isEnabled) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Heure d\'ouverture'),
                      trailing: Text(
                        startTime != null ? startTime!.format(context) : 'Choisir',
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (time != null) {
                          setState(() => startTime = time);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Heure de fermeture'),
                      trailing: Text(
                        endTime != null ? endTime!.format(context) : 'Choisir',
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (time != null) {
                          setState(() => endTime = time);
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _workingHours[index] = {
                        'day': _workingHours[index]['day'],
                        'start': isEnabled && startTime != null
                            ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                            : 'Fermé',
                        'end': isEnabled && endTime != null
                            ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                            : 'Fermé',
                        'enabled': isEnabled,
                      };
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mot de passe changé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Changer'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le compte'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer votre compte ? '
            'Cette action est irréversible et toutes vos données seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Supprimer le compte
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        children: [
          // Profil
          _buildSettingSection(
            'Profil',
            [
              _buildSettingTile(
                title: 'Informations personnelles',
                subtitle: 'Modifier votre nom, photo, etc.',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Éditer le profil
                },
              ),
              _buildSettingTile(
                title: 'Spécialité et services',
                subtitle: widget.doctor.specialization,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Modifier la spécialité
                },
              ),
              _buildSettingTile(
                title: 'Tarifs',
                subtitle: '€${widget.doctor.consultationFee}/consultation',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Modifier les tarifs
                },
              ),
            ],
          ),

          // Horaires de travail
          _buildSettingSection(
            'Horaires de travail',
            _workingHours.asMap().entries.map((entry) {
              final index = entry.key;
              final hours = entry.value;
              return _buildSettingTile(
                title: hours['day'],
                subtitle: hours['enabled']
                    ? '${hours['start']} - ${hours['end']}'
                    : 'Fermé',
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _updateWorkingHours(index),
              );
            }).toList(),
          ),

          // Notifications
          _buildSettingSection(
            'Notifications',
            [
              SwitchListTile(
                title: const Text('Activer les notifications'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              if (_notificationsEnabled) ...[
                SwitchListTile(
                  title: const Text('Notifications par email'),
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications push'),
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Notifications SMS'),
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() => _smsNotifications = value);
                  },
                ),
              ],
            ],
          ),

          // Sécurité
          _buildSettingSection(
            'Sécurité',
            [
              _buildSettingTile(
                title: 'Changer le mot de passe',
                trailing: const Icon(Icons.chevron_right),
                onTap: _showChangePasswordDialog,
              ),
              _buildSettingTile(
                title: 'Connexions actives',
                subtitle: 'Gérer les appareils connectés',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Voir les connexions
                },
              ),
              _buildSettingTile(
                title: 'Authentification à deux facteurs',
                subtitle: 'Non activé',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),

          // Préférences
          _buildSettingSection(
            'Préférences',
            [
              _buildSettingTile(
                title: 'Langue',
                subtitle: 'Français',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Changer la langue
                },
              ),
              _buildSettingTile(
                title: 'Thème',
                subtitle: 'Clair',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Changer le thème
                },
              ),
            ],
          ),

          // Support
          _buildSettingSection(
            'Support',
            [
              _buildSettingTile(
                title: 'Aide et FAQ',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Voir l'aide
                },
              ),
              _buildSettingTile(
                title: 'Contacter le support',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Contacter le support
                },
              ),
              _buildSettingTile(
                title: 'Conditions d\'utilisation',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Voir les conditions
                },
              ),
              _buildSettingTile(
                title: 'Politique de confidentialité',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Voir la politique
                },
              ),
            ],
          ),

          // Compte
          _buildSettingSection(
            'Compte',
            [
              _buildSettingTile(
                title: 'Supprimer le compte',
                trailing: const Icon(Icons.delete, color: Colors.red),
                onTap: _showDeleteAccountDialog,
              ),
              _buildSettingTile(
                title: 'Déconnexion',
                trailing: const Icon(Icons.logout, color: Colors.red),
                onTap: () {
                  // Déconnexion
                },
              ),
            ],
          ),

          // Version
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'DoctorPoint v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}