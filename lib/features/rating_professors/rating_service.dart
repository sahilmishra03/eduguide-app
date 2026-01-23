import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  final _firestore = FirebaseFirestore.instance;

  Future<bool> hasUserRated(String professorId, String studentId) async {
    final snap = await _firestore
        .collection('ratings')
        .where('professorId', isEqualTo: professorId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  Future<void> submitRating({
    required String professorId,
    required String studentId,
    required int rating,
  }) async {
    final ratingRef = _firestore.collection('ratings').doc();
    final summaryRef = _firestore.collection('rating_summary').doc(professorId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(summaryRef);

      double avg = 0;
      int count = 0;

      if (snap.exists) {
        avg = (snap['avgRating'] ?? 0).toDouble();
        count = snap['ratingCount'] ?? 0;
      }

      final newCount = count + 1;
      final newAvg = ((avg * count) + rating) / newCount;

      tx.set(ratingRef, {
        'professorId': professorId,
        'studentId': studentId,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(summaryRef, {
        'avgRating': newAvg,
        'ratingCount': newCount,
      }, SetOptions(merge: true));
    });
  }
}
