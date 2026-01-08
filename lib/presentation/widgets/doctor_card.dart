import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool showDetails;
  final bool isCompact;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    required this.onFavoriteTap,
    this.showDetails = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer la hauteur totale basée sur isCompact
    final totalHeight = isCompact ? 180.0 : 220.0;

    return Material( // AJOUTER Material widget
      color: Colors.transparent,
      child: InkWell( // Remplacer GestureDetector par InkWell
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        child: Container(
          width: isCompact ? 160 : 200,
          height: totalHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
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
              // Image du médecin (55% de la hauteur)
              SizedBox(
                height: totalHeight * 0.55,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isCompact ? 12 : 16),
                        topRight: Radius.circular(isCompact ? 12 : 16),
                      ),
                      child: Container(
                        height: double.infinity,
                        width: double.infinity,
                        color: AppTheme.lightGrey,
                        child: doctor.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: doctor.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppTheme.lightGrey,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.primaryColor),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppTheme.lightGrey,
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      size: isCompact ? 40 : 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.person,
                                  size: isCompact ? 40 : 60,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            doctor.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: doctor.isFavorite
                                ? Colors.red
                                : AppTheme.greyColor,
                            size: isCompact ? 16 : 20,
                          ),
                          onPressed: onFavoriteTap,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Informations du médecin (45% de la hauteur)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: TextStyle(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doctor.specialization,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: isCompact ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      
                      if (showDetails) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: isCompact ? 14 : 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${doctor.rating}',
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' (${doctor.reviews})',
                              style: TextStyle(
                                fontSize: isCompact ? 10 : 12,
                                color: AppTheme.greyColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${doctor.consultationFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}