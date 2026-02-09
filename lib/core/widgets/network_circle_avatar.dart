import 'package:flutter/material.dart';
import 'package:tapem/core/utils/remote_url_utils.dart';

class NetworkCircleAvatar extends StatelessWidget {
  const NetworkCircleAvatar({
    super.key,
    required this.url,
    this.radius = 20,
    this.backgroundColor,
    this.placeholder,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double radius;
  final Color? backgroundColor;
  final Widget? placeholder;
  final BoxFit fit;

  Widget _buildPlaceholder() {
    return Center(
      child: placeholder ?? const Icon(Icons.fitness_center_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundColor ?? Colors.white.withOpacity(0.1);
    final imageUri = parseHttpUri(url);
    if (imageUri == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: resolvedBackground,
        child: _buildPlaceholder(),
      );
    }
    final size = radius * 2;
    return CircleAvatar(
      radius: radius,
      backgroundColor: resolvedBackground,
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            imageUri.toString(),
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildPlaceholder();
            },
          ),
        ),
      ),
    );
  }
}
