import 'package:flutter/material.dart';
import 'package:onde_guardei/domain/repository.dart';

/// Foto do cadastro. O `cacheWidth` evita que o Android decodifique a
/// imagem inteira para desenhar uma miniatura, o que economiza memória.
class PhotoView extends StatelessWidget {
  final CatalogRepository repo;
  final String? photo;
  final int? cacheWidth;
  const PhotoView(this.repo, this.photo, {super.key, this.cacheWidth});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return photo == null
        ? ColoredBox(
            color: colors.secondaryContainer,
            child: Center(
              child: Icon(
                Icons.inventory_2_outlined,
                color: colors.onSecondaryContainer,
                size: 38,
              ),
            ),
          )
        : Image.file(
            repo.photoFile(photo!),
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => Center(
              child: Icon(Icons.broken_image_outlined, color: colors.primary),
            ),
          );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: colors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
