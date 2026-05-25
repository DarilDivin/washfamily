import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/review_model.dart';
import 'star_rating_widget.dart';

class ReviewCard extends StatefulWidget {
  final ReviewModel review;
  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  late final Future<String> _firstNameFuture;

  @override
  void initState() {
    super.initState();
    _firstNameFuture = _fetchFirstName();
  }

  Future<String> _fetchFirstName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.review.renterId)
          .get();
      return doc.data()?['firstName'] as String? ?? 'Utilisateur';
    } catch (_) {
      return 'Utilisateur';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _firstNameFuture,
      builder: (context, snapshot) {
        return _ReviewCardBody(
          review: widget.review,
          firstName: snapshot.data ?? '…',
        );
      },
    );
  }
}

class _ReviewCardBody extends StatelessWidget {
  final ReviewModel review;
  final String firstName;

  const _ReviewCardBody({required this.review, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy', 'fr').format(review.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                firstName,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A)),
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StarRatingWidget(rating: review.rating, size: 18),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
