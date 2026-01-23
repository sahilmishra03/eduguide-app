import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduguide/features/professors/services/professor_service.dart';
import 'package:eduguide/features/widgets/professor_status_helper.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../professors/screens/professors_profile.dart';

// --- Constants ---
Color primaryBlue = const Color(0xFF407BFF);
Color lightBackground = const Color(0xFFF7F7FD);
Color cardBackground = Colors.white;
Color textSubtle = const Color(0xFF6E6E73);
Color textBody = const Color(0xFF1D1D1F);

class HomePage extends StatefulWidget {
  final Function(int) onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfessorsService _professorsService = ProfessorsService();

  final Map<String, double> _ratingMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "EduGuide",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rating_summary')
            .snapshots(),
        builder: (context, ratingSnap) {
          if (!ratingSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _ratingMap.clear();
          for (var doc in ratingSnap.data!.docs) {
            _ratingMap[doc.id] = (doc['avgRating'] ?? 0).toDouble();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _professorsService.getProfessorsStream(),
            builder: (context, profSnap) {
              if (!profSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = profSnap.data!.docs;
              final Map<String, List<Map<String, dynamic>>> categoryMap = {};

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final id = doc.id;

                if (!_ratingMap.containsKey(id)) continue;

                data['id'] = id;
                data['rating'] = _ratingMap[id];

                final specs = (data['specializations'] as List<dynamic>? ?? []);
                if (specs.isEmpty) continue;

                final category = specs.first.toString();
                categoryMap.putIfAbsent(category, () => []);
                categoryMap[category]!.add(data);
              }

              final visibleCategories = categoryMap.entries.take(3);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          icon: FontAwesomeIcons.graduationCap,
                          label: "Teachers",
                          onTap: () => widget.onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickAction(
                          icon: FontAwesomeIcons.magnifyingGlass,
                          label: "Search",
                          onTap: () => widget.onNavigate(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ...visibleCategories.map((entry) {
                    final profs = entry.value.take(3).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("Top Rated in ${entry.key}"),
                        ...profs.map((p) => _teacherCard(context, p)),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  Widget _teacherCard(BuildContext context, Map<String, dynamic> data) {
    final rating = data['rating'] as double;
    final name = data['name'] ?? '';
    final specs = (data['specializations'] as List<dynamic>).join(', ');
    final imageUrl = data['image'];

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
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? Icon(Icons.person, color: primaryBlue)
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _statusBadge(data),
                    ],
                  ),

                  Text(
                    specs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSubtle),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "⭐ ${rating.toStringAsFixed(1)}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
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

  // --------------------------------------------------
  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryBlue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textBody,
        ),
      ),
    );
  }
}
