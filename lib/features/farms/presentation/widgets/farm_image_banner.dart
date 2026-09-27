import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A farm's photo banner — cycles through [imageUrls] with looping
/// left/right arrow buttons (last photo's "next" wraps to the first, and
/// vice versa) and a soft fade+scale crossfade between them. Falls back to
/// a plain tinted icon when the farm has no photos yet.
class FarmImageBanner extends StatefulWidget {
  const FarmImageBanner({
    super.key,
    required this.imageUrls,
    this.height = 160,
    this.borderRadius = const BorderRadius.vertical(
      top: Radius.circular(20),
    ),
  });

  final List<String> imageUrls;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<FarmImageBanner> createState() => _FarmImageBannerState();
}

class _FarmImageBannerState extends State<FarmImageBanner> {
  int _index = 0;

  void _go(int delta) {
    final length = widget.imageUrls.length;
    setState(() => _index = (_index + delta + length) % length);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImages = widget.imageUrls.isNotEmpty;

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!hasImages)
              Container(
                color: colorScheme.primary.withValues(alpha: 0.08),
                child: Icon(
                  Icons.agriculture_outlined,
                  color: colorScheme.primary,
                  size: 40,
                ),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(
                      begin: 0.96,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: CachedNetworkImage(
                  key: ValueKey(_index),
                  imageUrl: widget.imageUrls[_index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: widget.height,
                  placeholder: (context, url) => Container(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.agriculture_outlined,
                      color: colorScheme.primary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            if (widget.imageUrls.length > 1) ...[
              Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _BannerNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _go(-1),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _BannerNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _go(1),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.imageUrls.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: i == _index ? 14 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: i == _index ? 0.95 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerNavButton extends StatelessWidget {
  const _BannerNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
