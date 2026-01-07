import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool showDetails;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    required this.onFavoriteTap,
    this.showDetails = true, required String imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Image du médecin
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    height: 140,
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
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
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
                        color: doctor.isFavorite ? Colors.red : AppTheme.greyColor,
                        size: 20,
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialization,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (showDetails) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.greyColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospital,
                            style: const TextStyle(
                              fontSize: 12,
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
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.rating}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' (${doctor.reviews})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${doctor.consultationFee.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
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