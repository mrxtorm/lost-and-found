import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circular profile photo with an initial/icon fallback.
/// [localFile] (a just-picked photo) takes precedence over [photoUrl].
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final File? localFile;
  final String? name;
  final double radius;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.localFile,
    this.name,
    this.radius = 45,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = localFile != null
        ? FileImage(localFile!)
        : (photoUrl != null && photoUrl!.isNotEmpty)
            ? CachedNetworkImageProvider(photoUrl!)
            : null;
    final initial = name?.trim().isNotEmpty == true
        ? name!.trim()[0].toUpperCase()
        : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      foregroundImage: image,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.9,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : Icon(Icons.person, size: radius * 1.2, color: AppColors.primary),
    );
  }
}
