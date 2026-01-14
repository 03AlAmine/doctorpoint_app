import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class DoctorPrescriptionsPage extends StatefulWidget {
  const DoctorPrescriptionsPage({super.key});

  @override
  State<DoctorPrescriptionsPage> createState() =>
      _DoctorPrescriptionsPageState();
}

class _DoctorPrescriptionsPageState extends State<DoctorPrescriptionsPage> {
  final List<Map<String, dynamic>> _prescriptions = [
    {
      'id': '1',
      'patient': 'Marie Dupont',
      'date': '2024-01-15',
      'medications': [
        {
          'name': 'Métoprolol 50mg',
          'dosage': '1 comprimé',
          'frequency': '1 fois par jour',
          'duration': '30 jours',
        },
        {
          'name': 'Metformine 850mg',
          'dosage': '1 comprimé',
          'frequency': '2 fois par jour',
          'duration': '30 jours',
        },
      ],
      'notes': 'À prendre le matin',
      'status': 'Active',
    },
    {
      'id': '2',
      'patient': 'Jean Martin',
      'date': '2024-01-10',
      'medications': [
        {
          'name': 'Atorvastatine 20mg',
          'dosage': '1 comprimé',
          'frequency': '1 fois par soir',
          'duration': '90 jours',
        },
      ],
      'notes': 'Contrôle lipidique dans 3 mois',
      'status': 'Active',
    },
  ];

  void _createPrescription() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nouvelle prescription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Nom du patient',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Date de prescription',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                            text: DateFormat('dd/MM/yyyy').format(DateTime.now())),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Médicaments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMedicationForm(),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un médicament'),
                        onPressed: () {
                          // Ajouter un médicament
                        },
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes et instructions',
                          border: OutlineInputBorder(),
                          hintText: 'Instructions particulières...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Sauvegarder la prescription
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prescription créée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Créer la prescription'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicationForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nom du médicament',
              border: InputBorder.none,
              hintText: 'Ex: Paracétamol 500mg',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: InputBorder.none,
                    hintText: 'Ex: 1 comprimé',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Fréquence',
                    border: InputBorder.none,
                    hintText: 'Ex: 3 fois/jour',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Durée',
              border: InputBorder.none,
              hintText: 'Ex: 7 jours',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription['patient'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prescrit le ${prescription['date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: prescription['status'] == 'Active'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    prescription['status'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: prescription['status'] == 'Active'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Médicaments prescrits:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...prescription['medications'].map<Widget>((med) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${med['dosage']} - ${med['frequency']} - ${med['duration']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            if (prescription['notes'] != null &&
                prescription['notes'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prescription['notes'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Imprimer'),
                    onPressed: () {
                      // Imprimer la prescription
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    onPressed: () {
                      // Modifier la prescription
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createPrescription,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total',
                  _prescriptions.length.toString(),
                  Icons.medical_services,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Actives',
                  _prescriptions
                      .where((p) => p['status'] == 'Active')
                      .length
                      .toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Ce mois',
                  '12',
                  Icons.calendar_month,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Liste des prescriptions
          Expanded(
            child: _prescriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description,
                          size: 80,
                          color: AppTheme.lightGrey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune prescription',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Créez votre première prescription',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      return _buildPrescriptionCard(_prescriptions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }
}