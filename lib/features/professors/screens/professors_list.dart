import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduguide/features/professors/screens/professors_profile.dart';
import 'package:eduguide/features/professors/services/professor_service.dart';
import 'package:eduguide/features/widgets/professor_status_helper.dart';
import 'package:flutter/material.dart';

// --- Constants ---
const Color primaryBlue = Color(0xFF407BFF);
const Color lightBackground = Color(0xFFF7F7FD);
const Color cardBackground = Colors.white;
const Color textSubtle = Color(0xFF6E6E73);
const Color textBody = Color(0xFF1D1D1F);

class ProfessorsListPage extends StatelessWidget {
  final ProfessorsService professorsService;

  const ProfessorsListPage({required this.professorsService, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'All Professors',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          /// ⚡ QUICK STATS STRIP
          _quickStatsStrip(),

          /// PROFESSORS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: professorsService.getProfessorsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No professors found."));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    data['id'] = docs[idx].id;
                    return _buildProfessorCard(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // ⚡ QUICK STATS STRIP (UNCHANGED)
  Widget _quickStatsStrip() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('professors').snapshots(),
      builder: (context, profSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rating_summary')
              .snapshots(),
          builder: (context, ratingSnapshot) {
            int totalTeachers = 0;
            final Set<String> courses = {};
            double avgRating = 0;

            if (profSnapshot.hasData) {
              final profDocs = profSnapshot.data!.docs;
              totalTeachers = profDocs.length;

              for (var doc in profDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final specs = (data['specializations'] as List<dynamic>? ?? []);
                for (var s in specs) {
                  courses.add(s.toString());
                }
              }
            }

            if (ratingSnapshot.hasData &&
                ratingSnapshot.data!.docs.isNotEmpty) {
              double sum = 0;
              for (var doc in ratingSnapshot.data!.docs) {
                sum += (doc['avgRating'] ?? 0).toDouble();
              }
              avgRating = sum / ratingSnapshot.data!.docs.length;
            }

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("👨‍🏫 Teachers", totalTeachers.toString()),
                  _statItem("📚 Courses", courses.length.toString()),
                  _statItem(
                    "⭐ Avg Rating",
                    avgRating == 0 ? "--" : avgRating.toStringAsFixed(1),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textBody,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // PROFESSOR CARD (STATUS ADDED)
  Widget _buildProfessorCard(BuildContext context, Map<String, dynamic> data) {
    final name = data['name'] ?? 'N/A';
    final specializations = (data['specializations'] as List<dynamic>? ?? [])
        .join(', ');
    final imageUrl = data['image'] as String?;
    final professorId = data['id'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfessorDetailPage(data: data)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryBlue.withOpacity(0.1),
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Icon(Icons.person, color: primaryBlue)
                  : null,
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME + STATUS
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: textBody,
                          ),
                        ),
                      ),
                      _statusBadge(data),
                    ],
                  ),

                  const SizedBox(height: 4),

                  if (specializations.isNotEmpty)
                    Text(
                      specializations,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textSubtle),
                    ),

                  const SizedBox(height: 6),
                  _ratingWidget(professorId),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // STATUS BADGE
  Widget _statusBadge(Map<String, dynamic> data) {
    final availability = data['availability'] as Map<String, dynamic>? ?? {};

    final result = ProfessorStatusHelper.calculate(availability);

    // Don't show any badge outside college hours (before 9AM or after 5PM)
    if (result.status == ProfessorStatus.outsideCollegeHours) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;

    switch (result.status) {
      case ProfessorStatus.inCabin:
        color = Colors.green;
        text = "IN CABIN";
        break;
      case ProfessorStatus.busy:
        color = Colors.orange;
        text = result.nextAvailableIn != null
            ? "BUSY • ${result.nextAvailableIn!.inMinutes} min"
            : "BUSY";
        break;
      default:
        color = Colors.red;
        text = "ABSENT";
    }

    return _badge(text, color);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // ⭐ RATING WIDGET (UNCHANGED)
  Widget _ratingWidget(String professorId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rating_summary')
          .doc(professorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            "⭐ New",
            style: TextStyle(color: textSubtle, fontWeight: FontWeight.w600),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final avg = (data['avgRating'] ?? 0).toDouble();
        final count = data['ratingCount'] ?? 0;

        return Text(
          "⭐ ${avg.toStringAsFixed(1)} ($count)",
          style: const TextStyle(color: textBody, fontWeight: FontWeight.w600),
        );
      },
    );
  }
}
