// lib/presentation/pages/patient/doctor_detail_page.dart
// REDESIGN COMPLET - Header hero, stats, design premium

import 'package:doctorpoint/presentation/pages/patient/book_appointment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:doctorpoint/core/providers/doctor_provider.dart';

class DoctorDetailPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailPage({super.key, required this.doctor});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showStickyHeader = false;
  bool _isDescriptionExpanded = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _scrollController.addListener(() {
      final show = _scrollController.offset > 240;
      if (show != _showStickyHeader) {
        setState(() => _showStickyHeader = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(provider),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        _buildIdentityCard(),
                        _buildStatsRow(),
                        _buildAboutSection(),
                        _buildWorkingHours(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Sticky bottom bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(provider),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar avec photo héro ──
  Widget _buildSliverAppBar(DoctorProvider provider) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primaryColor,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              widget.doctor.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.doctor.isFavorite ? Colors.red.shade300 : Colors.white,
              size: 20,
            ),
            onPressed: () => provider.toggleFavorite(widget.doctor.id),
            padding: EdgeInsets.zero,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
            onPressed: () {},
            padding: EdgeInsets.zero,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Photo du médecin
            widget.doctor.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.doctor.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _buildPlaceholderHero(),
                  )
                : _buildPlaceholderHero(),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            // Badge spécialité en bas à gauche
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.doctor.specialization,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dr. ${widget.doctor.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Badge rating en bas à droite
            Positioned(
              bottom: 24,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.doctor.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      ' (${widget.doctor.reviews})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderHero() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.person, size: 100, color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  // ── Carte identité ──
  Widget _buildIdentityCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.local_hospital_outlined,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.hospital,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${widget.doctor.experience} ans d\'expérience',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '${widget.doctor.consultationFee.toStringAsFixed(0)} €',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (widget.doctor.languages.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.language, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: widget.doctor.languages.map((lang) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lang,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Ligne stats ──
  Widget _buildStatsRow() {
    final stats = [
      {'icon': Icons.people_rounded, 'value': '1000+', 'label': 'Patients', 'color': Colors.blue},
      {'icon': Icons.workspace_premium, 'value': '${widget.doctor.experience}', 'label': 'Ans exp.', 'color': Colors.orange},
      {'icon': Icons.star_rounded, 'value': widget.doctor.rating.toStringAsFixed(1), 'label': 'Note', 'color': Colors.amber},
      {'icon': Icons.rate_review_outlined, 'value': '${widget.doctor.reviews}', 'label': 'Avis', 'color': Colors.green},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((s) {
          final color = s['color'] as Color;
          return Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(s['icon'] as IconData, color: color, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                s['value'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                s['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── À propos ──
  Widget _buildAboutSection() {
    final description = widget.doctor.description ??
        'Dr. ${widget.doctor.name.split(' ').last} est un spécialiste en ${widget.doctor.specialization.toLowerCase()} renommé à ${widget.doctor.hospital}. Avec ${widget.doctor.experience} ans d\'expérience, il/elle a traité plus de 1000 patients avec un dévouement exceptionnel. Disponible pour des consultations en présentiel, en vidéo et en audio.';

    final isLong = description.length > 200;
    final displayText = isLong && !_isDescriptionExpanded
        ? '${description.substring(0, 200)}…'
        : description;

    return _buildSection(
      title: 'À propos',
      icon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayText,
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
              child: Text(
                _isDescriptionExpanded ? 'Voir moins' : 'Voir plus',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Horaires ──
  Widget _buildWorkingHours() {
    final Map<String, dynamic> schedule = widget.doctor.availability ??
        {
          'Lundi': ['09:00', '18:00'],
          'Mardi': ['09:00', '18:00'],
          'Mercredi': ['09:00', '18:00'],
          'Jeudi': ['09:00', '18:00'],
          'Vendredi': ['09:00', '18:00'],
          'Samedi': ['09:00', '14:00'],
          'Dimanche': ['Fermé'],
        };

    final today = DateFormat('EEEE', 'fr_FR').format(DateTime.now());
    final todayCapitalized = today[0].toUpperCase() + today.substring(1);

    return _buildSection(
      title: 'Horaires',
      icon: Icons.access_time_rounded,
      child: Column(
        children: schedule.entries.map((entry) {
          final isClosed = entry.value is List &&
              (entry.value as List).isNotEmpty &&
              entry.value[0] == 'Fermé';
          final isToday = entry.key == todayCapitalized;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.primaryColor.withOpacity(0.06)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: isToday
                  ? Border.all(color: AppTheme.primaryColor.withOpacity(0.25))
                  : null,
            ),
            child: Row(
              children: [
                if (isToday)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? AppTheme.primaryColor : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClosed
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isClosed
                        ? 'Fermé'
                        : '${entry.value[0]} – ${entry.value[1]}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isClosed ? Colors.red.shade600 : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section helper ──
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Bottom bar ──
  Widget _buildBottomBar(DoctorProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Consultation',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                '${widget.doctor.consultationFee.toStringAsFixed(0)} €',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookAppointmentPage(doctor: widget.doctor),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Prendre rendez-vous',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}