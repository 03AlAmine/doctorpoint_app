import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class DoctorStatisticsPage extends StatefulWidget {
  const DoctorStatisticsPage({super.key});

  @override
  State<DoctorStatisticsPage> createState() => _DoctorStatisticsPageState();
}

class _DoctorStatisticsPageState extends State<DoctorStatisticsPage> {
  String _selectedPeriod = 'Ce mois';

  final List<Map<String, dynamic>> _revenueData = [
    {'month': 'Jan', 'revenue': 12000},
    {'month': 'Fév', 'revenue': 15000},
    {'month': 'Mar', 'revenue': 18000},
    {'month': 'Avr', 'revenue': 14000},
    {'month': 'Mai', 'revenue': 22000},
    {'month': 'Juin', 'revenue': 19000},
  ];

  final List<Map<String, dynamic>> _appointmentTypes = [
    {'type': 'Présentiel', 'count': 65, 'color': Colors.blue},
    {'type': 'Vidéo', 'count': 25, 'color': Colors.purple},
    {'type': 'Audio', 'count': 10, 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> _specialtyStats = [
    {'specialty': 'Cardiologie', 'patients': 45},
    {'specialty': 'Dermatologie', 'patients': 32},
    {'specialty': 'Neurologie', 'patients': 28},
    {'specialty': 'Pédiatrie', 'patients': 56},
  ];

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenus mensuels',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total: €112,500',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <CartesianSeries>[
                LineSeries<Map<String, dynamic>, String>(
                  dataSource: _revenueData,
                  xValueMapper: (data, _) => data['month'],
                  yValueMapper: (data, _) => data['revenue'],
                  color: AppTheme.primaryColor,
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 8,
                    width: 8,
                    shape: DataMarkerType.circle,
                    borderWidth: 2,
                    borderColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTypesChart() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Types de consultations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCircularChart(
              legend: Legend(
                isVisible: true,
                overflowMode: LegendItemOverflowMode.wrap,
                position: LegendPosition.bottom,
              ),
              series: <CircularSeries>[
                DoughnutSeries<Map<String, dynamic>, String>(
                  dataSource: _appointmentTypes,
                  xValueMapper: (data, _) => data['type'],
                  yValueMapper: (data, _) => data['count'],
                  pointColorMapper: (data, _) => data['color'],
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyStats() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patients par spécialité',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ..._specialtyStats.map((stat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat['specialty'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: LinearProgressIndicator(
                        value: stat['patients'] / 100,
                        backgroundColor: AppTheme.lightGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${stat['patients']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Consultations',
          '142',
          Icons.calendar_today,
          Colors.blue,
          '+12% vs mois dernier',
        ),
        _buildStatCard(
          'Nouveaux patients',
          '24',
          Icons.person_add,
          Colors.green,
          '+8 vs mois dernier',
        ),
        _buildStatCard(
          'Taux de satisfaction',
          '96%',
          Icons.star,
          Colors.orange,
          '4.8/5.0',
        ),
        _buildStatCard(
          'Revenu moyen',
          '€850',
          Icons.euro,
          Colors.purple,
          'Par consultation',
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subtitle.split(' ').first,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.greyColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              items: ['Ce mois', 'Ce trimestre', 'Cette année']
                  .map((period) => DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Exporter les statistiques
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Période sélectionnée
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM y', 'fr_FR').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '+18.5%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistiques rapides
            _buildQuickStats(),
            const SizedBox(height: 24),

            // Graphiques
            _buildRevenueChart(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildAppointmentTypesChart(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSpecialtyStats(),
            const SizedBox(height: 16),

            // Tableau détaillé
            Container(
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Détails des consultations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Jour')),
                      DataColumn(label: Text('Consultations')),
                      DataColumn(label: Text('Revenu')),
                      DataColumn(label: Text('Durée moy.')),
                    ],
                    rows: [
                      _buildDataRow('Lun', '18', '€1,440', '32 min'),
                      _buildDataRow('Mar', '22', '€1,760', '35 min'),
                      _buildDataRow('Mer', '20', '€1,600', '30 min'),
                      _buildDataRow('Jeu', '24', '€1,920', '38 min'),
                      _buildDataRow('Ven', '19', '€1,520', '33 min'),
                      _buildDataRow('Sam', '8', '€640', '40 min'),
                      _buildDataRow('Dim', '0', '€0', '0 min'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(
      String day, String consultations, String revenue, String avgDuration) {
    return DataRow(
      cells: [
        DataCell(Text(day)),
        DataCell(Text(consultations)),
        DataCell(Text(
          revenue,
          style: TextStyle(
            color: revenue != '€0' ? Colors.green : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        )),
        DataCell(Text(avgDuration)),
      ],
    );
  }
}
