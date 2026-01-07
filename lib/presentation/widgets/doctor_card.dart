import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool showDetails;
  final bool isCompact; // Nouveau paramètre

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    required this.onFavoriteTap,
    this.showDetails = true,
    this.isCompact = false, // Valeur par défaut
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCompact ? 160 : 200, // Largeur adaptative
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
            // Image du médecin
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isCompact ? 12 : 16),
                    topRight: Radius.circular(isCompact ? 12 : 16),
                  ),
                  child: Container(
                    height: isCompact ? 100 : 140, // Hauteur adaptative
                    width: double.infinity,
                    color: AppTheme.lightGrey,
                    child: doctor.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: doctor.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.lightGrey,
                              child: const Center(
                                child: CircularProgressIndicator(),
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
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            
            // Informations du médecin
            Padding(
              padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
              child: Column(
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
                  
                  if (showDetails) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: isCompact ? 12 : 14,
                          color: AppTheme.greyColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospital,
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 12,
                              color: AppTheme.greyColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                          '\$${doctor.consultationFee.toStringAsFixed(2)}',
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
          ],
        ),
      ),
    );
  }
}