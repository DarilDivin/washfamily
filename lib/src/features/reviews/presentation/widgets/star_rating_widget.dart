import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final int rating;
  final void Function(int)? onChanged;
  final double size;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1),
        );
        if (onChanged == null) return icon;
        return GestureDetector(
          onTap: () => onChanged!(index + 1),
          child: icon,
        );
      }),
    );
  }
}
